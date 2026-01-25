import SwiftUI
import UIKit

struct PubSubmissionSheet: View {
    let pub: Pub
    let drink: String
    let pubIndex: Int
    let hasSubmitted: Bool
    let onSubmit: () -> Void

    @State private var showCamera = false
    @State private var capturedImage: UIImage?

    @Environment(\.dismiss) private var dismiss

    private var hasImage: Bool {
        capturedImage != nil
    }

    var body: some View {
        VStack(spacing: 16) {

            // MARK: Header
            Text("Pub #\(pubIndex + 1)")
                .font(.bricolage(.headline))
                .padding(.top, 8)

            // MARK: Pub row
            pubRow

            // MARK: Camera
            cameraButton

            // MARK: Submit
            submitButton
        }
        .padding()
        .presentationDetents([.height(500)])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showCamera) {
            CameraView(image: $capturedImage)
        }
    }
}

// MARK: - Subviews
extension PubSubmissionSheet {

    private var pubRow: some View {
        HStack(spacing: 12) {

            // Pub info card
            VStack(alignment: .leading, spacing: 8) {
                Text(pub.name)
                    .font(.bricolage(.headline))

                Text(pub.address)
                    .font(.bricolage(.footnote))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Side tiles
            VStack(spacing: 8) {
                mapsTile
                drinkTile
            }
        }
    }

    private var mapsTile: some View {
        Button {
            openInMaps()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "map.fill")
                Text("Maps")
                    .font(.bricolage(.caption))
            }
            .frame(width: 80, height: 48)
            .background(Color.blue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var drinkTile: some View {
        VStack(spacing: 4) {
            Text(Constants.drinkEmojis[drink] ?? "🍺")
                .font(.title3)
            Text(drink)
                .font(.bricolage(.caption2))
        }
        .frame(width: 80, height: 48)
        .background(Color.green)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var cameraButton: some View {
        Button {
            Haptics.light()
            showCamera = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: hasImage ? "checkmark.circle.fill" : "camera.fill")
                    .font(.title2)

                Text(hasImage ? "Photo Added" : "Open Camera")
                    .font(.bricolage(.headline))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(hasImage ? Color.gray.opacity(0.35) : Color.orange)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var submitButton: some View {
        Button {
            Haptics.success()
            onSubmit()
            dismiss()
        } label: {
            Text("Submit")
                .font(.bricolage(.headline))
                .frame(maxWidth: .infinity)
                .padding()
                .background(hasImage ? Color.green : Color.gray.opacity(0.4))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(!hasImage)
    }

    private func openInMaps() {
        LocationService.shared.openInMaps(pub: pub)
    }
}

// MARK: - Camera View
struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
                Haptics.success()
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Preview
#Preview {
    PubSubmissionSheet(
        pub: Pub(
            name: "Phoenix",
            address: "123 Main St",
            latitude: 0,
            longitude: 0
        ),
        drink: "Cocktail",
        pubIndex: 0,
        hasSubmitted: false,
        onSubmit: {}
    )
}
