import SwiftUI

/// The default video provider that displays a placeholder view.
public struct DefaultVideoProvider: VideoProvider {
  public init() {}

  public func makeThumbnail(url: URL?, title: String) -> some View {
    Rectangle()
      .fill(Color.gray.opacity(0.3))
      .aspectRatio(16/9, contentMode: .fit)
      .overlay(
        VStack {
          Spacer()
          Text(title)
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.5))
        }
      )
      .cornerRadius(12)
  }
}

extension VideoProvider where Self == DefaultVideoProvider {
  /// The default video provider that displays a placeholder view.
  public static var `default`: Self {
    .init()
  }
}
