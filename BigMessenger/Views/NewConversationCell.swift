//
//  NewConversationCell.swift
//  BigMessenger
//
//  Created by user on 01.04.2022.
//

import Foundation
import SDWebImage

class NewConversationCell: UITableViewCell {
    static let identifier = "NewConversationCell"
    
    private let userImageView: UIImageView = {
        let imageV = UIImageView()
        imageV.contentMode = .scaleAspectFill
        imageV.layer.cornerRadius = 35
        imageV.layer.masksToBounds = true
        return imageV
    }()
    private let userNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 21, weight: .semibold)
        return label
    }()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(userImageView)
        contentView.addSubview(userNameLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        userImageView.frame = CGRect(x: 10,
                                     y: 10,
                                     width: 70,
                                     height: 70)
        userNameLabel.frame = CGRect(x: userImageView.right+10,
                                     y: 20,
                                     width: contentView.width - 20 - userImageView.width,
                                     height: 50)
    }
    public func configure(with model: SearchedUser){
        userNameLabel.text = model.name
        let path = "image/\(model.email)_profile_image.png"
        StorageManager.shared.downloadURL(with: path) { [weak self] result in
            switch result {
            case .success(let url):
                DispatchQueue.main.async {
                    self?.userImageView.sd_setImage(with: url, completed: nil)
                }
            case .failure(let err):
                print("failed to download: \(err)")
            }
        }
    }
}
