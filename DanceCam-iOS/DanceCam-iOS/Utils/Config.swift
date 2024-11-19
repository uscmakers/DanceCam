//
//  Config.swift
//  DanceCam-iOS
//
//  Created by Irith Katiyar on 11/19/24.
//

let MODEL: String = "pose_landmarker_lite" // Set to file name of pretrained model
let MODEL_EXT: String = "task" // Set to file extension of pretrained model

let RUN_MOTOR: Bool = true // Set to true to make requests to server to run motors, false to isolate iOS app from physical system

let DRAW_LANDMARKS: Bool = true // Set to true to draw landmarks for each detected body on view, false to not draw landmarks
let DRAW_BBOX: Bool = true // Set to true to draw bounding box for each detected body on view, false to not draw bounding box
