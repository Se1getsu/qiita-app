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

struct QiitaRepository {
    func fetchArticles(count: Int) async throws -> [Article] {
        let url = URL(string: "https://qiita.com/api/v2/items?page=1&per_page=\(count)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Article].self, from: data)
    }
}

class ViewController: UIViewController {
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tableView
    }()
    private let repository = QiitaRepository()
    private var articles: [Article]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        tableView.frame = view.bounds
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        
        Task {
            do {
                articles = try await repository.fetchArticles(count: 20)
                tableView.reloadData()
            } catch {
                print("ERROR: \(error)")
            }
        }
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        articles?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        guard let article = articles?[indexPath.row] else { return cell }
        var config = cell.defaultContentConfiguration()
        config.text = article.title
        config.secondaryText = "by @\(article.user.id)"
        cell.contentConfiguration = config
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let article = articles?[indexPath.row] else { return }
        let url = URL(string: "https://qiita.com/Se1getsu/items/\(article.id)")!
        UIApplication.shared.open(url)
    }
}
