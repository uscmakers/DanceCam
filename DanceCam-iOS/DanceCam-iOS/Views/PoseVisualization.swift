//
//  PoseVisualization.swift
//  DanceCam-iOS
//
//  Created by Abby Farhat on 11/18/24.
//

import MediaPipeTasksVision
import SwiftUI

struct PoseVisualization: View {
    let poses: [[NormalizedLandmark]]
    let size: CGSize
    
    var body: some View {
        Canvas { context, size in
            for pose in poses {
                for landmark in pose {
                    // TODO: visualize
                    // https://ai.google.dev/edge/mediapipe/solutions/vision/pose_landmarker/ios#livestream:~:text=new%20input%20frame.-,Handle%20and%20display%20results,-Upon%20running%20inference
                }
            }
        }
        .frame(width: size.width, height: size.height)
    }
}

#Preview {
    
}
