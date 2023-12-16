//
//  ViewController.swift
//  
//  
//  Created by Seigetsu on 2023/11/13
//  
//

import UIKit

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
