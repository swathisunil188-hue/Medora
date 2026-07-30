import SwiftUI

struct HomeDashboardView: View {
    @State private var currentUser: User? = LocalStorageService.shared.getCurrentUser()
    @State private var showLogoutConfirm = false
    @State private var navigateToLogin = false

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Greeting header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Hello, \(currentUser?.name.components(separatedBy: " ").first ?? "there") 👋")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Stay on top of your prescriptions")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Button(action: { showLogoutConfirm = true }) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 34))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.top, 12)

                    // Feature grid
                    SectionHeader(title: "Tools")
                    LazyVGrid(columns: columns, spacing: 16) {
                        NavigationLink {
                            ScanPrescriptionView()
                        } label: {
                            DashboardCard(
                                icon: "camera.viewfinder",
                                title: "Scan Prescription",
                                subtitle: "Extract medicines from a photo, offline",
                                tint: .blue,
                                action: {}
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            DrugInteractionView()
                        } label: {
                            DashboardCard(
                                icon: "exclamationmark.triangle.fill",
                                title: "Interaction Checker",
                                subtitle: "Check drug-drug interactions via RxNorm/OpenFDA",
                                tint: .orange,
                                action: {}
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            ChatbotView()
                        } label: {
                            DashboardCard(
                                icon: "message.fill",
                                title: "Ask MediVerify AI",
                                subtitle: "Chat about medicines and dosages",
                                tint: .teal,
                                action: {}
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            ReportsListView()
                        } label: {
                            DashboardCard(
                                icon: "doc.text.fill",
                                title: "My Reports",
                                subtitle: "View & export saved PDF reports",
                                tint: .purple,
                                action: {}
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // Health snapshot
                    SectionHeader(title: "Your Health Info")
                    VStack(alignment: .leading, spacing: 10) {
                        HealthInfoRow(label: "Allergies", value: (currentUser?.allergies.isEmpty ?? true) ? "None on file" : currentUser!.allergies.joined(separator: ", "))
                        Divider()
                        HealthInfoRow(label: "Conditions", value: (currentUser?.medicalConditions.isEmpty ?? true) ? "None on file" : currentUser!.medicalConditions.joined(separator: ", "))
                        Divider()
                        HealthInfoRow(label: "Emergency Contact", value: currentUser?.emergencyContact.isEmpty == false ? currentUser!.emergencyContact : "Not set")
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(16)

                    Spacer(minLength: 20)
                }
                .padding(.horizontal)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarBackButtonHidden(true)
            .navigationDestination(isPresented: $navigateToLogin) { LoginView() }
            .confirmationDialog("Log out of MediVerify AI?", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
                Button("Log Out", role: .destructive) {
                    LocalStorageService.shared.logout()
                    navigateToLogin = true
                }
                Button("Cancel", role: .cancel) {}
            }
            .onAppear {
                currentUser = LocalStorageService.shared.getCurrentUser()
            }
        }
    }
}

private struct HealthInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.footnote)
                .foregroundColor(.gray)
                .frame(width: 130, alignment: .leading)
            Text(value)
                .font(.footnote)
                .fontWeight(.medium)
            Spacer()
        }
    }
}

#Preview {
    HomeDashboardView()
}
