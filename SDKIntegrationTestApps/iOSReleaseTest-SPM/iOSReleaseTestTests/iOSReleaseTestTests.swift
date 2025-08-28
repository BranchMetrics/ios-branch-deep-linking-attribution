//
//  iOSReleaseTestTests.swift
//  iOSReleaseTestTests
//
//  Created by Nidhi Dixit on 1/15/23.
//

import XCTest
import BranchSDK

@testable import iOSReleaseTest

final class iOSReleaseTestTests: XCTestCase {

    // A static property to hold the file handle, ensuring it persists across all test runs.
    private static var logFileHandle: FileHandle?
    
    // A serial dispatch queue to ensure that writes to the log file are thread-safe.
    private static let logQueue = DispatchQueue(label: "io.branch.sdk.testLogQueue")

    // This class method is called once before any tests in this class are run.
    override class func setUp() {
        super.setUp()
        setupBranchFileLogging()
        BranchLogger.shared().logDebug("Inside Setup", error: nil)
    }
    
    // This class method is called once after all tests in this class have been run.
    override class func tearDown() {
        logQueue.sync {
            self.logFileHandle?.closeFile()
            self.logFileHandle = nil
        }
        super.tearDown()
    }
    
    /// Sets up a file-based logger for the Branch SDK to capture verbose output during tests.
    private static func setupBranchFileLogging() {
        // Find the Caches directory, a reliable place to write temporary files.
        guard let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            XCTFail("Could not access Caches directory.")
            return
        }
        
        // Define the path for the log file.
        let logFileURL = cacheDir.appendingPathComponent("branch_sdk_test_logs.log")
        let logFilePath = logFileURL.path
        
        // Clear any old log file before starting.
        try? FileManager.default.removeItem(at: logFileURL)
        
        // This log will now appear in your main xcodebuild output.
        // It helps confirm that this code is running and shows the exact path.
        NSLog("[BRANCH SDK TEST LOGGING] Writing logs to: \(logFilePath)")
        
        // Create an empty file and get a handle for writing to it.
        guard FileManager.default.createFile(atPath: logFilePath, contents: nil, attributes: nil) else {
            XCTFail("Failed to create log file at path: \(logFilePath)")
            return
        }
        
        do {
            self.logFileHandle = try FileHandle(forWritingTo: logFileURL)
        } catch {
            XCTFail("Failed to open file handle for writing: \(error.localizedDescription)")
            return
        }

        // Enable Branch SDK's verbose logging and direct its output to our file.
        Branch.enableLogging(at: .verbose) { message, logLevel, error in
            // Use the serial queue to safely write from any thread.
            logQueue.async {
                var logLine = ""
                if (message.isEmpty == false) {
                    logLine = "\(Date()): \(message)\n"
                }
                else {
                    logLine = "\(Date()): Empty Message"
                }
                guard let logData = logLine.data(using: .utf8) else { return }
                
                // Seek to the end and write the new log line.
                self.logFileHandle?.seekToEndOfFile()
                self.logFileHandle?.write(logData)
            }
        }
    }

    func testSetTrackingDisabled() throws {

        print("Satrting Test testSetTrackingDisabled ....")
        // 1. Create an expectation to wait for the async init callback.
           let expectation = self.expectation(description: "Branch SDK Init")

           // 2. Initialize the Branch session.
        print("Going to initialize session ....")
           Branch.getInstance().initSession(launchOptions: nil) { params, error in
               // The init callback has returned, so we can fulfill the expectation.
               print("Session initialized ...")
               XCTAssertNil(error, "Branch init failed with error: \(error?.localizedDescription ?? "unknown")")
               expectation.fulfill()
           }
        print("Waiting for ....")
           // 3. Wait for the expectation to be fulfilled before continuing.
           waitForExpectations(timeout: 5, handler: nil)
        print("Waiting finished")
           // 4. Now perform your test logic on the initialized SDK.
        /*   let sdk = BranchSDKTest()
           sdk.disableTracking(status: true)
           let isTrackingDisabled = sdk.trackingStatus()
           XCTAssertTrue(isTrackingDisabled, "Tracking should have been disabled.")
           
           // You can re-enable it for other tests if needed.
           sdk.disableTracking(status: false)*/
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
