import Foundation
import UIKit
import Vision

public final class VisionAISuggestionService: AISuggestionService {
    public init() {}

    public func generateSuggestion(for images: [UIImage], children: [ChildProfile]) async -> String {
        guard let first = images.first, let cgImage = first.cgImage else {
            return Self.makeHeuristic(children: children)
        }
        do {
            let request = VNClassifyImageRequest()
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])
            if let results = request.results?.prefix(3) {
                let labels = results.map { $0.identifier }
                let names = children.map { $0.name }.joined(separator: ", ")
                return "\(names.isEmpty ? "A special moment" : names): \(labels.joined(separator: ", "))."
            }
        } catch {
            // fall through to heuristic
        }
        return Self.makeHeuristic(children: children)
    }

    static func makeHeuristic(children: [ChildProfile]) -> String {
        let names = children.map { $0.name }
        if names.isEmpty { return "A memorable family moment." }
        if names.count == 1 { return "\(names[0]) — a moment to remember." }
        return "Moments with \(names.joined(separator: ", "))."
    }
}

public final class FallbackAISuggestionService: AISuggestionService {
    public init() {}
    public func generateSuggestion(for images: [UIImage], children: [ChildProfile]) async -> String {
        return VisionAISuggestionService.makeHeuristic(children: children)
    }
}
