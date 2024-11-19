//
//  Camera.swift
//  DanceCam-iOS
//
//  Created by Abby Farhat on 11/18/24.
//

import MediaPipeTasksVision
import AVFoundation
import Photos

// MARK: - Camera Manager
class CameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    public let captureSession = AVCaptureSession()
    private var videoOutput = AVCaptureVideoDataOutput()
    private var poseLandmarker: PoseLandmarker?
    private var movieFileOutput: AVCaptureMovieFileOutput?
    
    @Published var isRecording = false
    @Published var isFlipping = false
    @Published var currentPosition: AVCaptureDevice.Position = .front
    @Published var lastError: String?
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
        checkPhotoLibraryPermission()
        
        if let currentMovieOutput = movieFileOutput {
            captureSession.removeOutput(currentMovieOutput)
        }
        
        movieFileOutput = AVCaptureMovieFileOutput()
        
        if captureSession.canAddOutput(movieFileOutput!) {
            captureSession.addOutput(movieFileOutput!)
        }

        
//        sendData(duty1: 1000, duty2: 1000, duty3: 1000, duty4: 1000)
//        Thread.sleep(forTimeInterval: 2.0)
//        sendData(duty1: 0, duty2: 0, duty3: 0, duty4: 0)
//        Thread.sleep(forTimeInterval: 2.0)
//        sendData(duty1: -1000, duty2: -1000, duty3: -1000, duty4: -1000)
//        Thread.sleep(forTimeInterval: 2.0)
//        sendData(duty1: 0, duty2: 0, duty3: 0, duty4: 0)
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
    
    private func checkPhotoLibraryPermission() {
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization { [weak self] status in
                DispatchQueue.main.async {
                    if status != .authorized {
                        self?.lastError = "Photo library access denied"
                    }
                }
            }
        } else if status != .authorized {
            DispatchQueue.main.async {
                self.lastError = "Photo library access denied"
            }
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
    
    func startRecording() {
        guard let movieFileOutput = movieFileOutput else { return }
        
        // Create temporary URL for the video
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let videoName = "video-\(Date().timeIntervalSince1970).mov"
        let videoURL = documentsPath.appendingPathComponent(videoName)
        
        // Start recording
        movieFileOutput.startRecording(to: videoURL, recordingDelegate: self)
        isRecording = true
    }

    func stopRecording() {
        movieFileOutput?.stopRecording()
    }
    
    func flipCamera() {
        guard !isFlipping else { return }
        isFlipping = true
        
        // Get new camera position
        let newPosition: AVCaptureDevice.Position = currentPosition == .back ? .front : .back
        
        // Get new video device
        guard let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
              let videoInput = try? AVCaptureDeviceInput(device: newCamera) else {
            isFlipping = false
            return
        }
        
        captureSession.beginConfiguration()
        
        // Remove existing input
        if let currentInput = captureSession.inputs.first {
            captureSession.removeInput(currentInput)
        }
        
        // Add new input
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
            currentPosition = newPosition
        }
        
        captureSession.commitConfiguration()
        
        // Add slight delay to ensure smooth animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.isFlipping = false
        }
    }
    
    private func saveVideoToPhotoLibrary(videoURL: URL) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
        }) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    print("Video saved successfully to photo library")
                } else {
                    self?.lastError = "Failed to save video: \(error?.localizedDescription ?? "Unknown error")"
                }
                
                // Clean up temporary file
                try? FileManager.default.removeItem(at: videoURL)
            }
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
        
        // Dispatch UI updates to the main thread
        DispatchQueue.main.async { [weak self] in
            self?.poses = newLandmarks
            
            if let pose = newLandmarks.first {
                var xValues: [Float] = []
                var yValues: [Float] = []
                
                for landmark in pose {
                    xValues.append(landmark.x)
                    yValues.append(landmark.y)
                }
                
                let xMin: Float = xValues.min()!
                let xMax: Float = xValues.max()!
                let yMin: Float = yValues.min()!
                let yMax: Float = yValues.max()!
                
                let cX: Float = (xMin + xMax) / 2
                let cY: Float = (yMin + yMax) / 2
                
                // Use cX and cY as needed
            }
            //        sendData(duty1:0,duty2:0,duty3:0,duty4:0)
        }
    } else {
        print("Failed to detect with error: \(error.debugDescription)")
    }
  }
}

extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput,
                   didFinishRecordingTo outputFileURL: URL,
                   from connections: [AVCaptureConnection],
                   error: Error?) {
        DispatchQueue.main.async {
            self.isRecording = false
        }
        
        if let error = error {
            DispatchQueue.main.async {
                self.lastError = "Recording error: \(error.localizedDescription)"
            }
            return
        }
        
        // Save to photo library
        saveVideoToPhotoLibrary(videoURL: outputFileURL)
    }
    
    func fileOutput(_ output: AVCaptureFileOutput,
                   didStartRecordingTo fileURL: URL,
                   from connections: [AVCaptureConnection]) {
        // Optional: Handle recording start
    }
}
