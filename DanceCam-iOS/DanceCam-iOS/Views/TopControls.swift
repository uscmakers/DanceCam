//
//  VideoControls.swift
//  DanceCam-iOS
//
//  Created by Abby Farhat on 11/18/24.
//

import SwiftUI
import PhotosUI

struct TopControls: View {
    @StateObject var cameraManager: CameraManager
    
    var body: some View {
        ZStack {
            HStack {
                // Left side of the screen
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
                Spacer()
            }
            .padding(.leading)
            
            HStack {
                Spacer()
                // Right side of the screen
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
            }
            .padding(.trailing)
        }
    }
}
