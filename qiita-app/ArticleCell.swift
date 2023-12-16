//
//  ArticleCell.swift
//  qiita-app
//  
//  Created by Seigetsu on 2023/12/17
//  
//

import UIKit

class ArticleCell: UITableViewCell {
    private var titleLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    private var profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    var image: UIImage? {
        didSet {
            profileImageView.image = image
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpViews() {
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(profileImageView)
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 36),
            profileImageView.heightAnchor.constraint(equalToConstant: 36),
            titleLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 6),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    func setProfileImageURL(_ urlString: String) {
        Task {
            do {
                let url = URL(string: urlString)!
                let (data, _) = try await URLSession.shared.data(from: url)
                let image = UIImage(data: data) ?? UIImage()
                await MainActor.run {
                    profileImageView.image = image
                }
            } catch {
                print("Failed to load image \(urlString): \(error)")
            }
        }
    }
}
