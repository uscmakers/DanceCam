//
//  SettingsMenu.swift
//  DanceCam-iOS
//
//  Created by Abby Farhat on 4/8/25.
//

import SwiftUI

struct SettingsMenu: View {
    @ObservedObject var cameraManager: CameraManager

    var body: some View {
        List {
            HStack {
                Text("# of People to Track")
                Spacer()
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
            }
        }
    }
}
