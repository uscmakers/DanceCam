//
//  VideoControls.swift
//  DanceCam-iOS
//
//  Created by Abby Farhat on 11/18/24.
//

import SwiftUI
import PhotosUI

struct TopControls: View {
    @ObservedObject var cameraManager: CameraManager
    @State private var showingMusic = false
    @State private var showingSettings = false
    
    // Audio Player Variable
    @ObservedObject var audioPlayer: AudioPlayer
    
    // Possible timer options array
    @State var timeSelect = [0, 5, 10, 15]
    
    var body: some View {
        HStack {
            Button(action: {
                showingMusic.toggle()
            }) {
                Image(systemName: "music.note")
                    .font(.system(size: 20))
                    .padding(12)
                    .background(.black.opacity(0.4))
                    .clipShape(Circle())
                    .accentColor(.white)
            }
            
            Picker("cameraManager.timeRemaining", selection: $cameraManager.timeRemaining) {
                Text("0").tag(timeSelect[0])
                Text("5").tag(timeSelect[1])
                Text("10").tag(timeSelect[2])
                Text("15").tag(timeSelect[3])
            }
            .accentColor(.white)
            .frame(height: 45)
            .background(.black.opacity(0.4))
            .clipShape(Circle())
            .sheet(isPresented: $showingMusic) {
                MusicMenu(
                    cameraManager: self.cameraManager,
                    audioPlayer: self.audioPlayer
                )
            }
            .sheet(isPresented: $showingSettings) {
                SettingsMenu(cameraManager: self.cameraManager)
            }
            
            Spacer()
            
            HStack {
                Button(action: {
                    if cameraManager.isSendingToRPi {
                        cameraManager.stopRPiConnection()
                    } else {
                        cameraManager.startRPiConnection()
                    }
                }) {
                    Image(systemName: cameraManager.isSendingToRPi ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                        .foregroundColor(cameraManager.isSendingToRPi ? .yellow : .white)
                        .font(.system(size: 20))
                        .padding(12)
                        .background(.black.opacity(0.4))
                        .clipShape(Circle())
                }
                .padding(.leading)
                
                Button(action: {
                    showingSettings.toggle()
                }) {
                    Image(systemName: "gear")
                        .font(.system(size: 20))
                        .padding(12)
                        .background(.black.opacity(0.4))
                        .clipShape(Circle())
                        .accentColor(.white)
                }
            }

        }
        .padding(.leading, 12)
        .padding(.trailing, 12)
    }
}
