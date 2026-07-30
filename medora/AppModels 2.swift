import Foundation

// MARK: - User
struct User: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var age: Int
    var gender: String
    var phone: String
    var email: String
    var passwordHash: String
    var emergencyContact: String = ""
    var medicalConditions: [String] = []
    var allergies: [String] = []
    var profileImageData: Data? = nil
}

// MARK: - Medicine
struct Medicine: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var genericName: String
    var drugClass: String
    var uses: [String]
    var sideEffects: [String]
    var warnings: [String]
    var manufacturer: String
    var storageInstructions: String
}

// MARK: - Prescription
struct Prescription: Codable, Identifiable {
    var id: UUID = UUID()
    var patientName: String
    var doctorName: String
    var hospital: String
    var dateScanned: Date = Date()
    var medicines: [PrescribedMedicine]
}

struct PrescribedMedicine: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var dosage: String
    var frequency: String
    var duration: String
}

// MARK: - Drug Interaction
enum InteractionSeverity: String, Codable, CaseIterable {
    case safe = "Safe"
    case mild = "Mild Interaction"
    case moderate = "Moderate Interaction"
    case severe = "Severe Interaction"
}

struct DrugInteraction: Codable, Identifiable {
    var id: UUID = UUID()
    var drugA: String
    var drugB: String
    var severity: InteractionSeverity
    var description: String
    var recommendation: String
}

// MARK: - Dosage Recommendation
struct DosageRecommendation: Codable, Identifiable {
    var id: UUID = UUID()
    var medicineName: String
    var adultDosage: String
    var childDosage: String
    var elderlyDosage: String
    var warnings: [String]
}

// MARK: - Alternative Medicine
struct AlternativeMedicine: Codable, Identifiable {
    var id: UUID = UUID()
    var originalMedicine: String
    var alternativeName: String
    var reason: String
    var type: String
}

// MARK: - Chat Message (Phase 6)
struct ChatMessage: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var text: String
    var isUser: Bool
    var timestamp: Date = Date()
}

// MARK: - Report
struct Report: Codable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var dateCreated: Date = Date()
    var prescription: Prescription
    var interactions: [DrugInteraction]
    var dosages: [DosageRecommendation]
    var alternatives: [AlternativeMedicine]
}
