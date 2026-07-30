import SwiftUI
import PhotosUI

struct ScanPrescriptionView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showCamera = false
    @State private var isProcessing = false
    @State private var recognizedLines: [String] = []
    @State private var errorMessage: String?
    @State private var editablePrescription: Prescription?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                if let selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 260)
                        .cornerRadius(12)
                        .shadow(radius: 3)
                } else {
                    EmptyStateView(
                        icon: "camera.viewfinder",
                        title: "No image yet",
                        message: "Take a photo of a prescription or choose one from your library. Recognition runs fully on-device."
                    )
                }

                HStack(spacing: 12) {
                    Button {
                        showCamera = true
                    } label: {
                        Label("Camera", systemImage: "camera.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(12)
                    }

                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label("Photo Library", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.teal.opacity(0.1))
                            .foregroundColor(.teal)
                            .cornerRadius(12)
                    }
                }

                if isProcessing {
                    ProgressView("Reading text on-device…")
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                }

                if !recognizedLines.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Detected Text")
                        ForEach(recognizedLines, id: \.self) { line in
                            Text(line)
                                .font(.footnote)
                                .padding(.vertical, 2)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)

                    if let prescription = editablePrescription {
                        PrimaryButton(title: "Review & Save Prescription (\(prescription.medicines.count) meds found)") {
                            savePrescription(prescription)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Scan Prescription")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker(image: $selectedImage)
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    selectedImage = uiImage
                    runOCR(on: uiImage)
                }
            }
        }
        .onChange(of: selectedImage) { _, newImage in
            if let newImage, showCamera == false {
                runOCR(on: newImage)
            }
        }
    }

    private func runOCR(on image: UIImage) {
        isProcessing = true
        errorMessage = nil
        recognizedLines = []
        editablePrescription = nil

        OCRService.shared.recognizeText(from: image) { result in
            DispatchQueue.main.async {
                isProcessing = false
                switch result {
                case .success(let lines):
                    recognizedLines = lines
                    let currentUser = LocalStorageService.shared.getCurrentUser()
                    editablePrescription = OCRService.shared.parsePrescription(
                        lines: lines,
                        patientName: currentUser?.name ?? "Unknown",
                        doctorName: "Dr. (confirm)",
                        hospital: "(confirm hospital)"
                    )
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func savePrescription(_ prescription: Prescription) {
        PrescriptionStore.shared.save(prescription)
        errorMessage = nil
        // Simple confirmation via detected text panel replacement
        recognizedLines = ["Saved ✓ — you can check interactions for these medicines from the Interaction Checker."]
    }
}

/// Wraps UIImagePickerController for camera capture (SwiftUI has no
/// built-in camera-only picker as of iOS 17).
struct CameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

/// Very small local store for saved prescriptions (mirrors LocalStorageService pattern).
class PrescriptionStore {
    static let shared = PrescriptionStore()
    private init() {}
    private let key = "saved_prescriptions"

    func save(_ prescription: Prescription) {
        var all = loadAll()
        all.append(prescription)
        if let data = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func loadAll() -> [Prescription] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let list = try? JSONDecoder().decode([Prescription].self, from: data) else {
            return []
        }
        return list
    }
}

#Preview {
    NavigationStack { ScanPrescriptionView() }
}
