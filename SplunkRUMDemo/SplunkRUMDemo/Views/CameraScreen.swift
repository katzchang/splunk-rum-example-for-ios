import SwiftUI
import AVFoundation

struct CameraScreen: View {
    @State private var capturedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined

    var body: some View {
        VStack(spacing: 20) {
            // Preview area
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 400)
                    .cornerRadius(12)
                    .padding()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))
                        .frame(height: 300)

                    VStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No photo captured")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }

            Spacer()

            // Camera button
            Button(action: {
                checkCameraPermissionAndOpen()
            }) {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("Take Photo")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding(.horizontal)

            // Clear button
            if capturedImage != nil {
                Button(action: {
                    capturedImage = nil
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Clear Photo")
                    }
                    .font(.headline)
                    .foregroundColor(.red)
                }
                .padding(.bottom)
            }
        }
        .navigationTitle("Camera")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $capturedImage)
        }
        .alert("Camera Access", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
            if cameraPermissionStatus == .denied {
                Button("Open Settings") {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }
            }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
        }
    }

    private func checkCameraPermissionAndOpen() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showingImagePicker = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showingImagePicker = true
                    } else {
                        alertMessage = "Camera access is required to take photos."
                        showingAlert = true
                    }
                    cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
                }
            }
        case .denied, .restricted:
            alertMessage = "Camera access has been denied. Please enable it in Settings to use this feature."
            cameraPermissionStatus = .denied
            showingAlert = true
        @unknown default:
            break
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
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

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        CameraScreen()
    }
}
