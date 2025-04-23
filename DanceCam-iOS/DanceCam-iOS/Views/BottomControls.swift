//
//  VideoControls.swift
//  DanceCam-iOS
//
//  Created by Abby Farhat on 11/18/24.
//

import SwiftUI
import PhotosUI
import AVFoundation

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
    @ObservedObject var cameraManager: CameraManager
    
    // Timer Variable
    @State private var timer: Timer?
    @State private var timeRemaining = 0
    @State private var timerIsActive = false
    
    // Audio Variable
    @ObservedObject var audioPlayer: AudioPlayer
    
    var isRecording: Bool {
        return cameraManager.isRecording
    }
    
    var body: some View {
        Button(action: {
            if !cameraManager.isRecording {
                if (!timerIsActive) {
                    startTimer()
                } else {
                    stopTimer()
                }
            } else {
                audioPlayer.stopAudio()
                cameraManager.stopRecording()
            }
        }) {
            if timerIsActive {
                Image(systemName: "\(timeRemaining).circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
            }
            else {
                Image(systemName: isRecording ? "stop.circle.fill" : "record.circle")
                    .font(.system(size: 60))
                    .foregroundColor(isRecording ? .red : .white)
            }
        }
    }
    
    private func startTimer() {
        self.timerIsActive = true
        self.timeRemaining = cameraManager.timeRemaining
        self.timer?.invalidate() // Invalidate any existing timer
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            if self.timeRemaining > 1 {
                self.timeRemaining -= 1
            } else {
                t.invalidate()
                cameraManager.startRecording()  // Start the camera recording
                audioPlayer.playAudio()        // Start the audio player
                cameraManager.isRecording = true
                self.timerIsActive = false
            }
        }
    }
    
    private func stopTimer() {
        self.timer?.invalidate()
        self.timerIsActive = false
        self.timeRemaining = 0
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
    @ObservedObject var audioPlayer: AudioPlayer

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
            RecordButton(
                cameraManager: cameraManager,
                audioPlayer: audioPlayer
            )
        }
    }
}
