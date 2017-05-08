//
//  ListPickerViewController.swift
//  Just
//
//  Created by Krzysztof Kapitan on 08.04.2017.
//  Copyright © 2017 CappSoft. All rights reserved.
//

import UIKit

final class ListPickerViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    
    var lists: [List] = {
        return (1..<10).map {
            List(id: $0, name: "Test \($0)", tasks: [])
        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerNib(for: ListEntryCell.self)
        tableView.estimatedRowHeight = 53.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lists.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let list = lists[indexPath.row]
        
        let cell: ListEntryCell = tableView.dequeue()
        cell.title = list.name
            
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNonzeroMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .leastNonzeroMagnitude
    }
    
    @IBAction func addButtonAction() {
        let alert = UIAlertController(title: "New list", message: "Enter name", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.becomeFirstResponder()
        }
        
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            guard let name = alert.textFields?.first?.text else { return }
            
            let list = List(id: 0, name: name, tasks: [])
            
            self.lists.append(list)
            self.tableView.reloadData()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    @IBAction func cancelButtonAction(_ sender: Any) {
        dismiss(animated: true)
    }

}
