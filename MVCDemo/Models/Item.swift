//
//  Item.swift
//  MVCDemo
//
//  Created by Vasiliy Korchagin on 01.04.2021.
//

import Foundation

class Item {
    static let uuidPathKey = "uuidPath"
    
    enum UserInfoKeys: String {
        case changeReason
        case currentValue
        case prevValue
        case parentFolder
    }
    
    enum ChangeReason: String {
        case renamed
        case added
        case removed
    }
    
    let uuid: UUID
    weak var repository: Repository?
    weak var parentFolder: Folder? {
        didSet {
            repository = parentFolder?.repository
        }
    }
    var uuidPath: [UUID] {
        var path = parentFolder?.uuidPath ?? []
        path.append(uuid)
        
        return path
    }
    
    private(set) var name: String
    
    // MARK: - Lifecycle
    
    init(name: String, uuid: UUID) {
        self.name = name
        self.uuid = uuid
        self.repository = nil
    }
    
    // MARK: - Public
    
    func setName(_ newName: String) {
        name = newName
        guard let parentFolder = parentFolder else {
            
            return
        }
        let updatedIndexes = parentFolder.reSort(changedItem: self)
        repository?.save(self,
                         userInfo: renameReasonUserInfo(parentFolder: parentFolder,
                                                        indexes: updatedIndexes))
    }
    
    func item(atUUIDPath path: ArraySlice<UUID>) -> Item? {
        guard let first = path.first, first == uuid else { return nil }
        
        return self
    }
    
    func handleDeleting() {
        parentFolder = nil
    }
    
    // MARK: - Private
    
    private func renameReasonUserInfo(
        parentFolder: Folder,
        indexes: (prevIndex: Int, currentIndex: Int)
    ) -> [AnyHashable: Any] {
        
        return [UserInfoKeys.changeReason: ChangeReason.renamed,
                UserInfoKeys.prevValue: indexes.prevIndex,
                UserInfoKeys.currentValue: indexes.currentIndex,
                UserInfoKeys.parentFolder: parentFolder]
    }
}

