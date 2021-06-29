//
//  ViewController.swift
//  MVCDemo
//
//  Created by Vasiliy Korchagin on 01.04.2021.
//

import UIKit

class ViewController: UITableViewController {
    var folder: Folder = Repository.shared.rootFolder {
        didSet {
            tableView.reloadData()
            updateTitle()
        }
    }
    var selectedItem: Item? {
        if let indexPath = tableView.indexPathForSelectedRow {
            return folder.contents[indexPath.row]
        }
        
        return nil
    }
    
    private static let folderCellIdentifier = "FolderCell"
    private static let fileCellIdentifier = "FileCell"
    
    init(folder: Folder? = nil) {
        super.init(nibName: nil, bundle: nil)
        
        if let folder = folder {
            self.folder = folder
        }
        updateTitle()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftItemsSupplementBackButton = true
        navigationItem.leftBarButtonItem = editButtonItem
        let addButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                            target: self,
                                            action: #selector(addTapped))
        navigationItem.rightBarButtonItem = addButtonItem
        
        tableView.register(
            UITableViewCell.self,
            forCellReuseIdentifier: ViewController.folderCellIdentifier)
        tableView.register(
            UITableViewCell.self,
            forCellReuseIdentifier: ViewController.fileCellIdentifier)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleChangeNotification(_:)),
            name: Repository.changedNotification, object: nil)
    }
    
    @objc func handleChangeNotification(_ notification: Notification) {
        // Handle changes to the current folder
        if let item = notification.object as? Folder,
           item === folder {
            guard
                let reason = notification.userInfo?[Item.UserInfoKeys.changeReason] as? String
            else {
                
                return
            }
            if Item.ChangeReason(rawValue: reason) == Item.ChangeReason.removed,
               let nc = navigationController {
                nc.setViewControllers(nc.viewControllers.filter { $0 !== self }, animated: false)
            } else {
                folder = item
            }
        }
        
        // Handle changes to children of the current folder
        guard
            let userInfo = notification.userInfo,
            userInfo[Item.UserInfoKeys.parentFolder] as? Folder === folder
        else {
            
            return
        }
        
        // Handle changes to contents
        if let reason = userInfo[Item.UserInfoKeys.changeReason] as? String {
            let currentValue = userInfo[Item.UserInfoKeys.currentValue]
            let prevValue = userInfo[Item.UserInfoKeys.prevValue]
            
            switch (reason, currentValue, prevValue) {
            case let (Item.ChangeReason.removed.rawValue, _, (prevIndex as Int)?):
                tableView.deleteRows(at: [IndexPath(row: prevIndex, section: 0)], with: .right)
            case let (Item.ChangeReason.added.rawValue, (currentIndex as Int)?, _):
                tableView.insertRows(at: [IndexPath(row: currentIndex, section: 0)], with: .left)
            case let (Item.ChangeReason.renamed.rawValue, (currentIndex as Int)?, (prevIndex as Int)?):
                tableView.moveRow(
                    at: IndexPath(row: prevIndex, section: 0),
                    to: IndexPath(row: currentIndex, section: 0))
                tableView.reloadRows(at: [IndexPath(row: currentIndex, section: 0)], with: .fade)
            default:
                tableView.reloadData()
            }
        } else {
            tableView.reloadData()
        }
    }
    
    @objc func addTapped() {
        presentCreateItemAlertController()
    }
    
    private func updateTitle() {
        if folder === folder.repository?.rootFolder {
            title = "MVC Demo"
        } else {
            title = folder.name
        }
    }
    
    // MARK: - Table View
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return folder.contents.count
    }
    
    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let item = folder.contents[indexPath.row]
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ViewController.folderCellIdentifier,
            for: indexPath)
        let prefix = item is File ? "🔊" : "📁"
        cell.textLabel!.text = "\(prefix) \(item.name)"
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        return true
    }
    
    override func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        folder.remove(folder.contents[indexPath.row])
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let selectedFolder = selectedItem as? Folder else {
            tableView.deselectRow(at: indexPath, animated: true)
            
            return
        }
        let viewController = ViewController(folder: selectedFolder)
        navigationController?.pushViewController(viewController, animated: true)
    }
}

extension ViewController {
    func presentCreateItemAlertController() {
        let alert = UIAlertController(title: "Create Item", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Create File", style: .default) { [weak self] _ in
            self?.presetCreateFileAlertController()
        })
        alert.addAction(UIAlertAction(title: "Create Folder", style: .default) { [weak self] _ in
            self?.presetCreateFolderAlertController()
        })
        present(alert, animated: true)
    }
    
    private func presetCreateFileAlertController() {
        presentAlertController(
            title: "Create file",
            accept: "Create",
            placeholder: "File name"
        ) { fileName in
            if let name = fileName {
                let file = File(name: name, uuid: UUID())
                self.folder.add(file)
            }
            self.dismiss(animated: true)
        }
    }
    
    private func presetCreateFolderAlertController() {
        presentAlertController(
            title: "Create folder",
            accept: "Create",
            placeholder: "Folder name"
        ) { folderName in
            if let name = folderName {
                let folder = Folder(name: name, uuid: UUID())
                self.folder.add(folder)
            }
            self.dismiss(animated: true)
        }
    }
    
    func presentAlertController(title: String,
                                accept: String = "Ok",
                                cancel: String = "Cancel",
                                placeholder: String,
                                callback: @escaping (String?) -> ()) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = placeholder }
        alert.addAction(UIAlertAction(title: cancel, style: .cancel) { _ in
            callback(nil)
        })
        alert.addAction(UIAlertAction(title: accept, style: .default) { _ in
            callback(alert.textFields?.first?.text)
        })
        present(alert, animated: true)
    }
}

