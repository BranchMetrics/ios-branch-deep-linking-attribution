//
//  ViewController.swift
//  DelayedInitTest
//
//  Created by Nipun Singh on 9/13/24.
//

import UIKit
import BranchSDK

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
    
    // "Init Branch" button as a bar button item
    private lazy var initBranchButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "Init Branch",
                                     style: .plain,
                                     target: self,
                                     action: #selector(initBranchTapped))
        return button
    }()
    
    // Flag to prevent multiple initializations
    private var isBranchInitialized = false
    
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
        title = "Delayed Init Logs"
        navigationItem.rightBarButtonItem = clearButton
        navigationItem.leftBarButtonItem = initBranchButton
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
    
    @objc private func initBranchTapped() {
        guard !isBranchInitialized else {
            showAlert(title: "Branch Already Initialized", message: "Branch SDK has already been initialized.")
            return
        }
        
//        // Retrieve persisted launch options
//        guard let launchOptions = UserDefaults.standard.retrieveBranchLaunchOptions() else {
//            showAlert(title: "Launch Options Missing", message: "No launch options found to initialize Branch.")
//            return
//        }
        
//        // Convert stored strings back to objects
//        let userActivities = launchOptions.userActivities.map { NSUserActivity(activityType: $0) }
//        let urlContexts = launchOptions.urlStrings.compactMap { URL(string: $0) }
//        
        // Initialize Branch SDK
        Branch.getInstance().initSession(launchOptions: nil, andRegisterDeepLinkHandler: { [weak self] params, error in
            guard let self = self else { return }
            
            if let error = error {
                self.showAlert(title: "Branch Initialization Error", message: error.localizedDescription)
                return
            }
            
            guard let data = params as? [String: AnyObject] else { return }
            print("Branch Params: \(params)")
            
            if let clicked = data["+clicked_branch_link"] as? Bool, clicked == true {
                let dataString = data.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
                self.showAlert(title: "Succesfully Deeplinked!", message: dataString)
            }
        })
        
//        // Handle user activities
//        for activityType in launchOptions.userActivities {
//            let userActivity = NSUserActivity(activityType: activityType)
//            Branch.getInstance().continue(userActivity)
//        }
//        
//        // Handle URL contexts
//        for urlString in launchOptions.urlStrings {
//            if let url = URL(string: urlString) {
//                Branch.getInstance().handleDeepLink(url)
//            }
//        }
        
        isBranchInitialized = true
        showAlert(title: "Branch Initialized", message: "Branch SDK has been successfully initialized.")
    }
    
    private func showAlert(title: String, message: String) {
        // Create alert
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Add OK action
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        // Present alert
        present(alert, animated: true, completion: nil)
    }
}

