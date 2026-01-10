import SwiftUI

extension View {
  /// Sets a custom play button view for videos.
  /// - Parameter playButton: A view builder that returns the custom play button to display.
  /// - Returns: A view that uses the specified play button for itself and its child views.
  public func markdownVideoPlayButton<Button: View>(@ViewBuilder _ playButton: @escaping () -> Button) -> some View {
    self.environment(\.videoPlayButton, AnyView(playButton()))
  }
}

extension EnvironmentValues {
  var videoPlayButton: AnyView? {
    get { self[VideoPlayButtonKey.self] }
    set { self[VideoPlayButtonKey.self] = newValue }
  }
}

private struct VideoPlayButtonKey: EnvironmentKey {
  static let defaultValue: AnyView? = nil
}
