

import Foundation
import AppKit
//import RNCryptor

extension NSAlert {
    
    struct Text {
        
        var message: String
        var information: String
        
        init(message: String = "", information: String = "") {
            self.message = message
            self.information = information
        }
        
    }
    
    convenience init(style: NSAlert.Style = .informational, text: Text) {
        self.init()
        self.alertStyle = style
        self.messageText = text.message
        self.informativeText = text.information
    }
    
}

extension NSAlert {
    
    struct Button {
        
        var title: String
        
        init(title: String = "") {
            self.title = title
        }
        
    }
    
    convenience init(style: NSAlert.Style = .informational, text: Text, button: Button) {
        self.init(style: style, text: text)
        self.addButton(withTitle: button.title)
        self.addButton(withTitle: "Cancel")
    }
    
}

extension NSAlert {
    
    struct TextField {
        
        var text: String
        var placeholder: String
        
        init(text: String = "", placeholder: String = "") {
            self.text = text
            self.placeholder = placeholder
        }
        
    }
    
    convenience init(style: NSAlert.Style = .informational, text: Text, textField: TextField, button: Button) {
        self.init(style: style, text: text, button: button)
        self.textField = NSTextField(frame: NSRect(x: 0.0, y: 0.0, width: 240.0, height: 22.0))
        self.textField?.stringValue = textField.text
        self.textField?.placeholderString = textField.placeholder
    }
    
    var textField: NSTextField? {
        get {
            return accessoryView as? NSTextField
        }
        set {
            accessoryView = newValue
        }
    }
    
}



//func encryptMessage(message: String, encryptionKey: String) throws -> String {
//    let messageData = message.data(using: .utf8)!
//    let cipherData = RNCryptor.encrypt(data: messageData, withPassword: encryptionKey)
//    return cipherData.base64EncodedString()
//}
//
//func decryptMessage(encryptedMessage: String, encryptionKey: String) throws -> String {
//
//    let encryptedData = Data.init(base64Encoded: encryptedMessage)!
//    let decryptedData = try RNCryptor.decrypt(data: encryptedData, withPassword: encryptionKey)
//    let decryptedString = String(data: decryptedData, encoding: .utf8)!
//
//    return decryptedString
//}
