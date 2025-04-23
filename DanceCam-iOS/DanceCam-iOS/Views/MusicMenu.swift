//
//  MusicMenu.swift
//  DanceCam-iOS
//
//  Created by Abby Farhat on 4/8/25.
//

import SwiftUI
import UniformTypeIdentifiers
import AVFoundation

// AudioPlayer class
class AudioPlayer: ObservableObject {
    @Published var audioFile: URL?
    var onTemplatesDirectoryPicked: (URL) -> Void = { _ in }
    
    private var avPlayer: AVAudioPlayer?

    func playAudio() {
        guard let fileURL = audioFile else { return }
        
        do {
            avPlayer = try AVAudioPlayer(contentsOf: fileURL)
            avPlayer?.play()
        } catch {
            print("Audio error: \(error)")
        }
    }
    
    func stopAudio() {
        avPlayer?.stop()
    }
}

struct MusicMenu: View {
    @ObservedObject var cameraManager: CameraManager
   
    // Audio Variables
    @ObservedObject var audioPlayer: AudioPlayer
    @State private var showFileImporter = false
    
    var body: some View {
        VStack {
            // Button to upload local files for audio
            Button {
                showFileImporter = true
            } label: {
                Label("Upload Music File", systemImage: "square.and.arrow.up")
            }
            
            // Show selected file name
            if let file = audioPlayer.audioFile {
                Text("Selected File: \(file.lastPathComponent)")
                    .font(.caption)
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.audio]
        ) { result in
            switch result {
            case .success(let url):
                let gotAccess = url.startAccessingSecurityScopedResource()
                if gotAccess {
                    audioPlayer.audioFile = url
                    audioPlayer.onTemplatesDirectoryPicked(url)
                }
            case .failure(let error):
                print("File import error: \(error.localizedDescription)")
            }
        }
    }
}
