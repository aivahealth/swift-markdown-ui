import SwiftUI
import Foundation
import AivaSDK

extension View {
  /// Sets the logger for the Markdown components in a view hierarchy.
  /// - Parameter logger: An optional logger instance. If `nil`, logging will be disabled.
  /// - Returns: A view that uses the specified logger for itself and its child views.
  public func markdownLogger(_ logger: (any Logger)?) -> some View {
    self.environment(\.markdownLogger, logger)
  }
}

extension EnvironmentValues {
  var markdownLogger: (any Logger)? {
    get { self[MarkdownLoggerKey.self] }
    set { self[MarkdownLoggerKey.self] = newValue }
  }
}

private struct MarkdownLoggerKey: EnvironmentKey {
  static let defaultValue: (any Logger)? = nil
}
