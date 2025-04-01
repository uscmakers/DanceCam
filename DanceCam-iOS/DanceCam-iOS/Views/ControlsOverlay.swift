//
//  ControlsOverlay.swift
//  DanceCam-iOS
//
//  Created by Abby Farhat on 11/25/24.
//

import SwiftUI

struct ControlsOverlay: View {
    @ObservedObject var cameraManager: CameraManager
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                TopControls(cameraManager: cameraManager)
                    .frame(height: 160).offset(y: cameraManager.isRecording ? -200 : 0)
                    .animation(.default, value: cameraManager.isRecording)
                
                Spacer()
                
                BottomControls(cameraManager: cameraManager)
                    .frame(height: 100)
                    .background(.ultraThinMaterial)
                    .padding(.bottom, 20)
            }
            .edgesIgnoringSafeArea(.all)
        }
    }
}
