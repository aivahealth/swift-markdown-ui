import SwiftUI

/// The properties of a video play button.
///
/// A theme ``BlockStyle`` for video play buttons receives a `VideoPlayButtonConfiguration` input
/// in its `body` closure. The configuration provides the video URL and title.
public struct VideoPlayButtonConfiguration {
  /// The URL of the video.
  public let videoURL: URL?
  
  /// The title/alt text of the video.
  public let title: String
  
  public init(videoURL: URL?, title: String) {
    self.videoURL = videoURL
    self.title = title
  }
}
