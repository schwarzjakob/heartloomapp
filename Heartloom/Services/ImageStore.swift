import Foundation
import UIKit

public final class ImageStore: ImageStoring {
    private let baseURL: URL
    private let fm = FileManager.default

    public init(baseURL: URL) {
        self.baseURL = baseURL
        try? fm.createDirectory(at: baseURL, withIntermediateDirectories: true)
    }

    public func save(image: UIImage) throws -> PhotoAsset {
        let id = newId()
        let fileName = "\(id).jpg"
        let url = baseURL.appendingPathComponent(fileName)
        guard let data = image.jpegData(compressionQuality: 0.9) else { throw AppError.invalid }
        try data.write(to: url, options: .atomic)
        return PhotoAsset(id: id, fileName: fileName, createdAt: Date())
    }

    public func loadImageData(for asset: PhotoAsset) -> Data? {
        let url = imageURL(for: asset)
        return try? Data(contentsOf: url)
    }

    public func imageURL(for asset: PhotoAsset) -> URL {
        baseURL.appendingPathComponent(asset.fileName)
    }
}
