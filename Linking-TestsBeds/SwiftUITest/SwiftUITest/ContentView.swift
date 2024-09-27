//
//  ContentView.swift
//  SwiftUITest
//
//  Created by Nipun Singh on 9/13/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var logReader = LogReader()
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    Text(logReader.logs)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding()
                
            }
            .navigationTitle("Logs")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        logReader.clearLogs()
                    }) {
                        Text("Clear")
                    }
                }
            }
        }
    }
}

class LogReader: ObservableObject {
    @Published var logs: String = ""
    private var timer: Timer?
    
    init() {
        startReadingLogs()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    private func startReadingLogs() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.readLogs()
        }
    }
    
    private func readLogs() {
        let logsFilePath = getLogFilePath()
        if let logData = try? String(contentsOfFile: logsFilePath) {
            DispatchQueue.main.async {
                self.logs = logData
            }
        }
    }
    
    func clearLogs() {
        let logsFilePath = getLogFilePath()
        // Clear the content of the log file
        try? "".write(toFile: logsFilePath, atomically: true, encoding: .utf8)
        self.logs = ""
    }
    
    private func getLogFilePath() -> String {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent("console.log").path
    }
}
