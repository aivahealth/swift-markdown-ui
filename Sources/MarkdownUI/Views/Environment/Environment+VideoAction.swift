import SwiftUI

/// A closure type for handling video play actions.
public typealias VideoAction = (URL) -> Void

extension View {
  /// Sets the action handler for when a video play button is tapped.
  /// - Parameter action: A closure that receives the video URL when the play button is tapped.
  /// - Returns: A view that uses the specified action handler for itself and its child views.
  public func markdownVideoAction(_ action: @escaping VideoAction) -> some View {
    self.environment(\.videoAction, action)
  }
}

extension EnvironmentValues {
  var videoAction: VideoAction? {
    get { self[VideoActionKey.self] }
    set { self[VideoActionKey.self] = newValue }
  }
}

private struct VideoActionKey: EnvironmentKey {
  static let defaultValue: VideoAction? = nil
}
