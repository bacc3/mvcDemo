//
//  File.swift
//  MVCDemo
//
//  Created by Vasiliy Korchagin on 26.05.2021.
//

import Foundation

class File: Item, Codable {
    private enum CondingKeys: CodingKey {
        case name
        case uuid
    }
    
    // MARK: - Lifecycle
    
    override init(name: String, uuid: UUID) {
        super.init(name: name, uuid: uuid)
    }
    
    // MARK: - Codable
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CondingKeys.self)
        let uuid = try container.decode(UUID.self, forKey: .uuid)
        let name = try container.decode(String.self, forKey: .name)
        super.init(name: name, uuid: uuid)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CondingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(uuid, forKey: .uuid)
    }
}
