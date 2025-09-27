import SwiftUI
import UIKit

struct ImagePickerRepresentable: UIViewControllerRepresentable {
    enum Source { case camera, library }
    var sourceType: UIImagePickerController.SourceType
    var onImage: (UIImage?) -> Void

    init(sourceType: UIImagePickerController.SourceType, onImage: @escaping (UIImage?) -> Void) {
        self.sourceType = sourceType
        self.onImage = onImage
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onImage: onImage) }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onImage: (UIImage?) -> Void
        init(onImage: @escaping (UIImage?) -> Void) { self.onImage = onImage }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { onImage(nil); picker.dismiss(animated: true) }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage
            onImage(image)
            picker.dismiss(animated: true)
        }
    }
}
