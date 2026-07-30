import Foundation
import Vision
import UIKit

/// Runs on-device text recognition using Apple's Vision framework.
/// No API key, no network call, works fully offline.
class OCRService {
    static let shared = OCRService()
    private init() {}

    enum OCRError: Error, LocalizedError {
        case invalidImage
        case recognitionFailed(String)

        var errorDescription: String? {
            switch self {
            case .invalidImage: return "Could not read the selected image."
            case .recognitionFailed(let msg): return "Text recognition failed: \(msg)"
            }
        }
    }

    /// Extracts all recognized lines of text from an image.
    func recognizeText(from image: UIImage, completion: @escaping (Result<[String], Error>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(OCRError.invalidImage))
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                completion(.failure(OCRError.recognitionFailed(error.localizedDescription)))
                return
            }
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(.success([]))
                return
            }
            let lines = observations.compactMap { $0.topCandidates(1).first?.string }
            completion(.success(lines))
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(OCRError.recognitionFailed(error.localizedDescription)))
                }
            }
        }
    }

    /// Very lightweight heuristic parser that turns raw OCR lines into
    /// a best-guess Prescription. Since handwriting/printed prescription
    /// layouts vary wildly, this looks for common keywords (mg, tab,
    /// once/twice/thrice a day, days) and otherwise just lists candidate
    /// medicine lines for the user to confirm/edit in the UI.
    func parsePrescription(lines: [String], patientName: String, doctorName: String, hospital: String) -> Prescription {
        var medicines: [PrescribedMedicine] = []

        let dosagePattern = try? NSRegularExpression(pattern: #"\d+\s?(mg|mcg|ml|g)\b"#, options: .caseInsensitive)
        let frequencyKeywords = ["once a day", "twice a day", "thrice a day", "1-0-1", "1-1-1", "0-0-1", "od", "bd", "tds", "qid"]
        let durationPattern = try? NSRegularExpression(pattern: #"\d+\s?(day|days|week|weeks)\b"#, options: .caseInsensitive)

        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard line.count > 2 else { continue }

            let range = NSRange(line.startIndex..., in: line)
            let hasDosage = dosagePattern?.firstMatch(in: line, range: range) != nil
            let hasFrequency = frequencyKeywords.contains { line.lowercased().contains($0) }
            let hasDuration = durationPattern?.firstMatch(in: line, range: range) != nil

            // Treat lines that look like "DrugName 500mg" or contain dosage/frequency hints as medicine candidates
            if hasDosage || hasFrequency || hasDuration {
                let dosageMatch = dosagePattern?.firstMatch(in: line, range: range)
                let dosageText = dosageMatch.flatMap { Range($0.range, in: line).map { String(line[$0]) } } ?? ""

                let durationMatch = durationPattern?.firstMatch(in: line, range: range)
                let durationText = durationMatch.flatMap { Range($0.range, in: line).map { String(line[$0]) } } ?? ""

                let name = line
                    .replacingOccurrences(of: dosageText, with: "")
                    .replacingOccurrences(of: durationText, with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                medicines.append(PrescribedMedicine(
                    name: name.isEmpty ? line : name,
                    dosage: dosageText.isEmpty ? "Confirm dosage" : dosageText,
                    frequency: frequencyKeywords.first(where: { line.lowercased().contains($0) }) ?? "Confirm frequency",
                    duration: durationText.isEmpty ? "Confirm duration" : durationText
                ))
            }
        }

        return Prescription(
            patientName: patientName,
            doctorName: doctorName,
            hospital: hospital,
            medicines: medicines
        )
    }
}
