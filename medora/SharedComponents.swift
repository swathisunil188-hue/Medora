import SwiftUI

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false

    @State private var isVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)

            HStack {
                if isSecure && !isVisible {
                    SecureField("Enter \(title.lowercased())", text: $text)
                } else {
                    TextField("Enter \(title.lowercased())", text: $text)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                }
                if isSecure {
                    Button(action: { isVisible.toggle() }) {
                        Image(systemName: isVisible ? "eye.slash" : "eye")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(title).fontWeight(.semibold)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(colors: [.blue, .teal], startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(12)
        }
        .disabled(isLoading)
    }
}
