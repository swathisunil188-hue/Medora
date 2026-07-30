import SwiftUI

struct ChatbotView: View {
    @State private var messages: [ChatMessage] = [
        ChatMessage(text: "Hi! I'm the MediVerify AI assistant. Ask me about a medicine, dosage, or general health question. I'm not a doctor — for anything urgent, please contact a professional.", isUser: false)
    ]
    @State private var inputText = ""
    @State private var isSending = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(messages) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                        }
                        if isSending {
                            HStack {
                                ProgressView()
                                Text("Thinking…").font(.caption).foregroundColor(.gray)
                            }
                            .padding(.leading, 4)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }

            HStack(spacing: 10) {
                TextField("Ask about a medicine…", text: $inputText, axis: .vertical)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)

                Button(action: send) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.blue)
                }
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isSending)
            }
            .padding()
        }
        .navigationTitle("Ask MediVerify AI")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        messages.append(ChatMessage(text: text, isUser: true))
        inputText = ""
        isSending = true
        errorMessage = nil

        Task {
            do {
                let reply = try await WatsonChatService.shared.sendMessage(text)
                await MainActor.run {
                    messages.append(ChatMessage(text: reply, isUser: false))
                    isSending = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSending = false
                }
            }
        }
    }
}

private struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 40) }

            Text(message.text)
                .padding(12)
                .background(message.isUser ? Color.blue : Color(.systemGray5))
                .foregroundColor(message.isUser ? .white : .primary)
                .cornerRadius(16)

            if !message.isUser { Spacer(minLength: 40) }
        }
    }
}

#Preview {
    NavigationStack { ChatbotView() }
}
