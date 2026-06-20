import FirebaseCore

/// One-time Firebase bootstrap. Call `configure()` at app launch (before
/// constructing any repository) so the app target never imports Firebase itself.
public enum SocialFeedFirebaseApp {
    public static func configure() {
        FirebaseApp.configure()
    }
}
