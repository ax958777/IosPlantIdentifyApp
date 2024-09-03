//
//  ContentView.swift
//  PlantIdentifyApp
//
//  Created by AlexX on 2024-09-02.
//

import SwiftUI

// MARK: - Models

struct Plant: Identifiable {
    let id = UUID()
    let name: String
    let description: String
}

// MARK: - View Models

class PlantIdentifierViewModel: ObservableObject {
    @Published var identifiedPlant: Plant?
    @Published var isLoading = false
    @Published var error: String?
    
    private let geminiService: GeminiService
    
    init(geminiService: GeminiService = GeminiService()) {
        self.geminiService = geminiService
    }
    
    func identifyPlant(image: UIImage) {
        isLoading = true
        error = nil
        
        geminiService.identifyPlant(image: image) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let plant):
                    self.identifiedPlant = plant
                case .failure(let error):
                    self.error = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Views

struct ContentView: View {
    @StateObject private var viewModel = PlantIdentifierViewModel()
    @State private var isImagePickerPresented = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        NavigationView {
            VStack {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                }
                
                Button(action: {
                    isImagePickerPresented = true
                }) {
                    Text("Upload Plant Image")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                if viewModel.isLoading {
                    ProgressView()
                } else if let plant = viewModel.identifiedPlant {
                    PlantInfoView(plant: plant)
                } else if let error = viewModel.error {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Plant Identifier")
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePicker(image: $selectedImage, onImagePicked: { image in
                    viewModel.identifyPlant(image: image)
                })
            }
        }
    }
}

struct PlantInfoView: View {
    let plant: Plant
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Name: \(plant.name)")
                .font(.headline)
            Text("Description: \(plant.description)")
                .font(.body)
        }
        .padding()
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var onImagePicked: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
                parent.onImagePicked(image)
            }
            picker.dismiss(animated: true)
        }
    }
}



#Preview {
    ContentView()
}
