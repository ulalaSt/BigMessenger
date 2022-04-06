//
//  ProfileViewController.swift
//  BigMessenger
//
//  Created by user on 21.03.2022.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import SDWebImage

final class ProfileViewController: UIViewController {
    @IBOutlet var tableView: UITableView!
    var data = [ProfileViewModel]()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        data.append(ProfileViewModel(viewModelType: .info,
                                     title: "Name: \(UserDefaults.standard.value(forKey: "name") as? String ?? "No Name")",
                                     handler: nil))
        data.append(ProfileViewModel(viewModelType: .info,
                                     title: "Email: \(UserDefaults.standard.value(forKey: "email") as? String ?? "No Email")",
                                     handler: nil))
        data.append(ProfileViewModel(viewModelType: .logout,
                                     title: "Log Out",
                                     handler: {[weak self] in
            guard let strongRef = self else {
                return
            }
            UserDefaults.standard.setValue(nil, forKey: "name")
            UserDefaults.standard.setValue(nil, forKey: "email")

            let alert = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: {[weak self] _ in
                guard let strongRef = self else {
                    return
                }
                
                //log out fb
                FBSDKLoginKit.LoginManager().logOut()
                //log out gid
                GIDSignIn.sharedInstance().signOut()
                
                do {
                    try FirebaseAuth.Auth.auth().signOut()
                    let vc = LoginViewController()
                    let nav = UINavigationController(rootViewController: vc)
                    nav.modalPresentationStyle = .fullScreen
                    strongRef.present(nav,animated: true)
                } catch {
                    print("Failed to Log Out")
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            strongRef.present(alert,animated: true)

        }))

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: ProfileTableViewCell.identifier)
        tableView.tableHeaderView = createTableView()
        // Do any additional setup after loading the view.
    }
    private func createTableView() -> UIView? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeEmail = DatabaseManager.safeEmail(emailAdress: email)
        let fileName = "\(safeEmail)_profile_image.png"
        let path = "image/"+fileName
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.width, height: 300))
        headerView.backgroundColor = .link
        let imageV = UIImageView(frame: CGRect(x: (headerView.width-(headerView.height/2))/2,
                                               y: headerView.height/4,
                                               width: headerView.height/2,
                                               height: headerView.height/2))
        imageV.contentMode = .scaleAspectFill
        imageV.backgroundColor = .white
        imageV.layer.cornerRadius = imageV.width/2
        imageV.layer.borderColor = UIColor.white.cgColor
        imageV.layer.borderWidth = 3
        imageV.layer.masksToBounds = true
        
        print("This is path: \(path)")
        StorageManager.shared.downloadURL(with: path) {[weak self] result in
            switch result {
            case .success(let url):
                print(".success have passed")
                self?.downloadImage(imageView: imageV, url: url)
            case .failure(let error):
                print("Error to download URL: \(error)")
            }
        }
        
        headerView.addSubview(imageV)
        return headerView
    }
    func downloadImage(imageView: UIImageView, url: URL) {
        imageView.sd_setImage(with: url, completed: nil)
//        URLSession.shared.dataTask(with: url) { data, _, error in
//            guard let data = data, error == nil else {
//                return
//            }
//            print("You are setting the photo...")
//
//            DispatchQueue.main.async {
//                let image = UIImage(data: data)
//                imageView.image = image
//                print("You successfully set the photo")
//            }
//        }.resume()
    }
}
extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileTableViewCell.identifier, for: indexPath) as! ProfileTableViewCell
        cell.setUp(with: data[indexPath.row])
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        data[indexPath.row].handler?()
    }
}

class ProfileTableViewCell: UITableViewCell {
    static let identifier = "ProfileTableViewCell"

    public func setUp(with viewModel: ProfileViewModel){
        self.textLabel?.text = viewModel.title

        switch viewModel.viewModelType {
        case .info:
            textLabel?.textAlignment = .left
            selectionStyle = .none
        case .logout:
            textLabel?.textColor = .red
            textLabel?.textAlignment = .center
        }
    }
}
