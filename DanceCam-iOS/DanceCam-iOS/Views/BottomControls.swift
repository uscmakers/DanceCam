//
//  VideoControls.swift
//  DanceCam-iOS
//
//  Created by Abby Farhat on 11/18/24.
//

import SwiftUI
import PhotosUI

struct GalleryButton: View {
    var disabled: Bool
    
    var body: some View {
        Button(action: {
            if let url = URL(string: "photos-redirect://") {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            }
        }) {
            Image(systemName: "photo.fill")
                .font(.system(size: 24))
                .foregroundColor(.white)
                .padding()
                .background(Circle().fill(Color.black.opacity(0.6)))
        }
        .disabled(disabled).opacity(disabled ? 0.5 : 1)
    }
}

struct RecordButton: View {
    @StateObject var cameraManager: CameraManager
    
    var isRecording: Bool {
        return cameraManager.isRecording
    }
    
    var body: some View {
        Button(action: {
    
            if !cameraManager.isRecording {
                cameraManager.startRecording();
            } else {
                cameraManager.stopRecording();
            }
        }) {
            Image(systemName: isRecording  ? "stop.circle.fill" : "record.circle")
                .font(.system(size: 60))
                .foregroundColor(isRecording ? .red : .white)
        }
    }
}

struct FlipCameraButton: View {
    @StateObject var cameraManager: CameraManager
    var disabled: Bool
    
    var isFlipping: Bool {
        return cameraManager.isFlipping
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
                .rotationEffect(.degrees(isFlipping ? 180 : 0))
                .padding()
                .background(Circle().fill(Color.black.opacity(0.6)))
        }
        .disabled(disabled).opacity(disabled ? 0.5 : 1)
    }
}

struct BottomControls: View {
    @StateObject var cameraManager: CameraManager
    var disabled: Bool {
        return cameraManager.isRecording || cameraManager.isFlipping
    }
    
    var body: some View {
        ZStack {
            HStack {
                GalleryButton(disabled: disabled)
                    .padding(.leading, 30)
                Spacer()
                FlipCameraButton(cameraManager: cameraManager, disabled: disabled)
                    .padding(.trailing, 30)
            }
            
            RecordButton(cameraManager: cameraManager)
        }
    }
}
