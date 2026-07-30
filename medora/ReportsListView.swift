
import SwiftUI

/// Simple local store for Reports, mirroring the pattern used by
/// LocalStorageService and PrescriptionStore.
class ReportStore {
    static let shared = ReportStore()
    private init() {}
    private let key = "saved_reports"

    func save(_ report: Report) {
        var all = loadAll()
        all.append(report)
        if let data = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(data, forKey: key)
        }
        // Also mirror to Firestore if signed in (Phase 5 + 6 together).
        FirebaseAuthService.shared.saveReport(report) { _ in }
    }

    func loadAll() -> [Report] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let list = try? JSONDecoder().decode([Report].self, from: data) else {
            return []
        }
        return list.sorted { $0.dateCreated > $1.dateCreated }
    }
}

struct ReportsListView: View {
    @State private var reports: [Report] = ReportStore.shared.loadAll()
    @State private var shareURL: URL?
    @State private var showShareSheet = false

    var body: some View {
        Group {
            if reports.isEmpty {
                EmptyStateView(
                    icon: "doc.text",
                    title: "No reports yet",
                    message: "Scan a prescription and run an interaction check — you can then save the combined result as a PDF report here."
                )
            } else {
                List(reports) { report in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(report.title)
                            .font(.headline)
                        Text(report.dateCreated.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(report.prescription.medicines.count) medicines · \(report.interactions.count) interactions checked")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                    .swipeActions {
                        Button {
                            exportPDF(for: report)
                        } label: {
                            Label("Export PDF", systemImage: "square.and.arrow.up")
                        }
                        .tint(.blue)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("My Reports")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            if let shareURL {
                ShareSheet(items: [shareURL])
            }
        }
        .onAppear {
            reports = ReportStore.shared.loadAll()
        }
    }

    private func exportPDF(for report: Report) {
        if let url = PDFReportService.shared.generatePDF(for: report) {
            shareURL = url
            showShareSheet = true
        }
    }
}

/// Wraps UIActivityViewController so the generated PDF can be shared/saved via SwiftUI.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack { ReportsListView() }
}
