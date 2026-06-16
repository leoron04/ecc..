import AVKit
import SwiftUI

struct PlayerPreviewView: View {
    let context: PlayerContext
    @State private var player: AVPlayer?

    var body: some View {
        NavigationStack {
            Group {
                if let player {
                    VideoPlayer(player: player)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(context.title)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                let asset = AVURLAsset(
                    url: context.url,
                    options: ["AVURLAssetHTTPHeaderFieldsKey": context.headers]
                )
                let item = AVPlayerItem(asset: asset)
                let player = AVPlayer(playerItem: item)
                self.player = player
                player.play()
            }
            .onDisappear {
                player?.pause()
                player = nil
            }
        }
    }
}

