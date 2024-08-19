//
//  ContentView.swift
//  Gary_Llama
//
//  Created by Caleb Matthews  on 7/29/24.
//




import SwiftUI

struct ContentView: View {
    @StateObject var llamaState = LlamaState()
    @State private var multiLineText = ""
    @State private var showingHelp = false    // To track if Help Sheet should be shown

    var body: some View {
        NavigationView {
            VStack {
                // Display the "GaryLLM_header" image at the Top Center just below the notch
                Image("GaryLLM_header")  // This is the image name
                    .resizable()
                    .scaledToFit()
                    .frame(height: 50)  // Smaller height to resemble a logo
                    .padding(.top, 50)  // Adjust padding to position below the notch

                ScrollView(.vertical, showsIndicators: true) {
                    Text(llamaState.messageLog)
                        .font(.custom("HelveticaNeue", size: 14))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(hex: "#dedfdb"))
                        .cornerRadius(5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color(hex: "#dedfdb"), lineWidth: 0.5)
                        )
                        .onTapGesture {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                }
                .background(Color(hex: "#dedfdb"))  // Ensure the ScrollView background matches

                TextEditor(text: $multiLineText)
                    .font(.custom("HelveticaNeue", size: 14))
                    .foregroundColor(.black)
                    .background(Color.white)  // White background for the TextEditor for contrast
                    .frame(height: 80)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color(hex: "#dedfdb"), lineWidth: 0.5)
                    )

                HStack {
                    Spacer()  // Add Spacer to separate buttons
                    Button("Send") {
                        sendText()
                    }
                    Spacer()
                    Button("Bench") {
                        bench()
                    }
                    Spacer()
                    Button("Clear") {
                        clear()
                    }
                    Spacer()
                    Button("Copy") {
                        UIPasteboard.general.string = llamaState.messageLog
                    }
                    Spacer()  // Add Spacer to separate buttons
                }
                .font(.custom("HelveticaNeue", size: 14))
                .foregroundColor(.white)
                .padding()
                .background(Color(hex: "#253439"))
                .cornerRadius(8)

                NavigationLink(destination: DrawerView(llamaState: llamaState)) {
                    Text("View Models")
                        .font(.custom("HelveticaNeue", size: 14))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color(hex: "#253439"))
                        .cornerRadius(8)
                }
                .padding()

            }
            .background(Color(hex: "#dedfdb"))  // Set the background of the entire VStack
            .edgesIgnoringSafeArea(.all)  // Ensure the background extends to the edges of the screen
        }
        .background(Color(hex: "#dedfdb"))  // Set the background of the entire NavigationView
    }

    func sendText() {
        Task {
            await llamaState.complete(text: multiLineText)
            multiLineText = ""
        }
    }

    func bench() {
        Task {
            await llamaState.bench()
        }
    }

    func clear() {
        Task {
            await llamaState.clear()
        }
    }


    
    
    struct DrawerView: View {

        @ObservedObject var llamaState: LlamaState
        @State private var showingHelp = false
        func delete(at offsets: IndexSet) {
            offsets.forEach { offset in
                let model = llamaState.downloadedModels[offset]
                let fileURL = getDocumentsDirectory().appendingPathComponent(model.filename)
                do {
                    try FileManager.default.removeItem(at: fileURL)
                } catch {
                    print("Error deleting file: \(error)")
                }
            }

            // Remove models from downloadedModels array
            llamaState.downloadedModels.remove(atOffsets: offsets)
        }

        func getDocumentsDirectory() -> URL {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            return paths[0]
        }

        var body: some View {
            List {
                Section(header: Text("Download Models From Hugging Face")) {
                    HStack {
                        InputButton(llamaState: llamaState)
                    }
                }
                Section(header: Text("Downloaded Models")) {
                    ForEach(llamaState.downloadedModels) { model in
                        DownloadButton(llamaState: llamaState, modelName: model.name, modelUrl: model.url, filename: model.filename)
                    }
                    .onDelete(perform: delete)

                    // Add this text below the downloaded models
                    Text("To load a model, tap load and then go back to the chat log")
                        .font(.custom("HelveticaNeue", size: 14))
                        .foregroundColor(.gray)
                        .padding(.top, 5)
                }
                Section(header: Text("Default Models")) {
                    ForEach(llamaState.undownloadedModels) { model in
                        DownloadButton(llamaState: llamaState, modelName: model.name, modelUrl: model.url, filename: model.filename)
                    }
                }
            }
            .font(.custom("HelveticaNeue", size: 14))
            .background(Color(hex: "#dedfdb"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Help") {
                        showingHelp = true
                    }
                }
            }
            .sheet(isPresented: $showingHelp) {    // Sheet for help modal
                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        Text("1. Make sure the model is in GGUF Format")
                            .padding()
                        Text("2. Copy the download link of the quantized model")
                            .padding()
                    }
                    Spacer()
                }
            }
        }
    }

    }


// Helper to use hex colors
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.scanLocation = 1 // skip #
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let red = Double((rgbValue & 0xff0000) >> 16) / 255.0
        let green = Double((rgbValue & 0xff00) >> 8) / 255.0
        let blue = Double(rgbValue & 0xff) / 255.0

        self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
