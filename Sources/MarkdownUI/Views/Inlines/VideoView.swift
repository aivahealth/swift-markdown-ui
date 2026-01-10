import SwiftUI

struct VideoView: View {
  @Environment(\.theme.image) private var image
  @Environment(\.videoProvider) private var videoProvider
  @Environment(\.videoAction) private var videoAction
  @Environment(\.videoPlayButton) private var customPlayButton
  @Environment(\.videoPlayButtonTint) private var playButtonTint
  @Environment(\.baseURL) private var baseURL

  private let data: RawVideoData

  init(data: RawVideoData) {
    self.data = data
  }

  var body: some View {
    self.image.makeBody(
      configuration: .init(
        label: .init(self.label),
        content: .init(block: self.content)
      )
    )
  }

  private var label: some View {
    ZStack {
      // Thumbnail from video provider
      self.videoProvider.makeThumbnail(url: self.url, title: self.data.alt)
      
      // Play button overlay - centered
      if let videoAction = self.videoAction, let url = self.url {
        Button {
          videoAction(url)
        } label: {
          self.playButton
        }
        .buttonStyle(.plain)
      } else {
        self.playButton
      }
    }
    .accessibilityLabel(self.data.alt)
  }

  @ViewBuilder
  private var playButton: some View {
    if let customPlayButton = self.customPlayButton {
      customPlayButton
    } else {
      // Default play button
      Image(systemName: "play.circle.fill")
        .font(.system(size: 60))
        .foregroundColor(self.playButtonTint ?? .white)
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }
  }

  private var content: BlockNode {
    .paragraph(
      content: [.video(source: self.data.source, children: [.text(self.data.alt)])]
    )
  }

  private var url: URL? {
    URL(string: self.data.source, relativeTo: self.baseURL)
  }
}

extension VideoView {
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
          let videoData = RawVideoData(source: source, alt: actualAlt)
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
        let videoData = RawVideoData(source: source, alt: actualAlt)
        self.init(data: videoData)
        return
      }
    }
    
    return nil
  }
}
