import SwiftUI
import PhotosUI
import UIKit
import SocialFeedCore

/// Create-a-post sheet. Binds to `ComposeViewModel`; dismisses on success.
struct ComposeView: View {
    @State private var viewModel: ComposeViewModel
    @State private var pickedItem: PhotosPickerItem?
    @State private var imageData: Data?
    @Environment(\.dismiss) private var dismiss
    private let onPosted: () -> Void

    init(container: RootContainer, onPosted: @escaping () -> Void) {
        _viewModel = State(initialValue: container.makeComposeViewModel())
        self.onPosted = onPosted
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            Form {
                Section {
                    TextField("What's happening?", text: $viewModel.text, axis: .vertical)
                        .lineLimit(3...8)
                }

                Section {
                    PhotosPicker(selection: $pickedItem, matching: .images) {
                        Label(imageData == nil ? "Add Photo" : "Change Photo", systemImage: "photo")
                    }
                    if let imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                    }
                }

                if let error = viewModel.submitState.failure {
                    Section {
                        Text(message(for: error)).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        Task {
                            await viewModel.submit(imageData: imageData)
                            if viewModel.didPost { onPosted() }
                        }
                    }
                    .disabled(isPostDisabled)
                }
            }
            .onChange(of: pickedItem) { _, item in
                Task { await loadImage(from: item) }
            }
        }
    }

    private var isPostDisabled: Bool {
        viewModel.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || viewModel.submitState.isLoading
    }

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item, let data = try? await item.loadTransferable(type: Data.self) else { return }
        // Recompress to keep uploads small.
        imageData = UIImage(data: data)?.jpegData(compressionQuality: 0.7) ?? data
    }

    private func message(for error: ComposeError) -> String {
        switch error {
        case .emptyText: "Write something first."
        case .uploadFailed: "Couldn't upload the image. Try again."
        case .postFailed: "Couldn't publish the post. Try again."
        }
    }
}
