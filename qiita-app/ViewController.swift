//
//  ViewController.swift
//  
//  
//  Created by Seigetsu on 2023/11/13
//  
//

import UIKit

struct User: Decodable {
    let id: String
    let profileImageURL: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case profileImageURL = "profile_image_url"
    }
}

struct Article: Decodable {
    let id: String
    let title: String
    let user: User
}

class QiitaRepository {
    /// QiitaAPIから記事の一覧を取得する。
    ///
    /// - parameter count: 何件取得するか。
    /// - parameter title: タイトルの検索キーワード。
    func fetchArticles(count: Int, title: String = "") async throws -> [Article] {
        let url = URL(string: "https://qiita.com/api/v2/items?page=1&per_page=\(count)&query=title:\(title)")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        let (data, _) = try await URLSession.shared.data(for: urlRequest)
        return try JSONDecoder().decode([Article].self, from: data)
    }
}

class ViewController: UIViewController {
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(ArticleCell.self, forCellReuseIdentifier: "articleCell")
        return tableView
    }()
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "検索"
        searchBar.showsCancelButton = false
        return searchBar
    }()
    private var repository = QiitaRepository()
    private var articles: [Article]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setUpSearchBar()
        
        tableView.frame = view.bounds
        view.addSubview(tableView)
        tableView.rowHeight = 44
        
        searchBar.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        
        Task {
            await fetchAndDisplayData(title: "")
        }
    }
    
    func setUpSearchBar() {
        navigationItem.titleView = searchBar
    }
    
    /// - parameter title: 検索キーワード
    func fetchAndDisplayData(title: String) async {
        do {
            articles = try await repository.fetchArticles(count: 50, title: title)
            tableView.reloadData()
        } catch {
            print("[Error] 通信に失敗: \(error)")
            let alert = UIAlertController(title: "通信に失敗しました。", message: "再試行しますか？", preferredStyle: .alert)
            let cancel = UIAlertAction(title: "キャンセル", style: .cancel) { _ in
                self.dismiss(animated: true, completion: nil)
            }
            let ok = UIAlertAction(title: "OK", style: .default) { _ in
                self.dismiss(animated: true, completion: nil)
                Task {
                    await self.fetchAndDisplayData(title: title)
                }
            }
            alert.addAction(cancel)
            alert.addAction(ok)
            present(alert, animated: true, completion: nil)
        }
    }
}

extension ViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchBar.showsCancelButton = !searchText.isEmpty
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text else { return }
        Task {
            await fetchAndDisplayData(title: text)
        }
        searchBar.endEditing(true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.showsCancelButton = false
        Task {
            await fetchAndDisplayData(title: "")
        }
        searchBar.endEditing(true)
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        articles?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "articleCell", for: indexPath) as! ArticleCell
        guard let article = articles?[indexPath.row] else { return cell }
        cell.title = article.title
        cell.setProfileImageURL(article.user.profileImageURL)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let article = articles?[indexPath.row] else { return }
        let url = URL(string: "https://qiita.com/items/\(article.id)")!
        UIApplication.shared.open(url)
    }
}

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
