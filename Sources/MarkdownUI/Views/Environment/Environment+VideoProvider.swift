import SwiftUI

extension View {
  /// Sets the video provider for the Markdown videos in a view hierarchy.
  /// - Parameter videoProvider: The video provider to set. Use one of the built-in values, like
  ///                            ``VideoProvider/default``, or a custom video provider that you define
  ///                            by creating a type that conforms to the ``VideoProvider`` protocol.
  /// - Returns: A view that uses the specified video provider for itself and its child views.
  public func markdownVideoProvider<V: VideoProvider>(_ videoProvider: V) -> some View {
    self.environment(\.videoProvider, .init(videoProvider))
  }
}

extension EnvironmentValues {
  var videoProvider: AnyVideoProvider {
    get { self[VideoProviderKey.self] }
    set { self[VideoProviderKey.self] = newValue }
  }
}

private struct VideoProviderKey: EnvironmentKey {
  static let defaultValue: AnyVideoProvider = .init(.default)
}
