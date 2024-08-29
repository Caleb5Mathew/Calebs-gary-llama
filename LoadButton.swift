//
//  LoadButton.swift
//  Gary_Llama
//
//  Created by Caleb Matthews  on 8/29/24.
//

import SwiftUI

struct LoadButton: View {
    @ObservedObject private var llamaState: LlamaState
    private var modelName: String
    private var filename: String

    @State private var status: String

    init(llamaState: LlamaState, modelName: String, filename: String) {
        self.llamaState = llamaState
        self.modelName = modelName
        self.filename = filename

        let fileURL = Bundle.main.url(forResource: filename, withExtension: nil)
        status = fileURL != nil ? "ready to load" : "not found"
    }

    private func loadModel() {
        if let fileURL = Bundle.main.url(forResource: filename, withExtension: nil) {
            do {
                try llamaState.loadModel(modelUrl: fileURL)
                print("\(modelName) loaded successfully.")
            } catch let err {
                print("Error: \(err.localizedDescription)")
            }
        } else {
            print("Model file not found in bundle.")
        }
    }

    var body: some View {
        VStack {
            if status == "ready to load" {
                Button(action: loadModel) {
                    Text("Load \(modelName)")
                }
            } else {
                Text("Model not found in app bundle.")
            }
        }
    }
}
