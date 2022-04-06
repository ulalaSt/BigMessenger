//
//  DatabaseManager.swift
//  BigMessenger
//
//  Created by user on 23.03.2022.
//

import Foundation
import FirebaseDatabase
import MessageKit
import CoreLocation

///To read and write the realtime database on firebase
final class DatabaseManager {
    static let shared = DatabaseManager()
    private let database = Database.database().reference()
    //to get a FIRDatabaseReference for the root of your Firebase Database
    
    static func safeEmail(emailAdress: String) -> String {
        var safeEmail = emailAdress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
}

// MARK: - Account Management

extension DatabaseManager {
    
    ///Checks if user exists in Firebase database
    func userExists(with email: String, completion: @escaping((Bool)->Void)){
        let safeEmail = DatabaseManager.safeEmail(emailAdress: email)
        database.child(safeEmail).observeSingleEvent(of: .value) { snapshot in
            guard snapshot.value as? [String:Any] != nil else {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    public func insertUser(with user: ChatAppUser, completion: @escaping (Bool)->Void){
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName
        ]) {[weak self] error, _ in
            guard let strongRef = self else {
                return
            }
            guard error == nil else {
                print("Failed to write to database")
                completion(false)
                return
            }
            
            strongRef.database.child("users").observeSingleEvent(of: .value) { snapshot in
                if var userCollection = snapshot.value as? [[String:String]] {
                    // add to "users" array
                    userCollection.append(
                        [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail
                        ]
                    )
                    strongRef.database.child("users").setValue(userCollection) { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                    
                } else {
                    //create "users" array
                    let newCollection: [[String:String]] = [
                        [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail
                        ]
                    ]
                    strongRef.database.child("users").setValue(newCollection) { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                }
            }
        }
    }
    public func fetchAllUsers(completion: @escaping (Result<[[String:String]], Error>)->Void) {
        database.child("users").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? [[String:String]] else {
                completion(.failure(DatabaseErrors.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
    public enum DatabaseErrors: Error {
        case failedToFetch
    }
    
}
//MARK: - Sending messages
extension DatabaseManager {
    //Scheme
    //    "asdasdasd": {
    //        message: [
    
    //        ]
    //    }
    //    conversation => [
    //        [
    //            "conversation_id": "asdasdasd"
    //            "other user email":
    //                "latest_message_data"=> {
    //                    "date":Date()
    //                    "latest_message": "hi"
    //                    "is_read": true/false
    //                }
    //        ]
    //    ]
    
    public func createNewConversation(with otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping (Bool)->Void) {
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAdress: currentUserEmail)
        let ref = database.child(safeEmail)
        
        ref.observeSingleEvent(of: .value) {[weak self] snapshot in
            guard var userNode = snapshot.value as? [String:Any], let myName = UserDefaults.standard.value(forKey: "name") as? String
            else {
                print("can not create user node")
                completion(false)
                return
            }
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            var message = ""
            
            switch firstMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            let convID = "conversation_\(firstMessage.messageId)"
            let newConData: [String: Any] = [
                "conversation_id": convID,
                "other user email": otherUserEmail,
                "name": name,
                "latest_message_data": [
                    "date": dateString,
                    
                    "message": message,
                    "is_read": false
                ]
            ]
            
            let recipient_newConData: [String: Any] = [
                "conversation_id": convID,
                "other user email": safeEmail,
                "name": myName,
                "latest_message_data": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) {[weak self] snapshot in
                if var conversations = snapshot.value as? [[String:Any]] {
                    conversations.append(recipient_newConData)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversations)
                } else {
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConData])
                }
            }
            
            if var conversations = userNode["conversations"] as? [[String:Any]] {
                //exists, append
                conversations.append(newConData)
                userNode["conversations"] = conversations
                ref.setValue(userNode) { err, _ in
                    guard err == nil else {
                        print("Can not set asign usernode")
                        completion(false)
                        return
                    }
                    self?.finishCreatingConv(name: name, convID: convID, firstMessage: firstMessage, completion: completion)
                }
            }
            else {
                //create
                userNode["conversations"] = [
                    newConData
                ]
                ref.setValue(userNode) {[weak self] err, _ in
                    guard err == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConv(name: name, convID: convID, firstMessage: firstMessage, completion: completion)
                }
            }
        }
    }
    private func finishCreatingConv(name: String, convID: String, firstMessage: Message, completion: @escaping (Bool)->Void) {
        var message = ""
        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        let currentUserEmail = DatabaseManager.safeEmail(emailAdress: myEmail)
        let collectionMessage: [String:Any] = [
            "id": firstMessage.messageId,
            "name": name,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "sender_email": currentUserEmail,
            "isRead":false
        ]
        let value: [String:Any] = [
            "messages": [
                collectionMessage
            ]
        ]
        database.child("\(convID)").setValue(value) { err, _ in
            guard err == nil else {
                completion(false)
                return
            }
            completion(true)
        }
    }
    public func getAllConversations(for email: String, completion: @escaping (Result<[Conversation], Error>)->Void) {
        database.child("\(email)/conversations").observe(.value) { snapshot in
            guard let value = snapshot.value as? [[String:Any]] else {
                return
            }
            let conversations: [Conversation] = value.compactMap({ dictionary in
                guard let id = dictionary["conversation_id"] as? String,
                      let name = dictionary["name"] as? String,
                      let otherEmail = dictionary["other user email"] as? String,
                      let latestMessageData = dictionary["latest_message_data"] as? [String:Any],
                      let isRead = latestMessageData["is_read"] as? Bool,
                      let latestMessage = latestMessageData["message"] as? String,
                      let messageDate = latestMessageData["date"] as? String
                else {
                    completion(.failure(DatabaseErrors.failedToFetch))
                    return nil
                }
                
                let latestMessageObject = LatestMessage(date: messageDate, text: latestMessage, isRead: isRead)
                return Conversation(id: id, name: name, otherUserEmail: otherEmail, latestMessage: latestMessageObject)
            })
            completion(.success(conversations))
        }
    }
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<[Message], Error>)->Void){
        database.child("\(id)/messages").observe(.value) { snapshot in
            guard let value = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseErrors.failedToFetch))
                return
            }
            let messages: [Message] = value.compactMap({ dictionary in
                guard let type = dictionary ["type"] as? String,
                      let date = dictionary["date"] as? String,
                      let id = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String,
                      let isRead = dictionary["isRead"] as? Bool,
                      let senderEmail = dictionary["sender_email"] as? String,
                      let realDate = ChatViewController.dateFormatter.date(from: date)
                else {
                    return nil
                }
                var kind: MessageKind = .text("")
                switch type {
                case "text":
                    guard let data = dictionary["content"] as? String else {
                        return nil
                    }
                    kind = .text(data)
                case "attributedText":
                    break
                case "photo":
                    guard let data = dictionary["content"] as? String else {
                        return nil
                    }
                    
                    let media = Media(url: URL(string: data),
                                      image: nil ,
                                      placeholderImage: UIImage(systemName: "plus")!,
                                      size: CGSize(width: 300, height: 300))
                    kind = .photo(media)
                    break
                case "video":
                    guard let data = dictionary["content"] as? String else {
                        return nil
                    }
                    
                    let media = Media(url: URL(string: data),
                                      image: nil ,
                                      placeholderImage: UIImage(systemName: "plus")!,
                                      size: CGSize(width: 300, height: 300))

                    kind = .video(media)
                    break
                case "location":
                    guard let coorString = dictionary["content"] as? String else {
                        return nil
                    }
                    let coorArray = coorString.components(separatedBy: ",")
                    guard let lon = Double(coorArray[0]), let lat = Double(coorArray[1]) else {
                        return nil
                    }
                    let location = Location(location: CLLocation(latitude: lat, longitude: lon) ,
                                            size: CGSize(width: 150, height: 150))
                    kind = .location(location)
                    break
                case "emoji":
                    break
                case "audio":
                    break
                case "contact":
                    break
                case "linkPreview":
                    break
                case "custom":
                    break
                default:
                    break
                }
                let sender = Sender(photoURL: "",
                                    senderId: senderEmail,
                                    displayName: name)
                return Message(sender: sender,
                               messageId: id,
                               sentDate: realDate,
                               kind: kind)
            })
            completion(.success(messages))
        }
    }
    public func getDataFor(path: String, completion: @escaping (Result<Any, Error>)->Void) {
        database.child(path).observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value else {
                completion(.failure(DatabaseErrors.failedToFetch))
                return
            }
            completion(.success(value))
            
        }
    }
    public func sendMessage(to conversation: String, otherUserEmail: String, name: String, message: Message, completion: @escaping (Bool)->Void){
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        let currentEmail = DatabaseManager.safeEmail(emailAdress: myEmail)
        //add message to messages
        database.child("\(conversation)/messages").observeSingleEvent(of: .value) {[weak self] snapshot in
            guard let strongRef = self else {
                return
            }
            guard var messages = snapshot.value as? [[String:Any]] else {
                completion(false)
                return
            }
            var content = ""
            var contentVisual = ""
            switch message.kind {
            case .text(let messageText):
                content = messageText
                contentVisual = messageText
            case .attributedText(_):
                break
            case .photo(let media):
                if let targetUrlString = media.url?.absoluteString {
                    content = targetUrlString
                }
                contentVisual = "🌄 Photo"
            case .video(let media ):
                if let targetUrlString = media.url?.absoluteString {
                    content = targetUrlString
                }
                contentVisual = "🎥 Video"
            case .location(let locationData):
                let location = locationData.location
                content = "\(location.coordinate.longitude),\(location.coordinate.latitude)"
                contentVisual = "📍 Location"
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            let messageDate = message.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                completion(false)
                return
            }
            let currentUserEmail = DatabaseManager.safeEmail(emailAdress: myEmail)
            let collectionMessage: [String:Any] = [
                "id": message.messageId,
                "name": name,
                "type": message.kind.messageKindString,
                "content": content,
                "date": dateString,
                "sender_email": currentUserEmail,
                "isRead":false
            ]
            messages.append(collectionMessage)
            strongRef.database.child("\(conversation)/messages").setValue(messages) { err, _ in
                guard err == nil else {
                    completion(false)
                    return
                }
                
                strongRef.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
                    var databaseEntryConv = [[String:Any]]()
                    let convData: [String:Any] = [
                        "date": dateString,
                        "is_read": false,
                        "message": contentVisual
                    ]
                    if var currentUserConv = snapshot.value as? [[String:Any]] {
                        var pos = 0
                        var targetConvData: [String:Any]?
                        for conv in currentUserConv {
                            if let convID = conv["conversation_id"] as? String, convID == conversation {
                                targetConvData = conv
                                break
                            }
                            pos += 1
                        }
                        if var targetConvData = targetConvData {
                            targetConvData["latest_message_data"] = convData
                            currentUserConv[pos] = targetConvData
                            databaseEntryConv = currentUserConv
                        } else {
                            let newConData: [String: Any] = [
                                "conversation_id": conversation,
                                "other user email": DatabaseManager.safeEmail(emailAdress: otherUserEmail),
                                "name": name,
                                "latest_message_data": convData
                            ]
                            currentUserConv.append(newConData)
                            databaseEntryConv = currentUserConv
                        }
                    } else {
                        let newConData: [String: Any] = [
                            "conversation_id": conversation,
                            "other user email": DatabaseManager.safeEmail(emailAdress: otherUserEmail),
                            "name": name,
                            "latest_message_data": convData
                        ]
                        databaseEntryConv = [newConData]
                    }

                    strongRef.database.child("\(currentEmail)/conversations").setValue(databaseEntryConv) { err, _ in
                        guard err == nil else {
                            completion(false)
                            return
                        }
                        //update latest for recipient
                        strongRef.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
                            guard let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
                                return
                            }
                            var otherUserEntryConv = [[String:Any]]()
                            let convData: [String:Any] = [
                                "date": dateString,
                                "is_read": false,
                                "message": contentVisual
                            ]
                            if var otherUserConv = snapshot.value as? [[String:Any]] {
                                var pos = 0
                                var targetConvData: [String:Any]?
                                for conv in otherUserConv {
                                    if let convID = conv["conversation_id"] as? String, convID == conversation {
                                        targetConvData = conv
                                        break
                                    }
                                    pos += 1
                                }
                                if var targetConvData = targetConvData {
                                    targetConvData["latest_message_data"] = convData
                                    otherUserConv[pos] = targetConvData
                                    otherUserEntryConv = otherUserConv
                                } else {
                                    let newConData: [String: Any] = [
                                        "conversation_id": conversation,
                                        "other user email": DatabaseManager.safeEmail(emailAdress: otherUserEmail),
                                        "name": currentName,
                                        "latest_message_data": convData
                                    ]
                                    otherUserConv.append(newConData)
                                    otherUserEntryConv = otherUserConv
                                }
                            } else {
                                let newConData: [String: Any] = [
                                    "conversation_id": conversation,
                                    "other user email": DatabaseManager.safeEmail(emailAdress: currentEmail),
                                    "name": currentName,
                                    "latest_message_data": convData
                                ]
                                otherUserEntryConv = [newConData]
                            }
                            strongRef.database.child("\(otherUserEmail)/conversations").setValue(otherUserEntryConv) { err, _ in
                                guard err == nil else {
                                    completion(false)
                                    return
                                }
                                completion(true)
                            }
                        }
                    }
                }
            }
        }
    }
    public func deleteConversation(convID: String, completion: @escaping (Bool)->Void){
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAdress: email)
        //get all conv for user
        let ref = database.child("\(safeEmail)/conversations")
        ref.observeSingleEvent(of: .value) { snapshot in
            if var conversations = snapshot.value as? [[String: Any]] {
                var positionToRemove = 0
                for conversation in conversations {
                    if let id = conversation["conversation_id"] as? String, id == convID {
                         break
                    }
                    positionToRemove+=1
                }
                conversations.remove(at: positionToRemove)
                ref.setValue(conversations) { err, _ in
                    guard err == nil else {
                        completion(false)
                        return
                    }
                    print("Deleted conversation")
                    completion(true)
                }
                
            }
        }
        //delete the specific one
        //reset the conv in database
    }
    public func ConversationExists(with targetRecipientEmail: String, completion: @escaping (Result<String, Error>) -> Void){
        let safeRecipientEmail = DatabaseManager.safeEmail(emailAdress: targetRecipientEmail)
        guard let SenderEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeSenderEmail = DatabaseManager.safeEmail(emailAdress: SenderEmail)
        
        database.child("\(safeRecipientEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
            guard let collection = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseErrors.failedToFetch))
                return
            }
            if let targetConversation = collection.first(where: {
                guard let otherUserFromRecipient = $0["other user email"] as? String else {
                    return false
                }
                return otherUserFromRecipient == safeSenderEmail
            }){
                guard let id = targetConversation["conversation_id"] as? String else {
                    completion(.failure(DatabaseErrors.failedToFetch))
                    return
                }
                completion(.success(id))
            } else {
                completion(.failure(DatabaseErrors.failedToFetch))
            }
        }
    }
}




struct ChatAppUser {
    let firstName: String
    let lastName: String
    let emailAdress: String
    //let pictureURL: String
    var safeEmail: String {
        var safeEmail = emailAdress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    var pictureFileName: String {
        return "\(safeEmail)_profile_image.png"
    }
}
