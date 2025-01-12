//
//  CSVManagementView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 12.01.25.
//

import SwiftUI
import UniformTypeIdentifiers

struct CSVManagementView: View {
    @State private var fileContent: String = ""
    @State private var showingFileImporter = false
    
    @State private var isLoading: Bool = false
    @State private var success: Bool = false
    @State private var errorMessage: String?
    var body: some View {
        VStack(spacing: 20) {
            Text("Upload a CSV File")
                .font(.title)

            Button(action: {
                showingFileImporter = true
            }) {
                Text("Select a File")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: [.plainText],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result: result)
            }

            if isLoading {
                ProgressView("Uploading...")
            } else if !isLoading && success {
                Text("File uploaded successfully")
                    .foregroundColor(.green)
            } else if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            } else {
                Text("Plaese select a file")
                    .foregroundColor(.red)
                    .font(.headline)
                    
            }

            Spacer()
        }
        .padding()
    }

    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let selectedFile = urls.first else { return }
            
            // Start accessing security-scoped resource
            guard selectedFile.startAccessingSecurityScopedResource() else {
                print("Unable to access file: \(selectedFile)")
                return
            }
            
            defer { selectedFile.stopAccessingSecurityScopedResource() }
            
            do {
                let fileData = try String(contentsOf: selectedFile, encoding: .utf8)
                fileContent = fileData
                batchPersons();
            } catch {
                print("Error reading file: \(error.localizedDescription)")
            }
        case .failure(let error):
            print("Error importing file: \(error.localizedDescription)")
        }
    }
    
    func batchPersons() {
        if fileContent == "" {
            return
        }
        
        isLoading = true
        errorMessage = nil
        success = false
        
        let csvPersonBatch = CSVPersonBatch(csv: fileContent)
        print("CSV Person Batch: \(csvPersonBatch)")
            
        fetch("persons/batch", CSVPersonBatchResponse.self, "POST", nil, csvPersonBatch) { result in
            switch result {
            case .success( _):
                success = true
                errorMessage = nil
            case .failure(let error):
                errorMessage = error.localizedDescription
                print(error)
                success = false
            }
            isLoading = false
        }
    }

}
