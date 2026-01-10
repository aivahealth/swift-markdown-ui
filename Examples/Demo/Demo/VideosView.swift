import MarkdownUI
import SwiftUI

struct VideosView: View {
  private let content = """
    You can display a video by using the `!video[Alt Text](video_url)` syntax.

    ```
    !video[Big Buck Bunny](https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4)
    ```

    !video[Video Example](https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4)

    The video will display with a thumbnail and a play button. When the play button is tapped, 
    the video action callback is triggered with the video URL.
    """

  @State private var lastPlayedVideoURL: URL?

  var body: some View {
    DemoView {
      Markdown(self.content)
        .markdownVideoAction { url in
          self.lastPlayedVideoURL = url
          print("Video tapped: \(url)")
        }

      if let url = self.lastPlayedVideoURL {
        Section("Last Played Video") {
          Text("URL: \(url.absoluteString)")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }

      Section("Custom Play Button") {
        Markdown(self.content)
          .markdownVideoPlayButton {
            ZStack {
              Circle()
                .fill(Color.blue)
                .frame(width: 80, height: 80)
              Image(systemName: "play.fill")
                .font(.system(size: 30))
                .foregroundColor(.white)
                .offset(x: 3) // Slight offset to center the play icon
            }
          }
          .markdownVideoAction { url in
            print("Custom button tapped: \(url)")
          }
      }

      Section("Custom Thumbnail Provider") {
        Markdown(self.content)
          .markdownVideoProvider(CustomVideoProvider())
          .markdownVideoAction { url in
            print("Custom thumbnail video tapped: \(url)")
          }
      }
    }
  }
}

struct CustomVideoProvider: VideoProvider {
  func makeThumbnail(url: URL?, title: String) -> some View {
    ZStack {
      // Gradient background
      LinearGradient(
        colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .aspectRatio(16/9, contentMode: .fit)
      
      // Title overlay
      VStack {
        Spacer()
        Text(title)
          .font(.headline)
          .foregroundColor(.white)
          .padding()
          .frame(maxWidth: .infinity)
          .background(Color.black.opacity(0.5))
      }
    }
    .cornerRadius(12)
  }
}

struct VideosView_Previews: PreviewProvider {
  static var previews: some View {
    VideosView()
  }
}
