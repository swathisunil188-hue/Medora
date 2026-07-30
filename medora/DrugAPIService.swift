import Foundation

/// IMPORTANT: NLM discontinued the old RxNav Drug-Drug Interaction API
/// (rxnav.nlm.nih.gov/REST/interaction) in January 2024 — it no longer
/// returns data. This service instead:
///   1. Uses RxNorm (still live, no key) to normalize a drug name to its
///      official ingredient name / RxCUI.
///   2. Uses openFDA's drug label endpoint (still live, no key) to pull
///      the manufacturer-submitted "drug_interactions" section of the
///      label and scans it for the other selected drug's name.
/// This is label-evidence, not a clinical decision engine — always show
/// a disclaimer in the UI (already included in DrugInteractionView).
class DrugAPIService {
    static let shared = DrugAPIService()
    private init() {}

    enum APIError: Error, LocalizedError {
        case notFound(String)
        case network(String)

        var errorDescription: String? {
            switch self {
            case .notFound(let name): return "No FDA label data found for \"\(name)\"."
            case .network(let msg): return "Network error: \(msg)"
            }
        }
    }

    // MARK: - RxNorm name normalization

    struct RxNormResult {
        let rxcui: String
        let normalizedName: String
    }

    func normalizeName(_ drugName: String) async throws -> RxNormResult {
        var components = URLComponents(string: "https://rxnav.nlm.nih.gov/REST/rxcui.json")!
        components.queryItems = [
            URLQueryItem(name: "name", value: drugName),
            URLQueryItem(name: "search", value: "2") // approximate match
        ]
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        let decoded = try JSONDecoder().decode(RxNormIdResponse.self, from: data)
        guard let rxcui = decoded.idGroup.rxnormId?.first else {
            throw APIError.notFound(drugName)
        }

        // Fetch the canonical name for that RxCUI
        let propsURL = URL(string: "https://rxnav.nlm.nih.gov/REST/rxcui/\(rxcui)/property.json?propName=RxNorm%20Name")!
        let (propData, _) = try await URLSession.shared.data(from: propsURL)
        let propsDecoded = try? JSONDecoder().decode(RxNormPropertyResponse.self, from: propData)
        let name = propsDecoded?.propConceptGroup?.propConcept?.first?.propValue ?? drugName

        return RxNormResult(rxcui: rxcui, normalizedName: name)
    }

    // MARK: - openFDA label lookup

    struct LabelInfo {
        let brandName: String?
        let genericName: String?
        let drugInteractionsText: String?
        let warningsText: String?
    }

    func fetchLabel(for drugName: String) async throws -> LabelInfo {
        var components = URLComponents(string: "https://api.fda.gov/drug/label.json")!
        let escaped = drugName.replacingOccurrences(of: "\"", with: "")
        components.queryItems = [
            URLQueryItem(name: "search", value: "openfda.generic_name:\"\(escaped)\" OR openfda.brand_name:\"\(escaped)\""),
            URLQueryItem(name: "limit", value: "1")
        ]
        let (data, response) = try await URLSession.shared.data(from: components.url!)

        if let http = response as? HTTPURLResponse, http.statusCode == 404 {
            throw APIError.notFound(drugName)
        }

        let decoded = try JSONDecoder().decode(OpenFDAResponse.self, from: data)
        guard let result = decoded.results?.first else {
            throw APIError.notFound(drugName)
        }

        return LabelInfo(
            brandName: result.openfda?.brandName?.first,
            genericName: result.openfda?.genericName?.first,
            drugInteractionsText: result.drugInteractions?.first,
            warningsText: result.warnings?.first ?? result.warningsAndCautions?.first
        )
    }

    // MARK: - Interaction check (heuristic, label-based)

    func checkInteraction(drugA: String, drugB: String) async -> DrugInteraction {
        do {
            async let labelA = fetchLabel(for: drugA)
            async let labelB = fetchLabel(for: drugB)
            let (infoA, infoB) = try await (labelA, labelB)

            let aMentionsB = infoA.drugInteractionsText?.lowercased().contains(drugB.lowercased()) ?? false
            let bMentionsA = infoB.drugInteractionsText?.lowercased().contains(drugA.lowercased()) ?? false

            if aMentionsB || bMentionsA {
                let evidence = aMentionsB ? infoA.drugInteractionsText : infoB.drugInteractionsText
                return DrugInteraction(
                    drugA: drugA,
                    drugB: drugB,
                    severity: .moderate,
                    description: String((evidence ?? "").prefix(400)),
                    recommendation: "This pairing is mentioned in an FDA label. Confirm with a pharmacist or doctor before combining."
                )
            } else {
                return DrugInteraction(
                    drugA: drugA,
                    drugB: drugB,
                    severity: .safe,
                    description: "No mention found in either drug's FDA label interaction section.",
                    recommendation: "No known label-documented interaction, but this is not exhaustive — always confirm with a pharmacist."
                )
            }
        } catch {
            return DrugInteraction(
                drugA: drugA,
                drugB: drugB,
                severity: .mild,
                description: "Could not verify: \(error.localizedDescription)",
                recommendation: "Try checking the drug names for typos, or consult a pharmacist directly."
            )
        }
    }
}

// MARK: - Decodable response shapes

private struct RxNormIdResponse: Decodable {
    let idGroup: IdGroup
    struct IdGroup: Decodable {
        let rxnormId: [String]?
        enum CodingKeys: String, CodingKey { case rxnormId }
    }
}

private struct RxNormPropertyResponse: Decodable {
    let propConceptGroup: PropConceptGroup?
    struct PropConceptGroup: Decodable {
        let propConcept: [PropConcept]?
    }
    struct PropConcept: Decodable {
        let propValue: String
    }
}

private struct OpenFDAResponse: Decodable {
    let results: [Result]?
    struct Result: Decodable {
        let drugInteractions: [String]?
        let warnings: [String]?
        let warningsAndCautions: [String]?
        let openfda: OpenFDAMeta?

        enum CodingKeys: String, CodingKey {
            case drugInteractions = "drug_interactions"
            case warnings
            case warningsAndCautions = "warnings_and_cautions"
            case openfda
        }
    }
    struct OpenFDAMeta: Decodable {
        let brandName: [String]?
        let genericName: [String]?
        enum CodingKeys: String, CodingKey {
            case brandName = "brand_name"
            case genericName = "generic_name"
        }
    }
}
