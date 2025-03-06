//
//  PoseVisualization.swift
//  DanceCam-iOS
//
//  Created by Abby Farhat on 11/18/24.
//

import MediaPipeTasksVision
import SwiftUI
import AVFoundation

struct PoseVisualization: View {
    let poses: [[NormalizedLandmark]]
    let size: CGSize
    let currentPosition: AVCaptureDevice.Position
    let shouldDisplay: Bool
    
    var body: some View {
        Canvas { context, size in
            if !shouldDisplay {
                return
            }
            
            var minX: Int = Int(size.width)
            var maxX: Int = 0
            var minY: Int = Int(size.height)
            var maxY: Int = 0
                        
            for dancer in poses {
                for xy in dancer {
                    var pX: Int = Int(xy.y * Float(size.width))
                    let pY: Int = Int(xy.x * Float(size.height))
                    
                    if (currentPosition == .back) {
                        pX = Int(size.width) - pX
                    }
                    
                    minX = min(minX, pX)
                    maxX = max(maxX, pX)
                    minY = min(minY, pY)
                    maxY = max(maxY, pY)
                    
                    let pSize = 10
                    let pRect = CGRect(origin: CGPoint(x: pX, y: pY), size: CGSize(width: pSize, height: pSize))
                    if(DRAW_LANDMARKS) { // Draws points
                        context.fill(Circle().path(in: pRect), with: .color(.blue))
                    }
                    
                }
                
            }
            
            // Draws single bounding box over all dancers
            let bbox = CGRect(origin: CGPoint(x: minX, y: minY), size: CGSize(width: maxX-minX, height: maxY-minY))
            if(DRAW_BBOX){
                context.stroke(Path(bbox), with: .color(.orange), lineWidth: 5)
            }
        }
        .frame(width: size.width, height: size.height)
    }
}
