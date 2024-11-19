//
//  VideoControls.swift
//  DanceCam-iOS
//
//  Created by Abby Farhat on 11/18/24.
//

import SwiftUI

struct RecordButton: View {
    @StateObject var cameraManager: CameraManager
    
    var body: some View {
        Button(action: {
            if !cameraManager.isRecording {
                cameraManager.startRecording();
            } else {
                cameraManager.stopRecording();
            }
        }) {
            Image(systemName: cameraManager.isRecording  ? "stop.circle.fill" : "record.circle")
                .font(.system(size: 60))
                .foregroundColor(cameraManager.isRecording ? .red : .white)
        }
    }
}

struct FlipCameraButton: View {
    @StateObject var cameraManager: CameraManager
    var disabled: Bool {
        return cameraManager.isFlipping || cameraManager.isRecording
    }
    
    var body: some View {
        Button(action: {
            withAnimation {
                cameraManager.flipCamera()
            }
        }) {
            Image(systemName: "camera.rotate.fill")
                .font(.system(size: 24))
                .foregroundColor(.white)
                .rotationEffect(.degrees(cameraManager.isFlipping ? 180 : 0))
                .padding()
                .background(Circle().fill(Color.black.opacity(0.6)))
        }
        .disabled(disabled).opacity(disabled ? 0.5 : 1)
    }
}

struct VideoControls: View {
    @StateObject public var cameraManager: CameraManager
    
    var body: some View {
        ZStack {
            HStack {
                Spacer()
            }
            
            RecordButton(cameraManager: cameraManager)
            
            HStack {
                Spacer()
                FlipCameraButton(cameraManager: cameraManager)
            }
        }.padding(.all).padding(.bottom, 40)
    }
}
