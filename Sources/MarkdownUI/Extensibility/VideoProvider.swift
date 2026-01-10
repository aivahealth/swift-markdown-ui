import SwiftUI

/// A type that provides a view that displays a video thumbnail in a Markdown view.
///
/// To configure the current video provider for a view hierarchy, use the `markdownVideoProvider(_:)` modifier.
///
/// The following example shows how to configure a custom video provider:
///
/// ```swift
/// Markdown {
///   "!video(My Video)[https://example.com/video.mp4]"
/// }
/// .markdownVideoProvider(MyVideoProvider())
/// ```
public protocol VideoProvider {
  /// A view that displays a video thumbnail.
  associatedtype Body: View

  /// Creates a view that displays the video thumbnail for a given URL.
  ///
  /// The ``Markdown`` views in a view hierarchy where this provider is the current video provider
  /// will call this method for each video in their contents.
  ///
  /// - Parameters:
  ///   - url: The URL of the video.
  ///   - title: The title of the video.
  @ViewBuilder func makeThumbnail(url: URL?, title: String) -> Body
}

struct AnyVideoProvider: VideoProvider {
  private let _makeThumbnail: (URL?, String) -> AnyView

  init<V: VideoProvider>(_ videoProvider: V) {
    self._makeThumbnail = { url, title in
      AnyView(videoProvider.makeThumbnail(url: url, title: title))
    }
  }

  func makeThumbnail(url: URL?, title: String) -> some View {
    self._makeThumbnail(url, title)
  }
}
