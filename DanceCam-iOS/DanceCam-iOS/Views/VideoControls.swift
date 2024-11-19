//
//  VideoControls.swift
//  DanceCam-iOS
//
//  Created by Abby Farhat on 11/18/24.
//

import SwiftUI

struct FlipCameraButton: View {
    @ObservedObject var cameraManager: CameraManager
    
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
                .disabled(cameraManager.isFlipping)
        }
    }
}

struct VideoControls: View {
    @StateObject public var cameraManager: CameraManager
    
    var body: some View {
        ZStack {
            HStack {
                Spacer()
            }
            
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

            HStack {
                Spacer()
                FlipCameraButton(cameraManager: cameraManager)
                    .padding(.trailing)
                    .padding(.top)
            }
        }.padding(.all).padding(.bottom, 40)
    }
}
