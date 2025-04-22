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
            
            guard let isSendingToRPi = self?.isSendingToRPi else {
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
                let bodyWidth: Float = (xMax-xMin)*frameWidth
                let bodyHeight: Float = (yMax-yMin)*frameHeight
                let bodyArea: Float = bodyWidth*bodyHeight
                
                // Repeat for torso points only
                var xTorsoValues: [Float] = []
                var yTorsoValues: [Float] = []
                for dancer in self!.poses {
                    for xy in [dancer[12], dancer[11], dancer[24], dancer[23]] {
                        xTorsoValues.append(xy.x)
                        yTorsoValues.append(xy.y)
                    }
                }
                let xTorsoMin: Float = xTorsoValues.min()!
                let xTorsoMax: Float = xTorsoValues.max()!
                let yTorsoMin: Float = yTorsoValues.min()!
                let yTorsoMax: Float = yTorsoValues.max()!
                let torsoWidth: Float = (xTorsoMax-xTorsoMin)*frameWidth
                let torsoHeight: Float = (yTorsoMax-yTorsoMin)*frameHeight
                let torsoArea: Float = torsoWidth*torsoHeight
                
                let frameArea: Float = frameWidth*frameHeight
                let areaRatio: Float = torsoArea/frameArea
                
                let pX: Float = ((xMin + xMax)/2)*frameWidth
                let pY: Float = ((yMin + yMax)/2)*frameHeight
                
                let cX: Float = frameWidth/2
                let cY: Float = frameHeight/2
                                               
                let dY: Float = pY - cY
                
                let maxDuty: Float = 100
                var dutyX: Float = 0 // Movement differential on left-right axis
                var dutyY: Float = 0 // Movement differential on forward-backward axis
                let scalingFactorXPos: Float = 6
                let scalingFactorXNeg: Float = 12
                let threshRatioX: Float = 0.05
                let deadRatioX: Float = 0.01
                let threshRangeX: Float = 0.04
                let scalingFactorY: Float = 25
                let deadFactorY: Float = 0.075
                let deltaDeadY: Float = deadFactorY*frameHeight
                
                var speedX: Int = 0
                var speedY: Int = 0
                
                if (dY < -1 * deltaDeadY){
                    dutyY = 1/(1+exp(-(dY+deltaDeadY)/frameHeight/2*scalingFactorY))-0.02
                }
                else if (dY > deltaDeadY){
                    dutyY = 1/(1+exp(-(dY-deltaDeadY)/frameHeight/2*scalingFactorY))+0.02
                }
                
                if (areaRatio > threshRatioX+deadRatioX){
                    dutyX = 1/(1+exp(-(areaRatio-threshRatioX)/threshRangeX*scalingFactorXPos))-0.02
                }
                else if (areaRatio < threshRatioX-deadRatioX){
                    dutyX = 1/(1+exp(-(areaRatio-threshRatioX)/threshRangeX*scalingFactorXNeg))+0.02
                }

                speedX = max(-100, min(100, Int(maxDuty*2*dutyX-maxDuty)))
                speedY = Int(maxDuty*2*dutyY-maxDuty)
                
                if (dutyX == 0 && dutyY == 0) {
                    if isSendingToRPi {sendStopCommand()}
                }
                else if (dutyY != 0) {
                    let directionY: String = speedY > 0 ? "backward" : "forward"
                    if isSendingToRPi { sendMoveCommand(command:directionY, speed:abs(speedY)) }
                }
                else if (dutyX != 0) {
                    let directionX: String = speedX > 0 ? "right" : "left"
                    if isSendingToRPi { sendMoveCommand(command:directionX, speed:abs(speedX)) }
                }
                else {
                    if isSendingToRPi {sendStopCommand()}
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
