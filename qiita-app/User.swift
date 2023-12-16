//
//  User.swift
//  qiita-app
//  
//  Created by Seigetsu on 2023/12/17
//  
//

import Foundation

struct User: Decodable {
    let id: String
    let profileImageURL: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case profileImageURL = "profile_image_url"
    }
}
