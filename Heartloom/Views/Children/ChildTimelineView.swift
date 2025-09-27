import SwiftUI

struct ChildTimelineView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var timelineVM: TimelineViewModel
    @EnvironmentObject var familyVM: FamilyViewModel

    @State private var exporting = false
    @State private var shareURL: URL?

    var body: some View {
        VStack {
            if let child = appState.selectedChild {
                Picker("Child", selection: Binding(get: { child.id }, set: { id in
                    if let newChild = familyVM.children.first(where: { $0.id == id }) { appState.selectedChild = newChild; Task { await timelineVM.load() } }
                })) {
                    ForEach(familyVM.children) { c in
                        Text(c.name).tag(c.id)
                    }
                }
                .pickerStyle(.segmented)
                .padding([.horizontal, .top])
            }

            if timelineVM.entries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled").font(.system(size: 40))
                    Text("No entries yet").font(.headline)
                    Text("Add a new journal entry from the Add tab.").foregroundColor(.secondary)
                }.padding()
            } else {
                List(timelineVM.entries) { entry in
                    TimelineEntryRow(entry: entry, imageFor: timelineVM.image(for:))
                }
                .listStyle(.plain)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: exportPDF) { Image(systemName: "square.and.arrow.up") }
            }
        }
        .sheet(item: Binding(get: { shareURL.map { ShareItem(url: $0) } }, set: { _ in shareURL = nil })) { item in
            ShareSheet(activityItems: [item.url])
        }
        .task { await timelineVM.load() }
    }

    func exportPDF() {
        guard let child = appState.selectedChild else { return }
        do {
            let url = try PDFExporter.export(entries: timelineVM.entries, title: child.name) { assetId in
                timelineVM.image(for: assetId)
            }
            shareURL = url
        } catch {
            // ignore for now; could present an alert
        }
    }
}

private struct TimelineEntryRow: View {
    let entry: JournalEntry
    let imageFor: (ID) -> UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(DateFormatter.localizedString(from: entry.createdAt, dateStyle: .medium, timeStyle: .none))
                .font(.caption)
                .foregroundColor(.secondary)
            ImageCarouselView(images: entry.photoIds.compactMap { imageFor($0) })
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Text(entry.descriptionText)
            if !entry.tags.isEmpty {
                HStack { ForEach(entry.tags, id: \.self) { t in Text("#\(t)").foregroundColor(.secondary) } }
            }
        }
        .padding(.vertical, 8)
    }
}

private struct ShareItem: Identifiable { let id = UUID(); let url: URL }

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: activityItems, applicationActivities: nil) }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
