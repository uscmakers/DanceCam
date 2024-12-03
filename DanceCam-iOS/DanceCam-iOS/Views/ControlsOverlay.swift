//
//  ControlsOverlay.swift
//  DanceCam-iOS
//
//  Created by Abby Farhat on 11/25/24.
//

import SwiftUI

struct ControlsOverlay: View {
    var cameraManager: CameraManager
    
    var body: some View {
        VStack {
            BottomControls(cameraManager: cameraManager)
            
            Spacer()
            
            TopControls(cameraManager: cameraManager)
        }
    }
}
