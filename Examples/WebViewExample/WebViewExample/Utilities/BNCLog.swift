//
//  BNCLog.swift
//  WebViewExample
//
//  Created by Jimmy Dee on 4/7/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

/**
 * Logs a message at BNCLogLevel.debug
 * - Parameters:
 *   - message: the message to log
 *   - file: (unused) provides the Swift source file path
 *   - line: (unused) provides the Swift line number
 */
func BNCLogDebug(_ message: String, _ file: String=#file, _ line: UInt=#line) {
    BNCSwiftLog.debug(message, file: file, line: line)
}

/**
 * Logs a message at BNCLogLevel.error
 * - Parameters:
 *   - message: the message to log
 *   - file: (unused) provides the Swift source file path
 *   - line: (unused) provides the Swift line number
 */
func BNCLogError(_ message: String, _ file: String=#file, _ line: UInt=#line) {
    BNCSwiftLog.error(message, file: file, line: line)
}

/**
 * Logs a message at BNCLogLevel.log
 * - Parameters:
 *   - message: the message to log
 *   - file: (unused) provides the Swift source file path
 *   - line: (unused) provides the Swift line number
 */
func BNCLog(_ message: String, _ file: String=#file, _ line: UInt=#line) {
    BNCSwiftLog.log(message, file: file, line: line)
}

/**
 * Logs a message at BNCLogLevel.warning
 * - Parameters:
 *   - message: the message to log
 *   - file: (unused) provides the Swift source file path
 *   - line: (unused) provides the Swift line number
 */
func BNCLogWarning(_ message: String, _ file: String=#file, _ line: UInt=#line) {
    BNCSwiftLog.warning(message, file: file, line: line)
}
