//
//  LogFileListViewController.swift
//  DeepLinkDemo
//
//  Created by Apple on 26/05/22.
//

import UIKit

class LogFileListViewController: UIViewController {
    
    var fileNames = [String]()
    
    @IBOutlet weak var logFileListTblView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fileNames = getAllLogFileNames()
    }
    
    func getAllLogFileNames() -> [String]{
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        do {
            var fileName = [String]()
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsUrl,
                                                                       includingPropertiesForKeys: nil,
                                                                       options: .skipsHiddenFiles)
            for fileURL in fileURLs {
                fileName.append(fileURL.lastPathComponent)
            }
            
            return fileName
        } catch  {
            NSLog("Failed to delete/read the file in document directory %@", error.localizedDescription)
        }
        return [""]
    }
    @IBAction func backAction(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    
}


extension LogFileListViewController: UITableViewDataSource, UITableViewDelegate{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fileNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "LogTableViewCell", for: indexPath) as? LogTableViewCell{
            cell.nameLbl.text = fileNames[indexPath.row]
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedFile = fileNames[indexPath.row]
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        if let vc = storyBoard.instantiateViewController(withIdentifier: "ReadLogViewController") as? ReadLogViewController {
            vc.selectedFileName = selectedFile
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
    }
}


class LogTableViewCell: UITableViewCell{
    
    @IBOutlet weak var nameLbl: UILabel!
}
