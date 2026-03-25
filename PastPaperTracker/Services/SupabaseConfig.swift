import Foundation

struct SupabaseConfig: Sendable {
    let url: URL
    let anonKey: String
    let storageBucket: String

    var isPlaceholder: Bool {
        anonKey.contains("your-anon-key") || url.absoluteString.contains("your-project")
    }

    static func loadFromBundle() -> SupabaseConfig? {
        guard
            let path = Bundle.main.path(forResource: "SupabaseConfig", ofType: "plist"),
            let data = FileManager.default.contents(atPath: path),
            let object = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
            let urlString = object["SUPABASE_URL"] as? String,
            let anonKey = object["SUPABASE_ANON_KEY"] as? String,
            let bucket = object["STORAGE_BUCKET"] as? String,
            let url = URL(string: urlString)
        else {
            return nil
        }

        let config = SupabaseConfig(url: url, anonKey: anonKey, storageBucket: bucket)
        return config.isPlaceholder ? nil : config
    }
}
