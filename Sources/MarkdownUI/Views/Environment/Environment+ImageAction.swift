import SwiftUI
import Foundation

/// A closure type for handling image tap actions.
/// - Parameters:
///   - imageData: The full-resolution image data that was loaded (not resized).
///   - url: The URL of the image.
public typealias ImageAction = (Data, URL) -> Void

extension View {
  /// Sets the action handler for when an image is tapped.
  /// - Parameter action: A closure that receives the image URL when the image is tapped.
  /// - Returns: A view that uses the specified action handler for itself and its child views.
  public func markdownImageAction(_ action: @escaping ImageAction) -> some View {
    self.environment(\.imageAction, action)
  }
}

extension EnvironmentValues {
  var imageAction: ImageAction? {
    get { self[ImageActionKey.self] }
    set { self[ImageActionKey.self] = newValue }
  }
}

private struct ImageActionKey: EnvironmentKey {
  static let defaultValue: ImageAction? = nil
}
