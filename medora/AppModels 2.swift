import Foundation

// Namespace to avoid type collisions with similarly named models elsewhere
public enum AppModels {
    // MARK: - User
    public struct User: Codable, Identifiable, Equatable {
        public var id: UUID = UUID()
        public var name: String
        public var age: Int
        public var gender: String
        public var phone: String
        public var email: String
        public var passwordHash: String
        public var emergencyContact: String = ""
        public var medicalConditions: [String] = []
        public var allergies: [String] = []
        public var profileImageData: Data? = nil

        public init(id: UUID = UUID(), name: String, age: Int, gender: String, phone: String, email: String, passwordHash: String, emergencyContact: String = "", medicalConditions: [String] = [], allergies: [String] = [], profileImageData: Data? = nil) {
            self.id = id
            self.name = name
            self.age = age
            self.gender = gender
            self.phone = phone
            self.email = email
            self.passwordHash = passwordHash
            self.emergencyContact = emergencyContact
            self.medicalConditions = medicalConditions
            self.allergies = allergies
            self.profileImageData = profileImageData
        }
    }

    // MARK: - Medicine
    public struct Medicine: Codable, Identifiable, Equatable {
        public var id: UUID = UUID()
        public var name: String
        public var genericName: String
        public var drugClass: String
        public var uses: [String]
        public var sideEffects: [String]
        public var warnings: [String]
        public var manufacturer: String
        public var storageInstructions: String

        public init(id: UUID = UUID(), name: String, genericName: String, drugClass: String, uses: [String], sideEffects: [String], warnings: [String], manufacturer: String, storageInstructions: String) {
            self.id = id
            self.name = name
            self.genericName = genericName
            self.drugClass = drugClass
            self.uses = uses
            self.sideEffects = sideEffects
            self.warnings = warnings
            self.manufacturer = manufacturer
            self.storageInstructions = storageInstructions
        }
    }

    // MARK: - Prescription
    public struct Prescription: Codable, Identifiable, Equatable {
        public var id: UUID = UUID()
        public var patientName: String
        public var doctorName: String
        public var hospital: String
        public var dateScanned: Date = Date()
        public var medicines: [PrescribedMedicine]

        public init(id: UUID = UUID(), patientName: String, doctorName: String, hospital: String, dateScanned: Date = Date(), medicines: [PrescribedMedicine]) {
            self.id = id
            self.patientName = patientName
            self.doctorName = doctorName
            self.hospital = hospital
            self.dateScanned = dateScanned
            self.medicines = medicines
        }
    }

    public struct PrescribedMedicine: Codable, Identifiable, Equatable {
        public var id: UUID = UUID()
        public var name: String
        public var dosage: String
        public var frequency: String
        public var duration: String

        public init(id: UUID = UUID(), name: String, dosage: String, frequency: String, duration: String) {
            self.id = id
            self.name = name
            self.dosage = dosage
            self.frequency = frequency
            self.duration = duration
        }
    }

    // MARK: - Drug Interaction
    public enum InteractionSeverity: String, Codable, CaseIterable {
        case safe = "Safe"
        case mild = "Mild Interaction"
        case moderate = "Moderate Interaction"
        case severe = "Severe Interaction"
    }

    public struct DrugInteraction: Codable, Identifiable, Equatable {
        public var id: UUID = UUID()
        public var drugA: String
        public var drugB: String
        public var severity: InteractionSeverity
        public var description: String
        public var recommendation: String

        public init(id: UUID = UUID(), drugA: String, drugB: String, severity: InteractionSeverity, description: String, recommendation: String) {
            self.id = id
            self.drugA = drugA
            self.drugB = drugB
            self.severity = severity
            self.description = description
            self.recommendation = recommendation
        }
    }

    // MARK: - Dosage Recommendation
    public struct DosageRecommendation: Codable, Identifiable, Equatable {
        public var id: UUID = UUID()
        public var medicineName: String
        public var adultDosage: String
        public var childDosage: String
        public var elderlyDosage: String
        public var warnings: [String]

        public init(id: UUID = UUID(), medicineName: String, adultDosage: String, childDosage: String, elderlyDosage: String, warnings: [String]) {
            self.id = id
            self.medicineName = medicineName
            self.adultDosage = adultDosage
            self.childDosage = childDosage
            self.elderlyDosage = elderlyDosage
            self.warnings = warnings
        }
    }

    // MARK: - Alternative Medicine
    public struct AlternativeMedicine: Codable, Identifiable, Equatable {
        public var id: UUID = UUID()
        public var originalMedicine: String
        public var alternativeName: String
        public var reason: String
        public var type: String

        public init(id: UUID = UUID(), originalMedicine: String, alternativeName: String, reason: String, type: String) {
            self.id = id
            self.originalMedicine = originalMedicine
            self.alternativeName = alternativeName
            self.reason = reason
            self.type = type
        }
    }

    // MARK: - Chat Message (Phase 6)
    public struct ChatMessage: Codable, Identifiable, Equatable {
        public var id: UUID = UUID()
        public var text: String
        public var isUser: Bool
        public var timestamp: Date = Date()

        public init(id: UUID = UUID(), text: String, isUser: Bool, timestamp: Date = Date()) {
            self.id = id
            self.text = text
            self.isUser = isUser
            self.timestamp = timestamp
        }
    }

    // MARK: - Report
    public struct Report: Codable, Identifiable, Equatable {
        public var id: UUID = UUID()
        public var title: String
        public var dateCreated: Date = Date()
        public var prescription: Prescription
        public var interactions: [DrugInteraction]
        public var dosages: [DosageRecommendation]
        public var alternatives: [AlternativeMedicine]

        public init(id: UUID = UUID(), title: String, dateCreated: Date = Date(), prescription: Prescription, interactions: [DrugInteraction], dosages: [DosageRecommendation], alternatives: [AlternativeMedicine]) {
            self.id = id
            self.title = title
            self.dateCreated = dateCreated
            self.prescription = prescription
            self.interactions = interactions
            self.dosages = dosages
            self.alternatives = alternatives
        }
    }
}
