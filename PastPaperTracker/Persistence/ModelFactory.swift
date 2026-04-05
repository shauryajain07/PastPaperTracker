import Foundation
import SwiftData

enum ModelFactory {
    static func makeContainer(inMemory: Bool = false) -> ModelContainer {
        let schema = Schema([
            Subject.self,
            GradeBoundarySet.self,
            MarkEntry.self,
            MistakeEntry.self,
        ])

        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Unable to create model container: \(error.localizedDescription)")
        }
    }
}
