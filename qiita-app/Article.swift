//
//  Article.swift
//  qiita-app
//  
//  Created by Seigetsu on 2023/12/17
//  
//

import Foundation

struct Article: Decodable {
    let id: String
    let title: String
    let user: User
}
