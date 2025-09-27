import Foundation
import PDFKit
import UIKit

public enum PDFExporter {
    public static func export(entries: [JournalEntry], title: String, loadImage: (ID) -> UIImage?) throws -> URL {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("Heartloom_\(UUID().uuidString).pdf")
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter @72dpi
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        try renderer.writePDF(to: tmp) { context in
            for (idx, entry) in entries.enumerated() {
                context.beginPage()
                let margin: CGFloat = 24
                var y: CGFloat = margin

                let dateStr = DateFormatter.localizedString(from: entry.createdAt, dateStyle: .medium, timeStyle: .none)
                let head = "Entry #\(idx + 1) — \(dateStr)"
                (head as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 16)])
                y += 28

                let imageSize = CGSize(width: (pageRect.width - margin*2 - 12)/2, height: 160)
                var col = 0
                for photoId in entry.photoIds {
                    if let img = loadImage(photoId) {
                        let x = margin + CGFloat(col) * (imageSize.width + 12)
                        img.draw(in: CGRect(origin: CGPoint(x: x, y: y), size: imageSize))
                        col += 1
                        if col == 2 { col = 0; y += imageSize.height + 12 }
                    }
                }
                if col != 0 { y += imageSize.height + 12 }

                let style = NSMutableParagraphStyle()
                style.lineBreakMode = .byWordWrapping
                let desc = entry.descriptionText as NSString
                let descRect = CGRect(x: margin, y: y, width: pageRect.width - margin*2, height: 300)
                desc.draw(with: descRect, options: .usesLineFragmentOrigin, attributes: [.font: UIFont.systemFont(ofSize: 14), .paragraphStyle: style], context: nil)
            }
        }
        return tmp
    }
}
