import SwiftUI

struct FeedTabView: View {
    @State private var messageText = ""
    @State private var isSending = false
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        let partyService = PartyService.shared
        let messages = partyService.messages
        let _ = print("FeedTabView: body evaluated, messages.count = \(messages.count)")

        VStack(spacing: 0) {
            if messages.isEmpty {
                emptyStateView
            } else {
                messageListView(messages: messages, partyService: partyService)
            }

            messageInputView(partyService: partyService)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isTextFieldFocused = false
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No messages yet")
                .font(.bricolage(.title2))

            Text("Send a message to your party!")
                .font(.bricolage(.subheadline))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()
        }
    }

    private func messageListView(messages: [Message], partyService: PartyService) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { message in
                        if message.isSystemMessage {
                            SystemMessageView(message: message)
                                .id(message.id)
                        } else {
                            MessageBubbleView(
                                message: message,
                                isCurrentUser: message.senderId == partyService.currentPlayer?.id,
                                teamColor: teamColor(for: message.teamId, partyService: partyService)
                            )
                            .id(message.id)
                        }
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.immediately)
            .onChange(of: messages.count) { _, _ in
                if let lastMessage = messages.last {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onAppear {
                if let lastMessage = messages.last {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
        }
    }

    private func messageInputView(partyService: PartyService) -> some View {
        HStack(spacing: 12) {
            TextField("Message...", text: $messageText, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .lineLimit(1...4)
                .focused($isTextFieldFocused)

            Button {
                sendMessage(partyService: partyService)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(canSend ? .blue : .gray)
            }
            .disabled(!canSend)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    private var canSend: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
    }

    private func sendMessage(partyService: PartyService) {
        guard canSend else { return }

        let text = messageText
        messageText = ""
        isSending = true
        isTextFieldFocused = false
        Haptics.light()

        Task {
            do {
                try await partyService.sendMessage(text: text)
            } catch {
                Haptics.error()
                messageText = text
            }
            isSending = false
        }
    }

    private func teamColor(for teamId: String?, partyService: PartyService) -> Color? {
        guard let teamId = teamId,
              let team = partyService.currentParty?.teams.first(where: { $0.id == teamId })
        else { return nil }
        return team.color
    }
}

struct MessageBubbleView: View {
    let message: Message
    let isCurrentUser: Bool
    let teamColor: Color?

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if isCurrentUser {
                Spacer(minLength: 60)
            }

            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                HStack(spacing: 6) {
                    
                    Text(isCurrentUser ? "You" : message.senderName)
                        .font(.bricolage(.caption))
                        .foregroundStyle(.secondary)
                    
                    if let teamColor = teamColor {
                        Circle()
                            .fill(teamColor)
                            .frame(width: 8, height: 8)
                    }
                    
                    Text(message.timestamp.formatted(.dateTime.hour().minute())) // 24h format
                        .font(.bricolage(.caption))
                        .foregroundStyle(.tertiary)
                    
                }

                Text(message.text)
                    .font(.bricolage(.body))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isCurrentUser ? Color.blue : Color(.systemGray5))
                    .foregroundStyle(isCurrentUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }

            if !isCurrentUser {
                Spacer(minLength: 60)
            }
        }
    }
}

struct SystemMessageView: View {
    let message: Message

    var body: some View {
        Text(message.text)
            .font(.bricolage(size: 14, weight: .semibold))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background {
                // Monochrome mesh gradient - dark with subtle center glow
                if #available(iOS 18.0, *) {
                    MeshGradient(
                        width: 3,
                        height: 3,
                        points: [
                            [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                            [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                            [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                        ],
                        colors: [
                            .black, .black, .black,
                            Color(white: 0.1), Color(white: 0.25), Color(white: 0.1),
                            .black, .black, .black
                        ]
                    )
                } else {
                    // Fallback for older iOS
                    LinearGradient(
                        colors: [.black, Color(white: 0.2), .black],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    FeedTabView()
}
