//
//  ViewController.swift
//  ScenesTest
//
//  Created by Nipun Singh on 9/13/24.
//

import UIKit

extension Notification.Name {
    static let newLogAvailable = Notification.Name("newLogAvailable")
}

class ViewController: UIViewController {
    
    private var logsFilePath: String {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent("console.log").path
    }
    
    // Create the text view
      private let textView: UITextView = {
          let tv = UITextView()
          tv.isEditable = false  // Make it read-only
          tv.font = UIFont(name: "Menlo", size: 14)  // Console-like font
          tv.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)  // Add padding
          tv.layer.cornerRadius = 10  // Rounded corners
          tv.layer.borderColor = UIColor.gray.cgColor
          tv.clipsToBounds = true
          tv.backgroundColor = UIColor(white: 0.95, alpha: 1)  // Light gray background for contrast
          tv.translatesAutoresizingMaskIntoConstraints = false
          return tv
      }()
    
    // Create the "Clear" button as a bar button item
    private lazy var clearButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "Clear",
                                     style: .plain,
                                     target: self,
                                     action: #selector(clearLogs))
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // Set up the view
        setupView()
        setupNavigationBar()
        setupConstraints()
        
        displayLogs()
        
        NotificationCenter.default.addObserver(self, selector: #selector(displayLogs), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    
    private func setupView() {
        view.backgroundColor = .white
        view.addSubview(textView)
    }
    
    private func setupNavigationBar() {
        title = "Logs"
        navigationItem.rightBarButtonItem = clearButton
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    @objc private func displayLogs() {
        let logsFilePath = getLogFilePath()
        do {
            let logs = try String(contentsOfFile: logsFilePath, encoding: .utf8)
            textView.text = logs
        } catch {
            print("Error reading logs: \(error)")
        }
    }
    
    @objc private func clearLogs() {
        let logsFilePath = getLogFilePath()
        // Truncate the file without deleting it
        if let fileHandle = FileHandle(forWritingAtPath: logsFilePath) {
            fileHandle.truncateFile(atOffset: 0)
            fileHandle.closeFile()
        }
        textView.text = "Cleared logs!"
    }
    
    private func getLogFilePath() -> String {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent("console.log").path
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}

