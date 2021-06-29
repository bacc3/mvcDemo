//
//  Folder.swift
//  MVCDemo
//
//  Created by Vasiliy Korchagin on 01.04.2021.
//

import Foundation

class Folder: Item, Codable {
    override weak var repository: Repository? {
        didSet {
            contents.forEach {
                $0.repository = repository
            }
        }
    }

    private enum CodingKeys: CodingKey {
        case name
        case uuid
        case contents
        case folder
        case file
    }
    
    private(set) var contents: [Item]
    
    // MARK: - Lifecycle
    
    override init(name: String, uuid: UUID) {
        contents = []
        super.init(name: name, uuid: uuid)
    }
    
    // MARK: - Codable
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        contents = [Item]()
        var nestedContainer = try container.nestedUnkeyedContainer(forKey: .contents)
        while true {
            let wrapper = try nestedContainer.nestedContainer(keyedBy: CodingKeys.self)
            if let folder = try wrapper.decodeIfPresent(Folder.self, forKey: .folder) {
                contents.append(folder)
            } else if let file = try wrapper.decodeIfPresent(File.self, forKey: .file) {
                contents.append(file)
            } else {
                break
            }
        }

        let uuid = try container.decode(UUID.self, forKey: .uuid)
        let name = try container.decode(String.self, forKey: .name)
        super.init(name: name, uuid: uuid)
        
        contents.forEach { content in
            content.parentFolder = self
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(uuid, forKey: .uuid)
        var nestedContainer = container.nestedUnkeyedContainer(forKey: .contents)
        for content in contents {
            var wrapper = nestedContainer.nestedContainer(keyedBy: CodingKeys.self)
            switch content {
            case let folder as Folder:
                try wrapper.encode(folder, forKey: .folder)
                
            case let file as File:
                try wrapper.encode(file, forKey: .file)
                
            default:
                break
            }
        }
        _ = nestedContainer.nestedContainer(keyedBy: CodingKeys.self)
    }
    
    // MARK: - Public
    
    func add(_ item: Item) {
        assert(contents.contains { $0 === item } == false)
        contents.append(item)
        contents.sort(by: { $0.name < $1.name })
        let index = contents.firstIndex { $0 === item }!
        item.parentFolder = self
        repository?.save(item, userInfo: [Item.UserInfoKeys.changeReason: Item.ChangeReason.added,
                                          Item.UserInfoKeys.currentValue: index,
                                          Item.UserInfoKeys.parentFolder: self])
    }
    
    func remove(_ item: Item) {
        guard let index = contents.firstIndex(where: { $0 === item }) else {
            
            return
        }
        item.handleDeleting()
        contents.remove(at: index)
        repository?.save(item, userInfo: [Item.UserInfoKeys.changeReason: Item.ChangeReason.removed,
                                          Item.UserInfoKeys.prevValue: index,
                                          Item.UserInfoKeys.parentFolder: self])
    }
    
    func reSort(changedItem: Item) -> (prevIndex: Int, currentIndex: Int) {
        let prevIndex = contents.firstIndex {
            $0 === changedItem
        }!
        contents.sort(by: {
            $0.name < $1.name
        })
        let currentIndex = contents.firstIndex {
            $0 === changedItem
        }!
        
        return (prevIndex, currentIndex)
    }
}
