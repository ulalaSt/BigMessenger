//
//  LoginViewController.swift
//  BigMessenger
//
//  Created by user on 21.03.2022.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import JGProgressHUD

final class LoginViewController: UIViewController {
    
    //All Log In Views
    private let spinner = JGProgressHUD(style: .dark)
    private var scrollView: UIScrollView = {
        let scrollview = UIScrollView()
        scrollview.clipsToBounds = true
        return scrollview
    }()
    private var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "logo")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    private let emailField: UITextField = {
        let field = UITextField()
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.returnKeyType = .default
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Email Address..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    private let passwordField: UITextField = {
        let field = UITextField()
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        field.isSecureTextEntry = true
        return field
    }()
    private let orLabel: UILabel = {
        let label = UILabel()
        label.text = "or"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        label.textColor = .systemGray
        return label
    }()
    private let FBloginButton: FBLoginButton = {
        let button = FBLoginButton()
        button.layer.cornerRadius = 12
        button.clipsToBounds = true
        button.permissions = ["email","public_profile"]
        let buttonText = NSAttributedString(string: "Continue with Facebook",attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20, weight: .bold)])
        button.setAttributedTitle(buttonText, for: .normal)
        return button
    }()
    private let GIDloginButton: UIView = {
        let viewButton = UIView()
        viewButton.layer.borderColor = UIColor.lightGray.cgColor
        viewButton.layer.borderWidth = 2
        viewButton.layer.cornerRadius = 12
        viewButton.layer.masksToBounds = true
        return viewButton
    }()
    private let GIDImage: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "google_logo.png")
        return imageView
    }()
    private let GIDlabel: UILabel = {
        let label = UILabel()
        label.text = "Continue with Google"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        label.textColor = .systemGray
        return label
    }()
    @objc private func GIDloginButtonPressed(){
        GIDSignIn.sharedInstance().signIn()
    }
    func drawLine(from start: CGPoint, to end: CGPoint) {
        let aPath = UIBezierPath()
        aPath.move(to: start)
        aPath.addLine(to: end)
        let layer = CAShapeLayer()
        layer.strokeColor = UIColor.systemGray.cgColor
        layer.lineWidth = 2.0
        layer.position = CGPoint(x: 0, y: 0)
        layer.path = aPath.cgPath
        self.scrollView.layer.addSublayer(layer)
    }
    //
    var loginObserver: NSObjectProtocol?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogin,
                                                               object: nil,
                                                               queue: .main) { [weak self] _ in
            guard let strongRef = self else {
                return
            }
            strongRef.navigationController?.dismiss(animated: true, completion: nil)
        }
        GIDSignIn.sharedInstance().presentingViewController = self
        title = "Log In"
        view.backgroundColor = .systemBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .done, target: self, action: #selector(didTapRegister))
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        emailField.delegate = self
        passwordField.delegate = self
        FBloginButton.delegate = self
        
        GIDloginButton.addSubview(GIDImage)
        GIDloginButton.addSubview(GIDlabel)
        GIDloginButton.isUserInteractionEnabled = true
        let gesture = UITapGestureRecognizer(target: self, action: #selector(GIDloginButtonPressed))
        gesture.numberOfTouchesRequired = 1
        GIDloginButton.addGestureRecognizer(gesture)
        
        //Add Subview
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(orLabel)
        scrollView.addSubview(FBloginButton)
        scrollView.addSubview(GIDloginButton)
    }
    
    deinit {
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let size = scrollView.width/3
        
        imageView.frame = CGRect(x: (scrollView.width-size)/2,
                                 y: 60,
                                 width: size,
                                 height: size)
        emailField.frame = CGRect(x: 30,
                                  y: imageView.bottom+75,
                                  width: scrollView.width-60,
                                  height: 52)
        passwordField.frame = CGRect(x: 30,
                                     y: emailField.bottom+10,
                                     width: scrollView.width-60,
                                     height: 52)
        loginButton.frame = CGRect(x: 30,
                                   y: passwordField.bottom+10,
                                   width: scrollView.width-60,
                                   height: 52)
        orLabel.frame = CGRect(x: 150,
                               y: loginButton.bottom+10,
                               width: scrollView.width-300,
                               height: 75)
        drawLine(from: CGPoint(x: 30, y: orLabel.frame.midY), to: CGPoint(x: orLabel.left, y: orLabel.frame.midY))
        drawLine(from: CGPoint(x: orLabel.right, y: orLabel.frame.midY), to: CGPoint(x: scrollView.right-30, y: orLabel.frame.midY))
        FBloginButton.frame = CGRect(x: 30,
                                     y: orLabel.bottom+10,
                                     width: scrollView.width-60,
                                     height: 52)
        GIDloginButton.frame = CGRect(x: 30,
                                      y: FBloginButton.bottom+10,
                                      width: scrollView.width-60,
                                      height: 52)
        GIDlabel.frame = CGRect(x: 0,
                                y: 0,
                                width: GIDloginButton.width,
                                height: GIDloginButton.height)
        GIDImage.frame = CGRect(x: 2,
                                y: 10,
                                width: GIDloginButton.height-20,
                                height: GIDloginButton.height-20)
        
    }
    
    @objc private func loginTapped(){
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let email = emailField.text, let password = passwordField.text, !email.isEmpty, !password.isEmpty, password.count >= 6 else {
            alertUserLoginError()
            return
        }
        
        spinner.show(in: view)
        
        //Firebase Login
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let strongRef = self else {
                return
            }
            DispatchQueue.main.async {
                strongRef.spinner.dismiss(animated: true)
            }
            guard let result = result, error == nil else {
                print("Failed in to log in with email: \(email)")
                return
            }
            let safeEmail = DatabaseManager.safeEmail(emailAdress: email)
            DatabaseManager.shared.getDataFor(path: safeEmail) { result in
                switch result {
                case .success(let data):
                    guard let userData = data as? [String: Any],
                          let first = userData["first_name"] as? String,
                          let last = userData["last_name"] as? String
                    else {
                        return
                    }
                    UserDefaults.standard.set("\(first) \(last)", forKey: "name")
                case .failure(let error):
                    print("Error on getting data for path: \(error)")
                }
            }
            UserDefaults.standard.set(email, forKey: "email")
            let user = result.user
            print("Logged in: \(user)")
            strongRef.navigationController?.dismiss(animated: false, completion: nil)
        }
    }
    
    func alertUserLoginError(){
        let alert = UIAlertController(title: "Woops", message: "Please enter all information to Log in", preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    @objc func didTapRegister(){
        let vc = RegisterViewController()
        vc.title = "Register"
        navigationController?.pushViewController(vc, animated: true)
    }
    
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            loginTapped()
        }
        return true
    }
}
extension LoginViewController: LoginButtonDelegate {
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        guard let token = result?.token?.tokenString else {
            print("User failed to log in with Facebook")
            return
        }
        let request = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                 parameters: ["fields" : "email, first_name, last_name, picture.type(large)"],
                                                 tokenString: token,
                                                 version: nil,
                                                 httpMethod: .get)
        
        request.start { _, result , error  in
            guard let result = result as? [String: Any], error == nil else {
                print("Failed on Facebook Graph request")
                return
            }
            print(result)
            guard let first = result["first_name"] as? String,
                  let last = result["last_name"] as? String,
                  let email = result["email"] as? String,
                  let picture = result["picture"] as? [String: Any],
                  let data = picture["data"] as? [String: Any],
                  let pictureUrl = data["url"] as? String else {
                      print("Can not get Email and Name from Facebook")
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
                            guard let url = URL(string: pictureUrl) else {
                                return
                            }
                            URLSession.shared.dataTask(with: url) { urlData, _, _ in
                                guard let urlData = urlData else {
                                    print("Failed to get Data From Facebook profile image URL")
                                    return
                                }
                                let fileName = chatUser.pictureFileName
                                StorageManager.shared.uploadPictures(with: urlData, fileName: fileName, completion: {result in
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
            
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            
            FirebaseAuth.Auth.auth().signIn(with: credential) { [weak self] result, error in
                guard let strongRef = self else {
                    return
                }
                guard result != nil, error == nil else {
                    print("Facebook login failed")
                    return
                }
                print("Facebook login succeeded")
                strongRef.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
        
        
    }
    
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        //no operation
    }
}
