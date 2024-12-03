//
//  VideoControls.swift
//  DanceCam-iOS
//
//  Created by Abby Farhat on 11/18/24.
//

import SwiftUI
import PhotosUI

struct GalleryButton: View {
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
    }
}

struct RecordButton: View {
    var cameraManager: CameraManager?
    
    var isRecording: Bool {
        guard let cameraManager
        else {
            return false
        }

        return cameraManager.isRecording
    }
    
    var body: some View {
        Button(action: {
            guard let cameraManager
            else {
                return
            }
            
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
    var cameraManager: CameraManager?
    
    var disabled: Bool {
        guard let cameraManager
        else {
            return false
        }
        
        return cameraManager.isRecording || cameraManager.isFlipping
    }
    var isFlipping: Bool {
        guard let cameraManager
        else {
            return false
        }
        
        return cameraManager.isFlipping
    }
    
    var body: some View {
        Button(action: {
            withAnimation {
                guard let cameraManager
                else {
                    return
                }
                
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
    var cameraManager: CameraManager?
    
    var body: some View {
        ZStack {
            HStack {
                GalleryButton()
                Spacer()
            }
            
            RecordButton(cameraManager: cameraManager)
            
            HStack {
                Spacer()
                FlipCameraButton(cameraManager: cameraManager)
            }
        }.background().padding(.all).padding(.bottom, 40)
    }
}

#Preview {
    BottomControls()
}
