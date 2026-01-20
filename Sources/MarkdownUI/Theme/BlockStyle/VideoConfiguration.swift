import Foundation
import SwiftUI

/// The properties of a Markdown video block.
///
/// The theme ``Theme/video`` block style receives a `VideoConfiguration`
/// input in its `body` closure.
public struct VideoConfiguration {
  /// A type-erased view of a Markdown video block.
  public struct Label: View {
    init<L: View>(_ label: L) {
      self.body = AnyView(label)
    }

    public let body: AnyView
  }

  /// The video block view.
  public let label: Label

  /// The content of the Markdown video block.
  public let content: MarkdownContent

  /// The URL of the video.
  public let videoURL: URL?

  /// The title/alt text of the video.
  public let title: String

  /// The thumbnail background color.
  public let thumbnailBackgroundColor: Color?

  /// The title text color.
  public let titleTextColor: Color?

  /// The title background overlay color.
  public let titleBackgroundColor: Color?

  /// The play button color.
  public let playButtonColor: Color?

  public init(
    label: Label,
    content: MarkdownContent,
    videoURL: URL?,
    title: String,
    thumbnailBackgroundColor: Color?,
    titleTextColor: Color?,
    titleBackgroundColor: Color?,
    playButtonColor: Color?
  ) {
    self.label = label
    self.content = content
    self.videoURL = videoURL
    self.title = title
    self.thumbnailBackgroundColor = thumbnailBackgroundColor
    self.titleTextColor = titleTextColor
    self.titleBackgroundColor = titleBackgroundColor
    self.playButtonColor = playButtonColor
  }
}
