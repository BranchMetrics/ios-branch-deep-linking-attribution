import XCTest
import Foundation

class TestObserver: NSObject, XCTestObservation {
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
        
    func testBundleWillStart(_ testBundle: Bundle) {
        logMessage("Test Bundle Will Start: \(testBundle.bundleIdentifier ?? "Unknown")")
        logMessage("Bundle Path: \(testBundle.bundlePath)")
    }
    
    func testBundleDidFinish(_ testBundle: Bundle) {
        logMessage("Test Bundle Did Finish: \(testBundle.bundleIdentifier ?? "Unknown")")
    }
    
    func testSuiteWillStart(_ testSuite: XCTestSuite) {
        logMessage("Test Suite Will Start: \(testSuite.name)")
        logMessage("Test Count: \(testSuite.testCaseCount)")
    }
    
    func testSuiteDidFinish(_ testSuite: XCTestSuite) {
        let duration = String(format: "%.3f", testSuite.testRun?.totalDuration ?? 0)
        let failures = testSuite.testRun?.failureCount ?? 0
        let unexpected = testSuite.testRun?.unexpectedExceptionCount ?? 0
        
        logMessage("Test Suite Did Finish: \(testSuite.name)")
        logMessage("Duration: \(duration)s")
        logMessage("Failures: \(failures)")
        logMessage("Unexpected Exceptions: \(unexpected)")
        
        if failures > 0 || unexpected > 0 {
            logMessage("SUITE FAILED: \(testSuite.name)")
        } else {
            logMessage("SUITE PASSED: \(testSuite.name)")
        }
    }
    
    func testCaseWillStart(_ testCase: XCTestCase) {
        logMessage("Test Case Will Start: \(testCase.name)")
        logMessage("Class: \(String(describing: type(of: testCase)))")
    }
    
    func testCaseDidFinish(_ testCase: XCTestCase) {
        guard let testRun = testCase.testRun else {
            logMessage("Test Case Did Finish (No Run Info): \(testCase.name)")
            return
        }
        
        let duration = String(format: "%.3f", testRun.totalDuration)
        let failures = testRun.failureCount
        let unexpected = testRun.unexpectedExceptionCount
        
        logMessage("Test Case Did Finish: \(testCase.name)")
        logMessage("Duration: \(duration)s")
        
        if testRun.hasSucceeded {
            logMessage("PASSED: \(testCase.name)")
        } else {
            logMessage("FAILED: \(testCase.name)")
            logMessage("Failures: \(failures)")
            logMessage("Unexpected Exceptions: \(unexpected)")
        }
    }
    
    func testCase(_ testCase: XCTestCase, didFailWithDescription description: String, inFile filePath: String?, atLine lineNumber: Int) {
        logMessage("TEST FAILURE:")
        logMessage("Test: \(testCase.name)")
        logMessage("Description: \(description)")
        
        if let filePath = filePath {
            let fileName = URL(fileURLWithPath: filePath).lastPathComponent
            logMessage("File: \(fileName):\(lineNumber)")
        }
        logMessage(String(repeating: "=", count: 80))
    }
    
    func testCase(_ testCase: XCTestCase, didRecord issue: XCTIssue) {
        logMessage("TEST ISSUE RECORDED:")
        logMessage("Test: \(testCase.name)")
        logMessage("Description: \(issue.compactDescription)")
        logMessage("Type: \(issue.type.description)")
        
        if let location = issue.sourceCodeContext.location {
            if #available(iOS 16.0, *) {
                let fileName = URL(fileURLWithPath: location.fileURL.path()).lastPathComponent
                logMessage("Location: \(fileName):\(location.lineNumber)")
            } else {
                logMessage("Location: Available on iOS versions - iOS 16+")
            }
           
        }
        
        // Add detailed description if available
        if ((issue.detailedDescription?.isEmpty) == nil) && issue.detailedDescription != issue.compactDescription {
            logMessage("Details: \(String(describing: issue.detailedDescription))")
        }
    }
    
    // MARK: - Helper Methods
    
    private func logMessage(_ message: String) {
        let timestamp = dateFormatter.string(from: Date())
        let logLine = "[\(timestamp)] [TestObserver] \(message)"
        print(logLine)
        fflush(stdout)
    }
}

extension XCTIssue.IssueType {
    var description: String {
        switch self {
        case .assertionFailure:
            return "Assertion Failure"
        case .performanceRegression:
            return "Performance Regression"
        case .system:
            return "System Issue"
        case .thrownError:
            return "Thrown Error"
        case .uncaughtException:
            return "Uncaught Exception"
        case .unmatchedExpectedFailure:
            return "Unmatched Expected Failure"
        @unknown default:
            return "Unknown Issue Type"
        }
    }
}
