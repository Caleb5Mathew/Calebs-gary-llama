import SwiftUI
import Combine

struct ContentView: View {
    @StateObject var llamaState = LlamaState()
    @State private var multiLineText = ""
    @State private var showingHelp = false
    @State private var isKeyboardVisible = false
    
    @State private var keyboardCancellables = Set<AnyCancellable>()

    var body: some View {
        NavigationView {
            VStack {
                // Header image at the top
                Image("GaryLLM_header")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 50)
                    .padding(.top, 50)

                // Scrollable text view for the message log
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
                            hideKeyboard()
                        }
                }
                .background(Color(hex: "#dedfdb"))

                Spacer() // Push the content above the buttons

                // Text editor for input
                TextEditor(text: $multiLineText)
                    .font(.custom("HelveticaNeue", size: 14))
                    .foregroundColor(.black)
                    .background(Color.white)
                    .frame(height: 80)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color(hex: "#dedfdb"), lineWidth: 0.5)
                    )
                    .environment(\.colorScheme, .light)
                    .onTapGesture {
                        // Handle tap on TextEditor
                    }
                    .onSubmit {
                        sendText()
                    }
                    .padding(.bottom, isKeyboardVisible ? 0 : 0) // Adjust the padding

                // Load Model Button
                LoadButton(
                    llamaState: llamaState,
                    modelName: "stablelm-2-zephyr-1_6b",
                    filename: "stablelm-2-zephyr-1_6b-Q4_1.gguf"
                )
                .padding()

                // HStack for buttons
                HStack {
                    Spacer()
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
                    Spacer()
                }
                .font(.custom("HelveticaNeue", size: 14))
                .foregroundColor(.white)
                .padding()
                .background(Color(hex: "#253439"))
                .cornerRadius(8)
                .padding(.bottom, isKeyboardVisible ? 10 : 0) // Adjust the padding
            }
            .padding(.bottom, isKeyboardVisible ? 300 : 0) // Adjust the entire view padding
            .background(Color(hex: "#dedfdb"))
            .edgesIgnoringSafeArea(.all)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isKeyboardVisible {
                        Button(action: {
                            hideKeyboard()
                        }) {
                            Image(systemName: "arrow.uturn.left.circle")
                                .imageScale(.large)
                                .foregroundColor(.black)
                        }
                    }
                }
            }
            .onAppear {
                // Observe keyboard show notification
                NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
                    .sink { _ in
                        withAnimation {
                            isKeyboardVisible = true
                        }
                    }
                    .store(in: &keyboardCancellables)
                
                // Observe keyboard hide notification
                NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
                    .sink { _ in
                        withAnimation {
                            isKeyboardVisible = false
                        }
                    }
                    .store(in: &keyboardCancellables)
            }
            .onDisappear {
                keyboardCancellables.forEach { $0.cancel() }
                keyboardCancellables.removeAll()
            }
        }
        .background(Color(hex: "#dedfdb"))
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // Function to hide the keyboard
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // Function to send text
    func sendText() {
        Task {
            await llamaState.complete(text: multiLineText)
            multiLineText = ""
        }
    }

    // Function to benchmark
    func bench() {
        Task {
            await llamaState.bench()
        }
    }

    // Function to clear text
    func clear() {
        Task {
            await llamaState.clear()
        }
    }
}

// DrawerView Definition (kept for reference; can be removed if not used elsewhere)
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

                Text("To load a model, click the Load button on the bottom of the screen!")
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
        .sheet(isPresented: $showingHelp) {
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    Text("1. Make sure the model is in GGUF Format")
                        .padding()
                    Text("2. Copy the download link of the quantized model")
                        .padding()
                }
                Spacer()
            }
            .padding()
        }
    }
}

// Helper extension to use hex colors
extension Color {
    init(hex: String) {
        var hexFormatted = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexFormatted.hasPrefix("#") {
            hexFormatted.remove(at: hexFormatted.startIndex)
        }
        
        var rgbValue: UInt64 = 0
        Scanner(string: hexFormatted).scanHexInt64(&rgbValue)

        let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgbValue & 0x0000FF) / 255.0

        self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1.0)
    }
}

// Preview provider for SwiftUI previews
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
