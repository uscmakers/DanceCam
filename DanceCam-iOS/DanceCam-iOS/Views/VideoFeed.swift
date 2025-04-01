//
//  VideoFeed.swift
//  DanceCam-iOS
//
//  Created by Abby Farhat on 11/18/24.
//

import SwiftUI
import AVFoundation

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

// MARK: - Main View
struct VideoFeed: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var numDancers = 1
    
    var body: some View {
        ZStack {
            CameraPreview(session: cameraManager.captureSession)
                .edgesIgnoringSafeArea(.all)
            
            PoseVisualization(
                poses: cameraManager.poses,
                size: UIScreen.main.bounds.size,
                currentPosition: cameraManager.currentPosition,
                shouldDisplay: cameraManager.isDisplayingViz
            )
        }.overlay(
            ControlsOverlay(cameraManager: cameraManager)
        )
    }
}
