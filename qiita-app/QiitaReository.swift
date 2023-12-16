//
//  QiitaReository.swift
//  qiita-app
//  
//  Created by Seigetsu on 2023/12/17
//  
//

import Foundation

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
