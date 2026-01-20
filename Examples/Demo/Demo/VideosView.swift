import MarkdownUI
import SwiftUI

struct VideosView: View {
  private let content = """
    You can display a video by using the `!video[Alt Text](video_url)` syntax.

    ```
    !video[Big Buck Bunny](https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4)
    ```

    !video[Video Example](https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4)

    You can also provide a poster thumbnail with `{poster=...}`:

    ```
    !video[Big Buck Bunny](https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4){poster=https://peach.blender.org/wp-content/uploads/title_anouncement.jpg}
    ```

    !video[Video With Poster](https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4){poster=https://peach.blender.org/wp-content/uploads/title_anouncement.jpg}

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

      Section("Custom Thumbnail Colors") {
        Markdown(self.content)
          .markdownBlockStyle(\.video) { configuration in
            ZStack {
              // Custom thumbnail with configuration colors
              Rectangle()
                .fill(configuration.thumbnailBackgroundColor ?? Color.blue.opacity(0.3))
                .aspectRatio(16/9, contentMode: .fit)
                .overlay(
                  VStack {
                    Spacer()
                    Text(configuration.title)
                      .font(.headline)
                      .foregroundColor(configuration.titleTextColor ?? .yellow)
                      .padding()
                      .frame(maxWidth: .infinity)
                      .background(configuration.titleBackgroundColor ?? Color.red.opacity(0.7))
                  }
                )
                .cornerRadius(12)
              
              // Play button with configuration color
              Image(systemName: "play.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(configuration.playButtonColor ?? .white)
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                .offset(y: -25)
            }
          }
          .markdownVideoAction { url in
            print("Custom thumbnail video tapped: \(url)")
          }
      }
    }
  }
}


struct VideosView_Previews: PreviewProvider {
  static var previews: some View {
    VideosView()
  }
}
