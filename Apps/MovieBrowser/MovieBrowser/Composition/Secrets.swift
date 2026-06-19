import Foundation

enum Secrets {
    static func tmdbBearerToken() throws -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "TMDB_BEARER_TOKEN") as? String,
              !value.isEmpty,
              value != "$(TMDB_BEARER_TOKEN)" else {
            throw StartupError.missingTMDBBearerToken
        }
        return value
    }
}
