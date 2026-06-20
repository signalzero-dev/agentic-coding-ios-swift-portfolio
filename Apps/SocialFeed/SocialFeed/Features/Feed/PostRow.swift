import SwiftUI
import SocialFeedCore

/// A single feed post with author, text, optional image, and an optimistic like button.
struct PostRow: View {
    let post: Post
    let onToggleLike: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(post.authorName)
                .font(.headline)
            Text(post.text)
                .font(.body)
            if let imageURL = post.imageURL {
                AsyncImage(url: imageURL) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    Color.gray.opacity(0.1)
                }
                .frame(maxHeight: 220)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            Button(action: onToggleLike) {
                Label("\(post.likeCount)", systemImage: post.likedByCurrentUser ? "heart.fill" : "heart")
                    .foregroundStyle(post.likedByCurrentUser ? .red : .secondary)
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
