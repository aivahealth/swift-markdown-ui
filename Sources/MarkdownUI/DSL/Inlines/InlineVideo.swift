import Foundation

/// A video in a Markdown content block.
///
/// You can use a video inline to embed a video in a paragraph.
///
/// ```swift
/// Markdown {
///   Paragraph {
///     "A video:"
///   }
///   Paragraph {
///     InlineVideo("My Video", source: URL(string: "https://example.com/video.mp4")!)
///   }
/// }
/// ```
public struct InlineVideo: InlineContentProtocol {
  public var _inlineContent: InlineContent {
    .init(inlines: [.video(source: self.source, children: self.content.inlines)])
  }

  private let source: String
  private let content: InlineContent

  init(source: String, content: InlineContent) {
    self.source = source
    self.content = content
  }

  /// Creates an inline video with the given title and source.
  /// - Parameters:
  ///   - title: The title of the video.
  ///   - source: The absolute or relative path to the video.
  public init(_ title: String, source: URL) {
    self.init(source: source.absoluteString, content: .init(inlines: [.text(title)]))
  }
}
