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
  @SwiftUI.State private var cachedIdealSize: CGSize?
  let url: URL?
  
  var body: some View {
    NetworkImage(url: url) { state in
      // #region agent log
      let _ = {
        let stateStr: String
        switch state {
        case .empty: stateStr = "empty"
        case .failure: stateStr = "failure"
        case .success(_, let idealSize): stateStr = "success(\(idealSize.width)x\(idealSize.height))"
        }
        let cachedSizeStr = cachedIdealSize != nil ? "\(cachedIdealSize!.width)x\(cachedIdealSize!.height)" : "nil"
        logger?.logInfo("[H1] DefaultImageProvider NetworkImage state change: url=\(url?.absoluteString ?? "nil"), state=\(stateStr), cachedIdealSize=\(cachedSizeStr)")
      }()
      // #endregion
      switch state {
      case .empty, .failure:
        // No placeholder - let it collapse to prevent layout interference
        // The brief collapse during loading is acceptable to avoid incorrect aspect ratio calculations
        Color.clear
          .frame(width: 0, height: 0)
      case .success(let image, let idealSize):
        // Cache the ideal size for use in placeholder
        let _ = {
          if cachedIdealSize != idealSize {
            cachedIdealSize = idealSize
          }
        }()
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
