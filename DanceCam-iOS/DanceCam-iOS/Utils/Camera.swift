//
//  Camera.swift
//  DanceCam-iOS
//
//  Created by Abby Farhat on 11/18/24.
//

import MediaPipeTasksVision
import AVFoundation

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
