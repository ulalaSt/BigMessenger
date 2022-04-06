//
//  StorageManager.swift
//  BigMessenger
//
//  Created by user on 24.03.2022.
//

import Foundation
import FirebaseStorage

final class StorageManager {
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    public typealias UploadPictureCompletion = (Result<String,Error>)->Void
    
    public func uploadPictures(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion){
        storage.child("image/\(fileName)").putData(data, metadata: nil) { [weak self] metaData, error in
            guard let strongRef = self else {
                return
            }
            guard error == nil else {
                print("failed to upload pictures")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            strongRef.storage.child("image/\(fileName)").downloadURL { url, error in
                guard let url = url else {
                    print("Failed to download the Picture URL")
                    completion(.failure(StorageErrors.failedToUploadURL))
                    return
                }
                let urlString = url.absoluteString
                print("Successed downloading picture with URL: \(urlString)")
                completion(.success(urlString))
            }
        }
    }
    public func uploadMessagePictures(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion){
        storage.child("message_images/\(fileName)").putData(data, metadata: nil) {[weak self] metaData, error in
            guard error == nil else {
                print("failed to upload pictures")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            self?.storage.child("message_images/\(fileName)").downloadURL { url, error in
                guard let url = url else {
                    print("Failed to download the Picture URL")
                    completion(.failure(StorageErrors.failedToUploadURL))
                    return
                }
                let urlString = url.absoluteString
                print("Successed downloading picture with URL: \(urlString)")
                completion(.success(urlString))
            }
        }
    }
    public func uploadMessageVideos(with url: URL, fileName: String, completion: @escaping UploadPictureCompletion){
        print(url.absoluteString)
        let metaData = StorageMetadata()
        metaData.contentType = "video/quicktime"
        if let videoData = NSData(contentsOf: url) as Data? {
            storage.child("message_videos/\(fileName)").putData(videoData, metadata: nil, completion: { [weak self] metaData, err in
                guard err == nil else {
                    print("failed to upload video with error: \(err)")
                    completion(.failure(StorageErrors.failedToUpload))
                    return
                }
                self?.storage.child("message_videos/\(fileName)").downloadURL { url, error in
                    guard let url = url else {
                        print("Failed to download the Picture URL")
                        completion(.failure(StorageErrors.failedToUploadURL))
                        return
                    }
                    let urlString = url.absoluteString
                    print("Successed downloading picture with URL: \(urlString)")
                    completion(.success(urlString))
                }
            })

        }
    }

    public func downloadURL(with path: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let reference = storage.child(path)
        reference.downloadURL { url, error in
            guard let url = url, error == nil else {
                completion(.failure(StorageErrors.failedToUploadURL))
                return
            }
            completion(.success(url))
        }
    }
}
public enum StorageErrors: Error {
    case failedToUpload
    case failedToUploadURL
}
