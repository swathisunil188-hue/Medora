import SwiftUI

struct DrugInteractionView: View {
    @State private var drugNames: [String] = ["", ""]
    @State private var isChecking = false
    @State private var results: [DrugInteraction] = []
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                Text("Enter two or more medicines to check for label-documented interactions. This uses public FDA data and RxNorm — it is not a substitute for advice from a pharmacist or doctor.")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)

                VStack(spacing: 12) {
                    ForEach(drugNames.indices, id: \.self) { index in
                        HStack {
                            CustomTextField(title: "Medicine \(index + 1)", text: $drugNames[index])
                            if drugNames.count > 2 {
                                Button {
                                    drugNames.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                                .padding(.top, 20)
                            }
                        }
                    }

                    Button {
                        drugNames.append("")
                    } label: {
                        Label("Add another medicine", systemImage: "plus.circle")
                            .font(.footnote)
                    }
                }

                PrimaryButton(title: "Check Interactions", action: runCheck, isLoading: isChecking)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                }

                if !results.isEmpty {
                    SectionHeader(title: "Results")
                    ForEach(results) { interaction in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("\(interaction.drugA) + \(interaction.drugB)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Spacer()
                                SeverityBadge(severity: interaction.severity)
                            }
                            Text(interaction.description)
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(interaction.recommendation)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Interaction Checker")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func runCheck() {
        let cleaned = drugNames.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        guard cleaned.count >= 2 else {
            errorMessage = "Enter at least two medicine names."
            return
        }
        errorMessage = nil
        results = []
        isChecking = true

        Task {
            var pairResults: [DrugInteraction] = []
            for i in 0..<cleaned.count {
                for j in (i + 1)..<cleaned.count {
                    let interaction = await DrugAPIService.shared.checkInteraction(drugA: cleaned[i], drugB: cleaned[j])
                    pairResults.append(interaction)
                }
            }
            await MainActor.run {
                results = pairResults
                isChecking = false
            }
        }
    }
}

#Preview {
    NavigationStack { DrugInteractionView() }
}
