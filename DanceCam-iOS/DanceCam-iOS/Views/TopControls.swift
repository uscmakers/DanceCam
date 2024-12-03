//
//  VideoControls.swift
//  DanceCam-iOS
//
//  Created by Abby Farhat on 11/18/24.
//

import SwiftUI
import PhotosUI

struct TopControls: View {
    var cameraManager: CameraManager?
    
    var body: some View {
        ZStack {            
            HStack {
                Spacer()
            }
            
            Spacer()
            
            HStack {
                Spacer()
            }
        }.background().padding(.all).padding(.top, 40)
    }
}

#Preview {
    TopControls()
}
