import SwiftUI

extension View {
  /// Sets the tint color for the video play button.
  /// - Parameter color: The color to use for the play button.
  /// - Returns: A view that uses the specified tint color for the play button.
  public func markdownVideoPlayButtonTint(_ color: Color?) -> some View {
    self.environment(\.videoPlayButtonTint, color)
  }
}

extension EnvironmentValues {
  var videoPlayButtonTint: Color? {
    get { self[VideoPlayButtonTintKey.self] }
    set { self[VideoPlayButtonTintKey.self] = newValue }
  }
}

private struct VideoPlayButtonTintKey: EnvironmentKey {
  static let defaultValue: Color? = nil
}
