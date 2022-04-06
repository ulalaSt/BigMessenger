//
//  AppDelegate.swift
//  BigMessenger
//
//  Created by user on 20.03.2022.
//

import UIKit
import Firebase
import FBSDKCoreKit
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()
        
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        return true
    }
    
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        
        ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
        return GIDSignIn.sharedInstance().handle(url)
    }
}

extension AppDelegate: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        guard error == nil else {
            if let error = error {
                print("Failed to sing in to Google: \(error)")
            }
            return
        }
        guard let email = user.profile.email, let first = user.profile.givenName, let last = user.profile.familyName else {
            print("Issue with the users data from Google")
            return
        }
        
        UserDefaults.standard.set(email, forKey: "email")
        UserDefaults.standard.set("\(first) \(last)", forKey: "name")

        DatabaseManager.shared.userExists(with: email) { exists in
            if !exists {
                let chatUser = ChatAppUser(firstName: first,
                                           lastName: last,
                                           emailAdress: email)
                DatabaseManager.shared.insertUser(with: chatUser) { success in
                    if success {
                        //upload image
                        if user.profile.hasImage {
                            guard let url = user.profile.imageURL(withDimension: 200) else {
                                return
                            }
                            URLSession.shared.dataTask(with: url) { data, _, _ in
                                guard let data = data else {
                                    return
                                }
                                let fileName = chatUser.pictureFileName
                                StorageManager.shared.uploadPictures(with: data, fileName: fileName, completion: {result in
                                    switch result {
                                    case .success(let url):
                                        UserDefaults.standard.set(url, forKey: "profile_picture_url")
                                        print(url)
                                    case .failure(let error):
                                        print(error)
                                    }
                                })
                                
                            }.resume()
                        }
                    }
                }
            }
        }
        guard let authentication = user.authentication else {
            print("Missing auth object off of google user")
            return
        }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
        FirebaseAuth.Auth.auth().signIn(with: credential) { result, error in
            guard result != nil, error == nil else {
                print("Failed to log in with google credential")
                return
            }
            print("Succeeded to log in with google credential")
            NotificationCenter.default.post(name: .didLogin, object: nil)
        }
    }
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        print("Google user disconnected")
    }

}
