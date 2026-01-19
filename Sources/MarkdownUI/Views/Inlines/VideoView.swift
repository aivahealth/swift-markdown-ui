import NetworkImage
import SwiftUI

struct VideoView: View {
  @Environment(\.theme) private var theme
  @Environment(\.videoAction) private var videoAction
  @Environment(\.baseURL) private var baseURL

  private let data: RawVideoData

  init(data: RawVideoData) {
    self.data = data
  }

  var body: some View {
    let configuration = self.makeConfiguration()
    self.theme.video.makeBody(configuration: configuration)
  }

  private func makeConfiguration() -> VideoConfiguration {
    let labelView = self.labelView
    return VideoConfiguration(
      label: .init(labelView),
      content: .init(block: self.content),
      videoURL: self.url,
      title: self.data.alt,
      thumbnailBackgroundColor: self.theme.videoThumbnailBackgroundColor,
      titleTextColor: self.theme.videoTitleTextColor,
      titleBackgroundColor: self.theme.videoTitleBackgroundColor,
      playButtonColor: self.theme.videoPlayButtonColor
    )
  }

  private var labelView: some View {
    ZStack {
      // Built-in thumbnail with theme colors
      self.thumbnail
      
      // Play button overlay - centered, but offset up to account for title overlay at bottom
      if let videoAction = self.videoAction, let url = self.url {
        Button {
          videoAction(url)
        } label: {
          self.playButton
        }
        .buttonStyle(.plain)
        .offset(y: -25) // Offset up to account for title overlay at bottom
      } else {
        self.playButton
          .offset(y: -25) // Offset up to account for title overlay at bottom
      }
    }
    .accessibilityLabel(self.data.alt)
  }

  private var thumbnail: some View {
    Rectangle()
      .fill(self.theme.videoThumbnailBackgroundColor ?? Color.gray.opacity(0.3))
      .aspectRatio(16/9, contentMode: .fit)
      .overlay(self.posterOverlay)
      .overlay(
        VStack {
          Spacer()
          Text(self.data.alt)
            .font(.headline)
            .foregroundColor(self.theme.videoTitleTextColor ?? .white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(self.theme.videoTitleBackgroundColor ?? Color.black.opacity(0.5))
        }
      )
      .cornerRadius(12)
  }

  @ViewBuilder
    private var playButton: some View {
        Image(systemName: "play.circle.fill")
            .font(.system(size: 60))
            .foregroundColor(self.theme.videoPlayButtonColor ?? .white)
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }

  private var content: BlockNode {
    .paragraph(
      content: [.video(source: self.data.source, children: [.text(self.data.alt)])]
    )
  }

  private var url: URL? {
    URL(string: self.data.source, relativeTo: self.baseURL)
  }

  private var posterURL: URL? {
    guard let poster = self.data.poster else { return nil }
    return URL(string: poster, relativeTo: self.baseURL)
  }

  @ViewBuilder private var posterOverlay: some View {
    if let posterURL = self.posterURL {
      NetworkImage(url: posterURL) { state in
        switch state {
        case .success(let image, _):
          image.resizable().scaledToFill().clipped()
        case .empty:
          Color.clear
        case .failure:
          Color.clear
        }
      }
      .clipped()
    }
  }
}

extension VideoView {
  private static func parseAlt(_ alt: String) -> (title: String, poster: String?) {
    guard let markerRange = alt.range(of: "||poster=") else {
      return (alt, nil)
    }
    let title = String(alt[..<markerRange.lowerBound])
    let poster = String(alt[markerRange.upperBound...])
    return (title, poster.isEmpty ? nil : poster)
  }

  init?(_ inlines: [InlineNode]) {
    // First, try to find a video node directly
    for inline in inlines {
      if let videoData = inline.videoData {
        self.init(data: videoData)
        return
      }
      
      // Also check for unconverted image nodes with "video:" prefix in alt text
      if case .image(let source, let children) = inline {
        let altText = children.renderPlainText()
        if altText.hasPrefix("video:") {
          let actualAlt = String(altText.dropFirst(6)) // "video:".count = 6
          let parsed = Self.parseAlt(actualAlt)
          let videoData = RawVideoData(source: source, alt: parsed.title, poster: parsed.poster)
          self.init(data: videoData)
          return
        }
      }
    }
    
    // If no video found directly, filter out whitespace and try again
    let significantInlines = inlines.filter { inline in
      switch inline {
      case .text(let text):
        return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      case .softBreak:
        return false
      default:
        return true
      }
    }
    
    // Only create VideoView if there's exactly one significant inline that is a video
    guard significantInlines.count == 1 else {
      return nil
    }
    
    let inline = significantInlines.first!
    
    // Check if it's a video node or an image node that should be a video
    if let videoData = inline.videoData {
      self.init(data: videoData)
      return
    }
    
    if case .image(let source, let children) = inline {
      let altText = children.renderPlainText()
      if altText.hasPrefix("video:") {
        let actualAlt = String(altText.dropFirst(6)) // "video:".count = 6
        let parsed = Self.parseAlt(actualAlt)
        let videoData = RawVideoData(source: source, alt: parsed.title, poster: parsed.poster)
        self.init(data: videoData)
        return
      }
    }
    
    return nil
  }
}
