//
//  Camera.swift
//  DanceCam-iOS
//
//  Created by Abby Farhat on 11/18/24.
//

import MediaPipeTasksVision
import AVFoundation
import Photos

// Image frame width and height
var frameWidth: Float = 0
var frameHeight: Float = 0

// MARK: - Camera Manager
class CameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    public let captureSession = AVCaptureSession()
    private var videoOutput = AVCaptureVideoDataOutput()
    private var poseLandmarker: PoseLandmarker?
    private var movieFileOutput: AVCaptureMovieFileOutput?
    
    @Published var isRecording = false
    @Published var isFlipping = false
    @Published var isConfigured = false
    @Published var currentPosition: AVCaptureDevice.Position = .front
    @Published var lastError: String?
    @Published var poses: [[NormalizedLandmark]] = []
    @Published var options = PoseLandmarkerOptions()
    @Published var timeRemaining: Int = 5
    
    @Published var isSendingToRPi: Bool {
        didSet {
            UserDefaults.standard.set(isSendingToRPi, forKey: "isSendingToRPi")
        }
    }
    @Published var isDisplayingViz: Bool {
        didSet {
            UserDefaults.standard.set(isDisplayingViz, forKey: "isDisplayingViz")
        }
    }
    
    // Maximum number of poses detected by the pose landmarker (total number of dancers)
    @Published var numPoses: Int = 1 { // Default to 1
        didSet {
            options.numPoses = numPoses
            updatePoseLandmarker()
        }
    }
    
    override init() {
        self.isSendingToRPi = UserDefaults.standard.bool(forKey: "isSendingToRPi")
        self.isDisplayingViz = UserDefaults.standard.bool(forKey: "isDisplayingViz")
        super.init()
        
        // Initialize PoseLandmarker with default settings
        options.baseOptions.modelAssetPath = Bundle.main.path(forResource: MODEL, ofType: MODEL_EXT)!
        options.runningMode = .liveStream
        options.poseLandmarkerLiveStreamDelegate = self
        options.minTrackingConfidence = 0.7

        do {
            poseLandmarker = try PoseLandmarker(options: options)
        } catch {
           fatalError("Failed to initialize pose landmarker: \(error)")
       }
        
        
        setupCamera()
        checkPhotoLibraryPermission()
        setupAudio()
        
        if let currentMovieOutput = movieFileOutput {
            captureSession.removeOutput(currentMovieOutput)
        }
        
        movieFileOutput = AVCaptureMovieFileOutput()
        
        if captureSession.canAddOutput(movieFileOutput!) {
            captureSession.addOutput(movieFileOutput!)
        }
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
    
    private func setupAudio() {
        // Request audio permission
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            guard granted else {
                DispatchQueue.main.async {
                    self?.lastError = "Microphone access denied"
                }
                return
            }
            
            DispatchQueue.main.async {
                self?.configureAudioInput()
            }
        }
    }
    
    private func configureAudioInput() {
        guard let audioDevice = AVCaptureDevice.default(for: .audio),
              let audioInput = try? AVCaptureDeviceInput(device: audioDevice) else {
            lastError = "Unable to configure audio input"
            return
        }
        
        captureSession.beginConfiguration()
        
        if captureSession.canAddInput(audioInput) {
            captureSession.addInput(audioInput)
            isConfigured = true
        } else {
            lastError = "Unable to add audio input to session"
        }
        
        captureSession.commitConfiguration()
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
    
    private func updatePoseLandmarker() {
        do {
            options.numPoses = numPoses
            poseLandmarker = try PoseLandmarker(options: options)
        } catch {
            print("Failed to update pose landmarker: \(error)")
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let image = try? MPImage(sampleBuffer: sampleBuffer) else { return }
        frameWidth = Float(image.width)
        frameHeight = Float(image.height)
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
        // if button click, then start timer and start recording
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
    
    func startRPiConnection() {
        isSendingToRPi = true
    }
    
    func stopRPiConnection() {
        isSendingToRPi = false
        sendStopCommand()
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
            
            guard var isSendingToRPi = self?.isSendingToRPi else {
                return
            }
            
            if(self?.poses.count ?? 0 > 0) {
                guard let pose = self?.poses[0] else {
                    print("Failed to unwrap pose")
                    return
                }
                
                // Initialize empty x and y arrays
                var xValues: [Float] = []
                var yValues: [Float] = []
                
                // Go thru each dancer and xy's of each dancer
                for dancer in self!.poses {
                    for xy in dancer {
                        // Add x- and y-values to array
                        xValues.append(xy.x)
                        yValues.append(xy.y)
                    }
                }
                
                // Solve for mins/maxes if not nil
                let xMin: Float = xValues.min()!
                let xMax: Float = xValues.max()!
                let yMin: Float = yValues.min()!
                let yMax: Float = yValues.max()!
                
                let cX: Float = ((xMin + xMax)/2)*frameWidth
                let cY: Float = ((yMin + yMax)/2)*frameHeight
                
                let cW: Float = frameWidth/2
                let cH: Float = frameHeight/2
                
                // let dX: Float = cX - cW
                let dY: Float = cY - cH

                let maxDuty: Float = 100
                let scalingFactor: Float = 10
                var sigmoid: Float = 0
                let deadFactor: Float = 0.075
                let deltaDead: Float = deadFactor*frameHeight
                if (dY < -1 * deltaDead){
                    sigmoid = 1/(1+exp(-(dY+deltaDead)/frameHeight/2*scalingFactor))-0.02
                }
                else if (dY > deltaDead){
                    sigmoid = 1/(1+exp(-(dY-deltaDead)/frameHeight/2*scalingFactor))+0.02
                }
                if sigmoid == 0 {
                    // Stop moving if "negligible" movement
                    if isSendingToRPi { sendStopCommand() }
                } else {
                    let speedY: Int = Int(maxDuty*2*sigmoid-maxDuty)
                    let directionY: String = speedY > 0 ? "forward" : "backward"
                    if isSendingToRPi { sendMoveCommand(command:directionY, speed:abs(speedY)) }
                }
                
            } else {
                // Stop moving if no bodies detected
                if isSendingToRPi { sendStopCommand() }
            }
            
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
