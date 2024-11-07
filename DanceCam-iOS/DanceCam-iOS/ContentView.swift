import SwiftUI
import MediaPipeTasksVision
import AVFoundation

// MARK: - Models
struct Landmark: Identifiable {
    let id = UUID()
    let x: Float
    let y: Float
    let z: Float
    let visibility: Float
    let presence: Float
}

// MARK: - Camera Manager
class CameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    public let captureSession = AVCaptureSession()
    private var videoOutput = AVCaptureVideoDataOutput()
    private var poseLandmarker: PoseLandmarker?
    
    @Published var poses: [[NormalizedLandmark]] = []
    
    override init() {
        super.init()
        
        // Initialize PoseLandmarker with default settings
        let options = PoseLandmarkerOptions()
        options.baseOptions.modelAssetPath = Bundle.main.path(forResource: "pose_landmarker_lite", ofType: "task")!
        options.runningMode = .liveStream
        options.poseLandmarkerLiveStreamDelegate = self
        options.numPoses = 17

        do {
            poseLandmarker = try PoseLandmarker(options: options)
        } catch {
           fatalError("Failed to initialize pose landmarker: \(error)")
       }
        
        setupCamera()
    }
    
    private func setupCamera() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("Failed to get camera device")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.videoSettings = [ String(kCVPixelBufferPixelFormatTypeKey) : kCMPixelFormat_32BGRA]
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
            }
        } catch {
            print("Failed to setup camera: \(error)")
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let image = try? MPImage(sampleBuffer: sampleBuffer) else { return }
        
        do {
            try poseLandmarker?.detectAsync(image: image, timestampInMilliseconds: Int(Date().timeIntervalSince1970 * 1000))
        } catch {
            print("Failed to detect pose: \(error)")
        }
    }
}

// MARK: - Pose Livestream Processor
extension CameraManager: PoseLandmarkerLiveStreamDelegate {

  func poseLandmarker(
    _ poseLandmarker: PoseLandmarker,
    didFinishDetection result: PoseLandmarkerResult?,
    timestampInMilliseconds: Int,
    error: Error?) {
    if (error == nil) {
        guard let newLandmarks = result?.landmarks else {
            return
        }
        
        poses = newLandmarks
        
        // TODO: send to rpi
    } else {
        print("Failed to detect with error: \(error.debugDescription)")
    }
  }
}

// MARK: - Camera Preview
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - Pose Visualization View
struct PoseVisualizationView: View {
    let poses: [[NormalizedLandmark]]
    let size: CGSize
    
    var body: some View {
        Canvas { context, size in
            for pose in poses {
                for landmark in pose {
                    // TODO: visualize
                    // https://ai.google.dev/edge/mediapipe/solutions/vision/pose_landmarker/ios#livestream:~:text=new%20input%20frame.-,Handle%20and%20display%20results,-Upon%20running%20inference
                }
            }
        }
        .frame(width: size.width, height: size.height)
    }
}

// MARK: - Main View
struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    
    var body: some View {
        ZStack {
            CameraPreview(session: cameraManager.captureSession)
                .edgesIgnoringSafeArea(.all)
            
            PoseVisualizationView(
                poses: cameraManager.poses,
                size: UIScreen.main.bounds.size
            )
        }
    }
}
