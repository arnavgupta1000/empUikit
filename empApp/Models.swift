import Foundation

// Model for a user
struct User {
    let email: String   // User's email address
    let name: String    // User's full name
}

// Model for a message
struct Message {
    let senderName: String        // Sender's full name
    let senderEmail: String       // Sender's email
    let recipientName: String     // Recipient's full name
    let recipientEmail: String    // Recipient's email
    let text: String              // The chat message text
    let timestamp: Date           // Timestamp of when the message was sent
}
