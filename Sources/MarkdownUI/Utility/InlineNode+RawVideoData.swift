import Foundation

struct RawVideoData: Hashable {
  var source: String
  var alt: String
}

extension InlineNode {
  var videoData: RawVideoData? {
    switch self {
    case .video(let source, let children):
      return .init(source: source, alt: children.renderPlainText())
    default:
      return nil
    }
  }
}
