import NetworkImage
import SwiftUI
import AivaSDK

/// The default image provider, which loads images from the network.
public struct DefaultImageProvider: ImageProvider {
  public func makeImage(url: URL?) -> some View {
    NetworkImageWithLogging(url: url)
  }
}

private struct NetworkImageWithLogging: View {
  @SwiftUI.Environment(\.markdownLogger) private var logger
  let url: URL?
  
  var body: some View {
    // #region agent log
    let _ = {
      let logMsg = "[H0] NetworkImageWithLogging body: url=\(url?.absoluteString ?? "nil"), logger=\(logger != nil ? "present" : "nil")"
      logger?.logInfo(logMsg)
      // Fallback print to ensure we see this even if logger isn't available
      print(logMsg)
    }()
    // #endregion
    NetworkImage(url: url) { state in
      // #region agent log
      let _ = {
        let stateStr: String
        switch state {
        case .empty: stateStr = "empty"
        case .failure: stateStr = "failure"
        case .success(_, let idealSize): stateStr = "success(\(idealSize.width)x\(idealSize.height))"
        }
        logger?.logInfo("[H1] DefaultImageProvider NetworkImage state change: url=\(url?.absoluteString ?? "nil"), state=\(stateStr)")
      }()
      // #endregion
      switch state {
      case .empty, .failure:
        // No placeholder - let it collapse to prevent layout interference
        // The brief collapse during loading is acceptable to avoid incorrect aspect ratio calculations
        Color.clear
          .frame(width: 0, height: 0)
      case .success(let image, let idealSize):
        // #region agent log
        let _ = {
          let logMsg = "[H8] DefaultImageProvider creating ResizeToFit: idealSize=\(idealSize.width)x\(idealSize.height), url=\(url?.absoluteString ?? "nil"), logger=\(logger != nil ? "present" : "nil")"
          logger?.logInfo(logMsg)
          // Fallback print to ensure we see this even if logger isn't available
          print(logMsg)
        }()
        // #endregion
        ResizeToFit(idealSize: idealSize) {
          image.resizable()
        }
      }
    }
  }
}

extension ImageProvider where Self == DefaultImageProvider {
  /// The default image provider, which loads images from the network.
  ///
  /// Use the `markdownImageProvider(_:)` modifier to configure this image provider for a view hierarchy.
  public static var `default`: Self {
    .init()
  }
}
