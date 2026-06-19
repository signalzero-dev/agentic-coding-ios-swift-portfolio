import Foundation

enum StartupError: Error, LocalizedError {
    case missingTMDBBearerToken
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .missingTMDBBearerToken:
            return """
            TMDB_BEARER_TOKEN is missing.
            Copy Apps/MovieBrowser/Config/Secrets.xcconfig.template to Secrets.xcconfig, paste your TMDB v4 Read Access Token, and ensure the target's Configuration File is set to Secrets.xcconfig.
            """
        case .unknown(let message):
            return message
        }
    }
}
