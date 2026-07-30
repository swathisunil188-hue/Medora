import Foundation
import UIKit

/// Generates a shareable PDF summary of a Report using UIGraphicsPDFRenderer
/// (built into UIKit — no third-party dependency needed).
class PDFReportService {
    static let shared = PDFReportService()
    private init() {}

    func generatePDF(for report: Report) -> URL? {
        let pageWidth: CGFloat = 612  // US Letter, 72 dpi
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 40
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        let fileName = "MediVerify_Report_\(report.id.uuidString.prefix(8)).pdf"
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try renderer.writePDF(to: outputURL) { context in
                context.beginPage()
                var y: CGFloat = margin

                func draw(_ text: String, font: UIFont, color: UIColor = .black, spacingAfter: CGFloat = 8) {
                    let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                    let attributed = NSAttributedString(string: text, attributes: attributes)
                    let boundingRect = attributed.boundingRect(
                        with: CGSize(width: pageWidth - margin * 2, height: .greatestFiniteMagnitude),
                        options: .usesLineFragmentOrigin, context: nil
                    )
                    if y + boundingRect.height > pageHeight - margin {
                        context.beginPage()
                        y = margin
                    }
                    attributed.draw(in: CGRect(x: margin, y: y, width: pageWidth - margin * 2, height: boundingRect.height))
                    y += boundingRect.height + spacingAfter
                }

                draw(report.title, font: .boldSystemFont(ofSize: 22), spacingAfter: 4)
                draw("Generated \(report.dateCreated.formatted(date: .abbreviated, time: .shortened))", font: .systemFont(ofSize: 11), color: .darkGray, spacingAfter: 20)

                draw("Prescription", font: .boldSystemFont(ofSize: 16), spacingAfter: 6)
                draw("Patient: \(report.prescription.patientName)", font: .systemFont(ofSize: 12))
                draw("Doctor: \(report.prescription.doctorName)", font: .systemFont(ofSize: 12))
                draw("Hospital: \(report.prescription.hospital)", font: .systemFont(ofSize: 12), spacingAfter: 16)

                if !report.prescription.medicines.isEmpty {
                    draw("Medicines", font: .boldSystemFont(ofSize: 14), spacingAfter: 6)
                    for med in report.prescription.medicines {
                        draw("• \(med.name) — \(med.dosage), \(med.frequency), \(med.duration)", font: .systemFont(ofSize: 12), spacingAfter: 4)
                    }
                    y += 12
                }

                if !report.interactions.isEmpty {
                    draw("Drug Interactions", font: .boldSystemFont(ofSize: 14), spacingAfter: 6)
                    for interaction in report.interactions {
                        draw("• \(interaction.drugA) + \(interaction.drugB): \(interaction.severity.rawValue)", font: .systemFont(ofSize: 12), spacingAfter: 2)
                        draw("   \(interaction.description)", font: .systemFont(ofSize: 10), color: .darkGray, spacingAfter: 8)
                    }
                    y += 12
                }

                if !report.dosages.isEmpty {
                    draw("Dosage Recommendations", font: .boldSystemFont(ofSize: 14), spacingAfter: 6)
                    for dosage in report.dosages {
                        draw("• \(dosage.medicineName): Adult \(dosage.adultDosage), Child \(dosage.childDosage), Elderly \(dosage.elderlyDosage)", font: .systemFont(ofSize: 12), spacingAfter: 4)
                    }
                    y += 12
                }

                if !report.alternatives.isEmpty {
                    draw("Alternative Medicines", font: .boldSystemFont(ofSize: 14), spacingAfter: 6)
                    for alt in report.alternatives {
                        draw("• \(alt.originalMedicine) → \(alt.alternativeName) (\(alt.type)): \(alt.reason)", font: .systemFont(ofSize: 12), spacingAfter: 4)
                    }
                }

                draw("This report is generated for informational purposes only and is not a substitute for professional medical advice.", font: .italicSystemFont(ofSize: 9), color: .gray, spacingAfter: 0)
            }
            return outputURL
        } catch {
            print("PDF generation failed: \(error)")
            return nil
        }
    }
}
