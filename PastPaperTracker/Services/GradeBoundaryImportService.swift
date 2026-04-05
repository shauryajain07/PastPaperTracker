import CryptoKit
import Foundation
@preconcurrency import Vision

struct GradeBoundaryImportResult {
    let imageHash: String
    let sourceSubjectTitle: String?
    let sourceOCRText: String
    let rows: [ImportedGradeBoundaryRow]
}

enum GradeBoundaryImportError: LocalizedError {
    case missingAPIKey
    case unreadableImage
    case noOCRText
    case invalidResponse
    case noBoundaryRows
    case malformedBoundaries(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Add a DeepSeek API key in Settings before importing a screenshot."
        case .unreadableImage:
            return "The selected screenshot could not be read."
        case .noOCRText:
            return "I could not read any text from that screenshot."
        case .invalidResponse:
            return "DeepSeek returned an unexpected response."
        case .noBoundaryRows:
            return "No session-based IB boundary rows were found in that screenshot."
        case .malformedBoundaries(let label):
            return "The imported boundaries for \(label) were incomplete or out of order."
        }
    }
}

@MainActor
final class GradeBoundaryImportService {
    private let apiKeyStore: DeepSeekAPIKeyStore
    private let session: URLSession

    init(apiKeyStore: DeepSeekAPIKeyStore, session: URLSession = .shared) {
        self.apiKeyStore = apiKeyStore
        self.session = session
    }

    func importBoundaries(from imageData: Data, subjectName: String) async throws -> GradeBoundaryImportResult {
        guard !imageData.isEmpty else {
            throw GradeBoundaryImportError.unreadableImage
        }

        guard let apiKey = await MainActor.run(body: { apiKeyStore.loadKey() }) else {
            throw GradeBoundaryImportError.missingAPIKey
        }

        let imageHash = SHA256.hash(data: imageData).compactMap { String(format: "%02x", $0) }.joined()
        let ocrText = try await extractText(from: imageData)
        guard !ocrText.isEmpty else {
            throw GradeBoundaryImportError.noOCRText
        }

        let parsed = try await requestStructuredBoundaries(ocrText: ocrText, subjectName: subjectName, apiKey: apiKey)
        let rows = try parsed.rows.map { row in
            let thresholds = try row.thresholds
            guard thresholds.isStrictlyAscending else {
                throw GradeBoundaryImportError.malformedBoundaries(row.label)
            }

            let sessionCode = GradeBoundarySessionCode.canonicalize(row.sessionCode ?? row.label) ?? row.label
            return ImportedGradeBoundaryRow(
                title: row.label,
                sessionCode: sessionCode,
                thresholds: thresholds
            )
        }

        guard !rows.isEmpty else {
            throw GradeBoundaryImportError.noBoundaryRows
        }

        return GradeBoundaryImportResult(
            imageHash: imageHash,
            sourceSubjectTitle: parsed.subject,
            sourceOCRText: ocrText,
            rows: rows
        )
    }

    static let extractionPrompt = """
    You clean OCR text from an IB grade-boundary table and return JSON only.

    Goal:
    Extract only the session-specific boundary rows that can be used to convert raw marks into IB grades.

    Context:
    - The selected app subject is: {{SUBJECT_NAME}}
    - OCR text may contain errors, merged columns, repeated spacing, and irrelevant rows like Average or SD.
    - Keep only rows that represent actual exam sessions, such as M25 TZ1, M25 TZ2, N25 TZ3.
    - Normalize session codes to the format M25 TZ1 or N24 TZ2.
    - Ignore rows like Average, SD, Boundary, Mean, or any row that is not an exam session.

    Output JSON shape:
    {
      "subject": "string or null",
      "rows": [
        {
          "label": "M25 TZ1",
          "session_code": "M25 TZ1",
          "boundaries": {
            "1": 0,
            "2": 12,
            "3": 24,
            "4": 35,
            "5": 49,
            "6": 63,
            "7": 75
          }
        }
      ]
    }

    Rules:
    - Return valid JSON only. No markdown.
    - Every row must contain all grades 1 through 7.
    - Boundary values must be numbers.
    - If OCR introduces uncertainty, choose the most likely numeric value from the table context.
    - Do not invent rows that are not present.
    - Prefer exact table values over OCR fragments.
    """

    private func extractText(from imageData: Data) async throws -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let handler = VNImageRequestHandler(data: imageData, options: [:])
                    try handler.perform([request])
                    let text = request.results?
                        .compactMap { $0.topCandidates(1).first?.string }
                        .joined(separator: "\n")
                        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    continuation.resume(returning: text)
                } catch {
                    continuation.resume(throwing: GradeBoundaryImportError.unreadableImage)
                }
            }
        }
    }

    private func requestStructuredBoundaries(
        ocrText: String,
        subjectName: String,
        apiKey: String
    ) async throws -> DeepSeekBoundaryPayload {
        guard let url = URL(string: "https://api.deepseek.com/chat/completions") else {
            throw GradeBoundaryImportError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 60

        let systemPrompt = Self.extractionPrompt.replacingOccurrences(of: "{{SUBJECT_NAME}}", with: subjectName)
        let body = DeepSeekBoundaryRequest(
            model: "deepseek-chat",
            temperature: 0,
            responseFormat: .init(type: "json_object"),
            messages: [
                .init(role: "system", content: systemPrompt),
                .init(
                    role: "user",
                    content: """
                    Subject selected in app: \(subjectName)

                    OCR text:
                    \(ocrText)
                    """
                ),
            ]
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw GradeBoundaryImportError.invalidResponse
        }

        let payload = try JSONDecoder().decode(DeepSeekBoundaryResponse.self, from: data)
        guard
            let content = payload.choices.first?.message.content,
            let contentData = content.data(using: .utf8)
        else {
            throw GradeBoundaryImportError.invalidResponse
        }

        return try JSONDecoder().decode(DeepSeekBoundaryPayload.self, from: contentData)
    }
}

private struct DeepSeekBoundaryRequest: Encodable {
    struct Message: Encodable {
        let role: String
        let content: String
    }

    struct ResponseFormat: Encodable {
        let type: String

        enum CodingKeys: String, CodingKey {
            case type
        }
    }

    let model: String
    let temperature: Double
    let responseFormat: ResponseFormat
    let messages: [Message]

    enum CodingKeys: String, CodingKey {
        case model
        case temperature
        case responseFormat = "response_format"
        case messages
    }
}

private struct DeepSeekBoundaryResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String?
        }

        let message: Message
    }

    let choices: [Choice]
}

private struct DeepSeekBoundaryPayload: Decodable {
    struct Row: Decodable {
        let label: String
        let sessionCode: String?
        let boundaries: [String: Double]

        enum CodingKeys: String, CodingKey {
            case label
            case sessionCode = "session_code"
            case boundaries
        }

        var thresholds: GradeBoundaryThresholds {
            get throws {
                guard
                    let grade1 = boundaries["1"],
                    let grade2 = boundaries["2"],
                    let grade3 = boundaries["3"],
                    let grade4 = boundaries["4"],
                    let grade5 = boundaries["5"],
                    let grade6 = boundaries["6"],
                    let grade7 = boundaries["7"]
                else {
                    throw GradeBoundaryImportError.malformedBoundaries(label)
                }

                return GradeBoundaryThresholds(
                    grade1: grade1,
                    grade2: grade2,
                    grade3: grade3,
                    grade4: grade4,
                    grade5: grade5,
                    grade6: grade6,
                    grade7: grade7
                )
            }
        }
    }

    let subject: String?
    let rows: [Row]
}
