//
//  Repository.swift
//  MVCDemo
//
//  Created by Vasiliy Korchagin on 01.04.2021.
//

import Foundation

class Repository {
    static let changedNotification = Notification.Name("RepositoryChanged")
    static let shared = Repository(url: libraryDirectory)
    
    static private let libraryDirectory = try! FileManager.default.url(for: .libraryDirectory,
                                                                       in: .userDomainMask,
                                                                       appropriateFor: nil,
                                                                       create: true)
    static private let localFileName = "repository.json"
    
    let baseURL: URL?
    var placeholder: URL?
    private(set) var rootFolder: Folder
    
    // MARK: - Lifecycle
    
    init(url: URL?) {
        self.baseURL = url
        self.placeholder = nil
        
        if let url = url,
            let data = try? Data(contentsOf: url.appendingPathComponent(Repository.localFileName)),
            let folder = try? JSONDecoder().decode(Folder.self, from: data) {
            self.rootFolder = folder
        } else {
            self.rootFolder = Folder(name: "", uuid: UUID())
        }
        
        self.rootFolder.repository = self
    }
    
    // MARK: - Public
    
    func save(_ item: Item, userInfo: [AnyHashable: Any]) {
        if let url = baseURL,
           let data = try? JSONEncoder().encode(rootFolder) {
            try! data.write(to: url.appendingPathComponent(Repository.localFileName))
        }
        NotificationCenter.default.post(name: Repository.changedNotification,
                                        object: item,
                                        userInfo: userInfo)
    }
    
    func item(atUUIDPath path: [UUID]) -> Item? {
        
        return rootFolder.item(atUUIDPath: path[0...])
    }
}
