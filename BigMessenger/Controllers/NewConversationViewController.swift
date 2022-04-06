//
//  NewConversationViewController.swift
//  BigMessenger
//
//  Created by user on 21.03.2022.
//

import UIKit
import JGProgressHUD
final class NewConversationViewController: UIViewController {
    private let spinner = JGProgressHUD(style: .dark)
    public var completion: ((SearchedUser)->Void)?
    private var users = [[String: String]]()
    private var results = [SearchedUser]()
    private var hasFetched = false
    
    private let searchBar: UISearchBar = {
        let search = UISearchBar()
        search.placeholder = "Search for users..."
        return search
    }()
    private var tableView: UITableView = {
        let table = UITableView()
        table.isHidden = true
        table.register(NewConversationCell.self, forCellReuseIdentifier: NewConversationCell.identifier)
        return table
    }()
    private var noUsersLabel: UILabel = {
        let label = UILabel()
        label.text = "No Users Found"
        label.textAlignment = .center
        label.textColor = .green
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.isHidden = true
        return label
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(noUsersLabel)
        view.addSubview(tableView)
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done , target: self, action: #selector(didCancelled))
        searchBar.becomeFirstResponder()
        
    }
    override func viewDidLayoutSubviews() {
        tableView.frame = view.bounds
        noUsersLabel.frame = CGRect(x: view.width/4, y: (view.height-200)/2, width: view.width/2, height: 200)
    }
    @objc private func didCancelled(){
        dismiss(animated: true, completion: nil)
    }
    
}
extension NewConversationViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = results[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: NewConversationCell.identifier, for: indexPath) as! NewConversationCell
        cell.configure(with: model)
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        //start conversation
        let targetData = results[indexPath.row]
        
        dismiss(animated: true) {[weak self] in
            self?.completion?(targetData)
        }
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
}
extension NewConversationViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        results.removeAll()
        searchBar.resignFirstResponder()
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        spinner.show(in: view)
        
        searchUsers(query: text)
    }
    func searchUsers(query: String) {
        // check if results have firebase data
        if hasFetched {
            filterUsers(with: query)
        } else {
            DatabaseManager.shared.fetchAllUsers {[weak self] result in
                switch result {
                case .failure(let err):
                    print("Error with Fetching all: \(err)")
                case .success(let result):
                    self?.hasFetched = true
                    self?.users = result
                    self?.filterUsers(with: query)
                }
            }
        }
    }
    func filterUsers(with term: String){
        //update the UI: tableView or label
        guard hasFetched else {
            return
        }
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAdress: currentEmail)
        self.spinner.dismiss(animated: true)
        let results: [SearchedUser] = users.filter({
            guard let email = $0["email"], email != safeEmail else {
                return false
            }
            guard let name = $0["name"]?.lowercased() else {
                return false
            }
            return name.hasPrefix(term.lowercased())
        }).compactMap({
            guard let email = $0["email"], let name = $0["name"]?.lowercased() else {
                return nil
            }
            return SearchedUser(name: name, email: email)
        })
        print(results)
        self.results = results
        updateUI()
    }
    func updateUI(){
        if results.isEmpty {
            noUsersLabel.isHidden = false
            tableView.isHidden = true
        } else {
            noUsersLabel.isHidden = true
            tableView.isHidden = false
            tableView.reloadData()
        }
    }
}
