import SwiftUI

struct ChildTimelineView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var timelineVM: TimelineViewModel
    @EnvironmentObject var familyVM: FamilyViewModel

    @State private var shareURL: URL?

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                headerCard

                if timelineVM.entries.isEmpty {
                    GlassCard {
                        VStack(spacing: 12) {
                            Image(systemName: "sparkles.rectangle.stack")
                                .font(.system(size: 44))
                                .foregroundStyle(LinearGradient(colors: [.white.opacity(0.9), Color(red: 0.58, green: 0.76, blue: 1.0)], startPoint: .top, endPoint: .bottom))
                            Text("No entries yet")
                                .font(.headline)
                            Text("Capturing their first story moment is just a tap away from the Add tab.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    LazyVStack(spacing: 18, pinnedViews: []) {
                        ForEach(timelineVM.entries) { entry in
                            TimelineEntryRow(entry: entry, imageFor: timelineVM.image(for:))
                        }
                    }
                }
            }
            .padding(.vertical, 24)
        }
        .scrollIndicators(.hidden)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: exportPDF) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3.weight(.semibold))
                        .glassChip(cornerRadius: 16)
                }
            }
        }
        .sheet(item: Binding(get: { shareURL.map { ShareItem(url: $0) } }, set: { _ in shareURL = nil })) { item in
            ShareSheet(activityItems: [item.url])
        }
        .task { await timelineVM.load() }
    }

    private var headerCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                if !familyVM.children.isEmpty {
                    Picker("Child", selection: Binding(get: { appState.selectedChild?.id ?? familyVM.children.first?.id ?? "" }, set: { id in
                        if let newChild = familyVM.children.first(where: { $0.id == id }) {
                            appState.selectedChild = newChild
                            Task { await timelineVM.load() }
                        }
                    })) {
                        ForEach(familyVM.children) { c in
                            Text(c.name).tag(c.id)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if let child = appState.selectedChild {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(child.name)
                            .font(.title2.weight(.semibold))
                        Text("\(timelineVM.entries.count) memories captured")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Select or add a child to begin")
                        .font(.headline)
                }

                Button(action: exportPDF) {
                    Label("Export timeline", systemImage: "doc.richtext")
                }
                .buttonStyle(GlassButtonStyle())
            }
        }
    }

    private func exportPDF() {
        guard let child = appState.selectedChild else { return }
        do {
            let url = try PDFExporter.export(entries: timelineVM.entries, title: child.name) { assetId in
                timelineVM.image(for: assetId)
            }
            shareURL = url
        } catch {
            // TODO: surface error
        }
    }
}

private struct TimelineEntryRow: View {
    let entry: JournalEntry
    let imageFor: (ID) -> UIImage?

    var body: some View {
        GlassCard(cornerRadius: 26, padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(DateFormatter.localizedString(from: entry.createdAt, dateStyle: .medium, timeStyle: .none))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if !entry.tags.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(entry.tags, id: \.self) { t in
                                Text(t.uppercased())
                                    .font(.caption2.weight(.semibold))
                                    .glassChip(cornerRadius: 12)
                            }
                        }
                    }
                }

                if !entry.photoIds.isEmpty {
                    ImageCarouselView(images: entry.photoIds.compactMap { imageFor($0) })
                        .frame(height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(0.35))
                        )
                }

                Text(entry.descriptionText)
                    .font(.body)
                    .foregroundStyle(.primary)
            }
        }
    }
}

private struct ShareItem: Identifiable { let id = UUID(); let url: URL }

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: activityItems, applicationActivities: nil) }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
