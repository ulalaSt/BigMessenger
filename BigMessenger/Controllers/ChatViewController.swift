//
//  ChatViewController.swift
//  BigMessenger
//
//  Created by user on 24.03.2022.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage
import AVKit
import AVFoundation
import CoreLocation

final class ChatViewController: MessagesViewController {
    
    private var senderPhotoURL: URL?
    private var otherUserPhotoURL: URL?
    
    public let otherUserEmail: String
    private var id: String?
    
    public static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .long
        df.locale =  Locale(identifier: "en_us")
        return df
    }()
    
    public var isNewConversation = false
    private var messages = [Message]()
    private var selfSender: Sender? = {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeEmail = DatabaseManager.safeEmail(emailAdress: email)
        return Sender(photoURL: "",
                      senderId: safeEmail,
                      displayName: "Me")
    }()
    init(with email: String, id: String?) {
        otherUserEmail = email
        self.id = id
        super.init(nibName: nil, bundle: nil)
        if let conv = id {
            listenToMessages(id: conv)
            print("Listening Conversation with ID: \(conv)")
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .link
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        setUpInputButton()
    }
    private func setUpInputButton(){
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside { [weak self]_ in
            self?.presentInputActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    private func presentInputActionSheet(){
        let actionsheet = UIAlertController(title: "Attach Media",
                                            message: "What would you like to attach?",
                                            preferredStyle: .actionSheet)
        actionsheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: { [weak self] _ in
            self?.presentPhotoInputActionSheet()
        }))
        actionsheet.addAction(UIAlertAction(title: "Video", style: .default, handler: { [weak self] _ in
            self?.presentVideoInputActionSheet()
        }))
        actionsheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: { _ in
            
        }))
        actionsheet.addAction(UIAlertAction(title: "Location", style: .default, handler: { [weak self] _ in
            self?.presentLocationPicker()
        }))
        actionsheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionsheet, animated: true, completion: nil)
    }
    private func presentPhotoInputActionSheet(){
        let actionsheet = UIAlertController(title: "Attach Photo",
                                            message: "Where would you like to attach photo from?",
                                            preferredStyle: .actionSheet)
        actionsheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true, completion: nil)
        }))
        actionsheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: {[weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true, completion: nil)
        }))
        actionsheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionsheet, animated: true, completion: nil)
    }
    private func presentVideoInputActionSheet(){
        let actionsheet = UIAlertController(title: "Attach Video",
                                            message: "Where would you like to attach video from?",
                                            preferredStyle: .actionSheet)
        actionsheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true, completion: nil)
        }))
        actionsheet.addAction(UIAlertAction(title: "Library", style: .default, handler: {[weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true, completion: nil)
        }))
        actionsheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionsheet, animated: true, completion: nil)
    }
    private func presentLocationPicker(){
        let vc = LocationPickerViewController(coordinates: nil)
        vc.title = "Pick Location"
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.completion = {[weak self] selectionCoordinates in
            guard let strongRef = self else {
                return
            }
            let longitude: Double = selectionCoordinates.longitude
            let latitude: Double = selectionCoordinates.latitude
            let location = Location(location: CLLocation(latitude: latitude, longitude: longitude),
                                 size: .zero)
            guard let messageID = strongRef.createMessageID(),
                  let conversationID = strongRef.id,
                  let name = strongRef.title,
                  let selfSender = strongRef.selfSender else {
                      return
                  }
            let message = Message(sender: selfSender,
                                  messageId: messageID,
                                  sentDate: Date(),
                                  kind: .location(location))
            DatabaseManager.shared.sendMessage(to: conversationID,
                                               otherUserEmail: strongRef.otherUserEmail,
                                               name: name,
                                               message: message) { success in
                if success {
                    print("sent location message")
                } else {
                    print("failed to send location message")
                }
            }
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    private func listenToMessages(id: String){
        DatabaseManager.shared.getAllMessagesForConversation(with: id) { [weak self] result in
            switch result {
            case .success(let data):
                guard !data.isEmpty else {
                    return
                }
                self?.messages = data
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                }
            case .failure(let err):
                print("Error on listening the messages: \(err)")
            }
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
    }
}
extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let messageID = createMessageID(),
              let conversationID = id,
              let name = self.title,
              let selfSender = selfSender else {
                  picker.dismiss(animated: true, completion: nil)
                  return
              }
        if let image = info[.editedImage] as? UIImage,
           let imageData = image.pngData() {
            let fileName = "photo_message_"+messageID.replacingOccurrences(of: " ", with: "-")+".png"
            picker.dismiss(animated: true, completion: nil)
            //Upload Image
            StorageManager.shared.uploadMessagePictures(with: imageData, fileName: fileName, completion: {[weak self] result in
                guard let strongRef = self else {
                    return
                }
                switch result {
                case .success(let urlString):
                    //ready to send
                    let media = Media(url: URL(string: urlString),
                                      image: nil,
                                      placeholderImage: UIImage(systemName: "plus")!,
                                      size: .zero)
                    let message = Message(sender: selfSender,
                                          messageId: conversationID,
                                          sentDate: Date(),
                                          kind: .photo(media))
                    DatabaseManager.shared.sendMessage(to: conversationID,
                                                       otherUserEmail: strongRef.otherUserEmail,
                                                       name: name,
                                                       message: message) { success in
                        if success {
                            print("sent photo message")
                        } else {
                            print("failed to send photo message")
                        }
                    }
                case .failure(let err):
                    print("photo upload error: \(err)")
                }
            })
        } else if let videoURL = info[.mediaURL] as? URL {
            let fileName = "video_message_"+messageID.replacingOccurrences(of: " ", with: "-")+".mov"
            
            //Upload video
            StorageManager.shared.uploadMessageVideos(with: videoURL, fileName: fileName, completion: {[weak self] result in
                
                print("Video was uploaded")
                guard let strongRef = self else {
                    return
                }
                switch result {
                case .success(let urlString):
                    //ready to send
                    let media = Media(url: URL(string: urlString),
                                      image: nil,
                                      placeholderImage: UIImage(systemName: "plus")!,
                                      size: .zero)
                    let message = Message(sender: selfSender,
                                          messageId: conversationID,
                                          sentDate: Date(),
                                          kind: .video(media))
                    DatabaseManager.shared.sendMessage(to: conversationID,
                                                       otherUserEmail: strongRef.otherUserEmail,
                                                       name: name,
                                                       message: message) { success in
                        if success {
                            picker.dismiss(animated: true, completion: nil)
                            print("sent video message")
                        } else {
                            picker.dismiss(animated: true, completion: nil)
                            print("failed to send video message")
                        }
                    }
                case .failure(let err):
                    print("video upload error: \(err)")
                }
            })
        } else {
            print("Passed from both cases")
        }
    }
}
extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
              let selfSender = selfSender,
              let messageID = createMessageID() else {
                  return
              }
        //Send message
        let message = Message(sender: selfSender,
                              messageId: messageID,
                              sentDate: Date(),
                              kind: .text(text))
        
        if isNewConversation {
            //create conver. in database
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, name: self.title ?? "User",  firstMessage: message) {[weak self] success in
                if success {
                    self?.isNewConversation = false
                    
                    let newConvID = "conversation_\(message.messageId)"
                    self?.id = newConvID
                    self?.listenToMessages(id: newConvID)
                    self?.messageInputBar.inputTextView.text = nil
                    print("message sent")
                } else {
                    print("message issue")
                }
            }
        } else {
            guard let conversationID = self.id, let name = self.title else {
                return
            }
            
            DatabaseManager.shared.sendMessage(to: conversationID, otherUserEmail: otherUserEmail, name: name, message: message) { isSent in
                if isSent {
                    self.messageInputBar.inputTextView.text = nil
                    print("message sent")
                } else {
                    print("message issue")
                }
            }
            
        }
    }
    private func createMessageID() -> String? {
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeCurrentUserEmail = DatabaseManager.safeEmail(emailAdress: currentUserEmail)
        let dateString = Self.dateFormatter.string(from: Date())
        let newIdent = "\(otherUserEmail)_\(safeCurrentUserEmail)_\(dateString)"
        return newIdent
    }
}
extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate,MessagesDisplayDelegate {
    func currentSender() -> SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("Fatal error when sending a message, Sender is nil")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        switch message.kind {
        case .photo(let media):
            guard let url = media.url else {
                return
            }
            imageView.sd_setImage(with: url, completed: nil)
        default:
            break
        }
    }
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        let sender = message.sender
        if sender.senderId == selfSender?.senderId {
            return .link
        }
        return .secondarySystemBackground
    }
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        let sender = message.sender
        if sender.senderId == selfSender?.senderId {
            if let currentUserURL = self.senderPhotoURL {
                avatarView.sd_setImage(with: currentUserURL, completed: nil)
            } else {
                guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
                    return
                }
                let safeEmail = DatabaseManager.safeEmail(emailAdress: email)
                let path = "image/\(safeEmail)_profile_image.png"
                StorageManager.shared.downloadURL(with: path) {[weak self] result in
                    switch result {
                    case .success(let url):
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url, completed: nil)
                        }
                        self?.senderPhotoURL = url
                    case .failure(let err):
                        print("Error on self avatar: \(err)")
                    }
                }
            }
        } else {
            if let otherUserURL = self.otherUserPhotoURL {
                avatarView.sd_setImage(with: otherUserURL, completed: nil)
            } else {
                let safeEmail = DatabaseManager.safeEmail(emailAdress: otherUserEmail)
                let path = "image/\(safeEmail)_profile_image.png"
                StorageManager.shared.downloadURL(with: path) {[weak self] result in
                    switch result {
                    case .success(let url):
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url, completed: nil)
                        }
                        self?.otherUserPhotoURL = url
                    case .failure(let err):
                        print("Error on other avatar: \(err)")
                    }
                }

            }

        }
    }
}
extension ChatViewController: MessageCellDelegate {
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let message = messages[indexPath.section]
        switch message.kind {
        case .location(let locationData):
            let coords = locationData.location.coordinate
            let vc = LocationPickerViewController(coordinates: coords)
            vc.title = "Location"
            navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let message = messages[indexPath.section]
        switch message.kind {
        case .photo(let media):
            guard let url = media.url else {
                return
            }
            let vc = PhotoViewerViewController(with: url)
            navigationController?.pushViewController(vc, animated: true)
        case .video(let media):
            guard let videoUrl = media.url else {
                return
            }
            let vc = AVPlayerViewController()
            vc.player = AVPlayer(url: videoUrl)
            present(vc, animated: true)
        default:
            break
        }
    }
}
