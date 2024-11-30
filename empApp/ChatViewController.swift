import UIKit
import FirebaseFirestore
import FirebaseAuth

class ChatViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    
    var selectedUser: User? // The user being chatted with
    var messages: [Message] = [] // Array to hold chat messages
    let db = Firestore.firestore() // Firestore database reference
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = selectedUser?.name ?? "Chat"
        setupTableView()
        fetchMessages()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MessageCell")
    }
    
    func fetchMessages() {
        guard let currentUserEmail = Auth.auth().currentUser?.email,
              let recipientEmail = selectedUser?.email else { return }

        db.collection("messages")
            .whereField("participants", arrayContains: currentUserEmail)
            .order(by: "timestamp") // Ensure messages are sorted by timestamp
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Error fetching messages: \(error.localizedDescription)")
                    return
                }

                self.messages = querySnapshot?.documents.compactMap { doc -> Message? in
                    let data = doc.data()
                    guard let senderEmail = data["senderEmail"] as? String,
                          let recipientEmailInMessage = data["recipientEmail"] as? String,
                          let text = data["text"] as? String,
                          let timestamp = data["timestamp"] as? Timestamp else {
                        print("Invalid message data: \(doc.data())")
                        return nil
                    }

                    let isRelevantMessage = (senderEmail == currentUserEmail && recipientEmailInMessage == recipientEmail) ||
                                            (senderEmail == recipientEmail && recipientEmailInMessage == currentUserEmail)

                    if isRelevantMessage {
                        return Message(
                            senderName: data["senderName"] as? String ?? "Unknown",
                            senderEmail: senderEmail,
                            recipientName: data["recipientName"] as? String ?? "Unknown",
                            recipientEmail: recipientEmailInMessage,
                            text: text,
                            timestamp: timestamp.dateValue()
                        )
                    } else {
                        return nil
                    }
                } ?? []

                // Ensure the messages are sorted by timestamp
                self.messages.sort { $0.timestamp < $1.timestamp }

                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.scrollToBottom() // Scroll to the latest message
                }
            }
    }

    
    @IBAction func sendButtonTapped(_ sender: UIButton) {
        guard let messageText = messageTextField.text, !messageText.isEmpty,
              let currentUserEmail = Auth.auth().currentUser?.email,
              let recipientEmail = selectedUser?.email else { return }

        let currentUserRef = db.collection("employees").whereField("email", isEqualTo: currentUserEmail)

        currentUserRef.getDocuments { [weak self] querySnapshot, error in
            if let error = error {
                print("Error fetching current user data: \(error.localizedDescription)")
                return
            }

            guard let currentUserData = querySnapshot?.documents.first?.data(),
                  let senderName = currentUserData["name"] as? String else {
                print("Unable to fetch sender's name.")
                return
            }

            guard let recipientName = self?.selectedUser?.name else {
                print("Recipient's name not found.")
                return
            }

            let messageData: [String: Any] = [
                "senderName": senderName,
                "senderEmail": currentUserEmail,
                "recipientName": recipientName,
                "recipientEmail": recipientEmail,
                "text": messageText,
                "timestamp": FieldValue.serverTimestamp(),
                "participants": [currentUserEmail, recipientEmail]
            ]

            self?.db.collection("messages").addDocument(data: messageData) { error in
                if let error = error {
                    print("Error sending message: \(error.localizedDescription)")
                } else {
                    DispatchQueue.main.async {
                        self?.messageTextField.text = ""
                    }
                    print("Message successfully sent!")
                }
            }
        }
    }
    
    func scrollToBottom() {
        guard !messages.isEmpty else { return }
        let lastIndexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: true)
    }
    
    // MARK: - UITableViewDataSource Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath)
        let message = messages[indexPath.row]
        let sender = message.senderEmail == Auth.auth().currentUser?.email ? "You" : message.senderName
        cell.textLabel?.text = "\(sender): \(message.text)"
        return cell
    }
}
