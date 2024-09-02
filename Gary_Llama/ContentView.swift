import SwiftUI
import Combine

struct ContentView: View {
    @StateObject var llamaState = LlamaState()
    @State private var multiLineText = ""
    @State private var showingHelp = false    // To track if Help Sheet should be shown
    @State private var isKeyboardVisible = false // Track keyboard visibility
    
    @State private var keyboardCancellables = Set<AnyCancellable>() // To store multiple cancellables

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
                            hideKeyboard()
                        }
                }
                .background(Color(hex: "#dedfdb"))  // Ensure the ScrollView background matches

                Spacer() // Add spacer to move the content up

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
                    .onTapGesture {
                        // Handle tap on TextEditor to make sure keyboard appears
                    }
                    .onSubmit {
                        sendText() // Trigger send when return key is pressed
                    }
                    .background(GeometryReader { geometry in
                        Color.clear.onAppear {
                            NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
                                .sink { notification in
                                    if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                                        let keyboardHeight = keyboardFrame.height
                                        let bottomPadding = geometry.size.height - keyboardHeight - 100 // Adjust to your needs
                                        withAnimation {
                                            isKeyboardVisible = true
                                        }
                                    }
                                }
                                .store(in: &keyboardCancellables)
                            
                            NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
                                .sink { _ in
                                    withAnimation {
                                        isKeyboardVisible = false
                                    }
                                }
                                .store(in: &keyboardCancellables)
                        }
                    })

                Spacer() // Add spacer to move the content up

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

                // Load Model Button
                LoadButton(
                    llamaState: llamaState,
                    modelName: "stablelm-2-zephyr-1_6b",
                    filename: "stablelm-2-zephyr-1_6b-Q4_1.gguf"
                )
                .padding()

                Spacer() // Final spacer to push everything up when keyboard is visible
            }
            .background(Color(hex: "#dedfdb"))  // Set the background of the entire VStack
            .edgesIgnoringSafeArea(.all)  // Ensure the background extends to the edges of the screen
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
                // Cancel all keyboard-related subscriptions
                keyboardCancellables.forEach { $0.cancel() }
                keyboardCancellables.removeAll()
            }
        }
        .background(Color(hex: "#dedfdb"))  // Set the background of the entire NavigationView
        .navigationViewStyle(StackNavigationViewStyle()) // Use StackNavigationViewStyle for consistent behavior on iPad
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
}


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
