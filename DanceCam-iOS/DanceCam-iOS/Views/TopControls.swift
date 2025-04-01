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
    
    // Possible timer options array
    @State var timeSelect = [0, 5, 10, 15]
        
    var body: some View {
        HStack {
            // Button to connect to RPi
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
            // Button to display landmarkers and bounding box
            Button(action: {
                cameraManager.isDisplayingViz.toggle()
            }) {
                Image(systemName: cameraManager.isDisplayingViz ? "eye.fill" : "eye.slash.fill")
                    .foregroundColor(cameraManager.isDisplayingViz ? .yellow : .white)
                    .font(.system(size: 20))
                    .padding(12)
                    .background(.black.opacity(0.4))
                    .clipShape(Circle())
            }
            Spacer()
            
            // Stepper for user to choose number of dancers to be detected (1-10)
            Stepper("\(cameraManager.numPoses) 🕺", value: $cameraManager.numPoses, in: 1...10)
                .onChange(of: cameraManager.numPoses) { oldValue, newValue in
                    cameraManager.numPoses = newValue // Updates number of dancers
                }
                .foregroundColor(.white)
                .frame(width: 140)
                .padding(.top, 6)
                .padding(.bottom, 6)
                .padding(.leading, 10)
                .padding(.trailing, 10)
                .background(.black.opacity(0.4))
                .cornerRadius(16)
            
            Spacer()
            
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
        }
        .padding(.leading, 12)
        .padding(.trailing, 12)
    }
}
