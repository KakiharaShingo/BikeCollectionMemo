import SwiftUI
import MessageUI

struct MailComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let subject: String
    let messageBody: String
    let isHTML: Bool
    let onResult: ((MFMailComposeResult, Error?) -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    
    init(recipients: [String], subject: String, messageBody: String, isHTML: Bool = false, onResult: ((MFMailComposeResult, Error?) -> Void)? = nil) {
        self.recipients = recipients
        self.subject = subject
        self.messageBody = messageBody
        self.isHTML = isHTML
        self.onResult = onResult
    }
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mailController = MFMailComposeViewController()
        mailController.mailComposeDelegate = context.coordinator
        mailController.setToRecipients(recipients)
        mailController.setSubject(subject)
        mailController.setMessageBody(messageBody, isHTML: isHTML)
        return mailController
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposeView
        
        init(_ parent: MailComposeView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.onResult?(result, error)
            parent.dismiss()
        }
    }
}

// メール送信可能かチェックする関数
func canSendMail() -> Bool {
    return MFMailComposeViewController.canSendMail()
}