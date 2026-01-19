import Foundation

struct RawVideoData: Hashable {
  var source: String
  var alt: String
  var poster: String?
}

private enum VideoAltParser {
  static func parse(_ alt: String) -> (title: String, poster: String?) {
    guard let markerRange = alt.range(of: "||poster=") else {
      return (alt, nil)
    }
    let title = String(alt[..<markerRange.lowerBound])
    let poster = String(alt[markerRange.upperBound...])
    return (title, poster.isEmpty ? nil : poster)
  }
}

extension InlineNode {
  var videoData: RawVideoData? {
    switch self {
    case .video(let source, let children):
      let rawAlt = children.renderPlainText()
      let parsed = VideoAltParser.parse(rawAlt)
      return .init(source: source, alt: parsed.title, poster: parsed.poster)
    default:
      return nil
    }
  }
}
