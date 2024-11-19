//
//  Landmarks.swift
//  DanceCam-iOS
//
//  Created by Abby Farhat on 11/18/24.
//

import Foundation

// MARK: - Models
struct Landmark: Identifiable {
    let id = UUID()
    let x: Float
    let y: Float
    let z: Float
    let visibility: Float
    let presence: Float
}
