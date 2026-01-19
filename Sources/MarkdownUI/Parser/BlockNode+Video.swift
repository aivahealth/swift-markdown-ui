import Foundation

extension BlockNode {
  /// Converts video images (images with source starting with "video:") back to video nodes
  func convertVideoImages() -> BlockNode {
    switch self {
    case .paragraph(let content):
      return .paragraph(content: content.map { $0.convertVideoImage() })
    case .blockquote(let children):
      return .blockquote(children: children.map { $0.convertVideoImages() })
    case .bulletedList(let isTight, let items):
      return .bulletedList(
        isTight: isTight,
        items: items.map { RawListItem(children: $0.children.map { $0.convertVideoImages() }) }
      )
    case .numberedList(let isTight, let start, let items):
      return .numberedList(
        isTight: isTight,
        start: start,
        items: items.map { RawListItem(children: $0.children.map { $0.convertVideoImages() }) }
      )
    case .taskList(let isTight, let items):
      return .taskList(
        isTight: isTight,
        items: items.map { RawTaskListItem(isCompleted: $0.isCompleted, children: $0.children.map { $0.convertVideoImages() }) }
      )
    case .heading(let level, let content):
      return .heading(level: level, content: content.map { $0.convertVideoImage() })
    case .table(let columnAlignments, let rows):
      return .table(
        columnAlignments: columnAlignments,
        rows: rows.map { RawTableRow(cells: $0.cells.map { RawTableCell(content: $0.content.map { $0.convertVideoImage() }) }) }
      )
    default:
      return self
    }
  }
}

extension InlineNode {
  /// Converts video images (images with alt text starting with "video:") back to video nodes
  func convertVideoImage() -> InlineNode {
    switch self {
    case .image(let source, let children):
      // Check if the alt text starts with "video:" (this is how we mark videos during preprocessing)
      let altText = children.renderPlainText()
      if altText.hasPrefix("video:") {
        // Extract the actual alt text (remove "video:" prefix)
        let actualAlt = String(altText.dropFirst(6)) // "video:".count = 6
        // The source URL is the actual video URL
        return .video(source: source, children: [.text(actualAlt)])
      }
      return self
    case .emphasis(let children):
      return .emphasis(children: children.map { $0.convertVideoImage() })
    case .strong(let children):
      return .strong(children: children.map { $0.convertVideoImage() })
    case .strikethrough(let children):
      return .strikethrough(children: children.map { $0.convertVideoImage() })
    case .link(let destination, let children):
      return .link(destination: destination, children: children.map { $0.convertVideoImage() })
    default:
      return self
    }
  }
}

extension String {
  /// Post-processes markdown to convert ![video:alt](url) back to !video[alt](url)
  func postprocessVideoSyntax() -> String {
    // Pattern: ![video:alt](url)
    // Replace with: !video[alt](url)
    let pattern = #"!\[video:([^\]]+)\]\(([^\)]+)\)"#
    guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
      return self
    }
    
    let mutableString = NSMutableString(string: self)
    let range = NSRange(location: 0, length: mutableString.length)
    
    // Find all matches in reverse order to preserve indices
    let matches = regex.matches(in: mutableString as String, options: [], range: range).reversed()
    
    for match in matches {
      guard match.numberOfRanges >= 3 else { continue }
      let altRange = match.range(at: 1)
      let urlRange = match.range(at: 2)
      
      guard altRange.location != NSNotFound,
            urlRange.location != NSNotFound else {
        continue
      }
      
      let altText = mutableString.substring(with: altRange)
      let urlText = mutableString.substring(with: urlRange)
      
      // Unescape special characters in alt text
      let unescapedAlt = altText.replacingOccurrences(of: "\\[", with: "[").replacingOccurrences(of: "\\]", with: "]")

      // Parse optional poster metadata encoded in alt text
      let (title, poster) = {
        guard let markerRange = unescapedAlt.range(of: "||poster=") else {
          return (unescapedAlt, nil as String?)
        }
        let title = String(unescapedAlt[..<markerRange.lowerBound])
        let poster = String(unescapedAlt[markerRange.upperBound...])
        return (title, poster.isEmpty ? nil : poster)
      }()

      let posterSuffix = poster.map { "{poster=\($0)}" } ?? ""
      let replacement = "!video[\(title)](\(urlText))\(posterSuffix)"
      mutableString.replaceCharacters(in: match.range, with: replacement)
    }
    
    return mutableString as String
  }
  
  /// Pre-processes markdown to convert !video[alt](url) to ![video:alt](url)
  func preprocessVideoSyntax() -> String {
    // Pattern: !video[Alt Text](video_url.mp4)
    // Replace with: ![video:Alt Text](video_url.mp4)
    // Note: We need to match !video that is NOT followed by [ (to avoid matching !video[ which would be invalid)
    // But actually !video[ is what we want, so the pattern is correct
    let pattern = #"!video\[([^\]]+)\]\(([^\)]+)\)\s*(\{[^}]*\})?"#
    guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
      return self
    }
    
    let mutableString = NSMutableString(string: self)
    let range = NSRange(location: 0, length: mutableString.length)
    
    // Find all matches in reverse order to preserve indices
    let matches = regex.matches(in: mutableString as String, options: [], range: range).reversed()
    
    for match in matches {
      guard match.numberOfRanges >= 3 else { continue }
      let altRange = match.range(at: 1)
      let urlRange = match.range(at: 2)
      
      guard altRange.location != NSNotFound,
            urlRange.location != NSNotFound else {
        continue
      }
      
      let altText = mutableString.substring(with: altRange)
      let urlText = mutableString.substring(with: urlRange)

      var poster: String?
      if match.numberOfRanges >= 4 {
        let attrsRange = match.range(at: 3)
        if attrsRange.location != NSNotFound {
          let attrsText = mutableString.substring(with: attrsRange)
          if let posterRange = attrsText.range(of: #"poster\s*=\s*([^\s,}]+)"#, options: .regularExpression) {
            let value = String(attrsText[posterRange])
            if let eqIndex = value.firstIndex(of: "=") {
              poster = String(value[value.index(after: eqIndex)...])
            }
          }
        }
      }
      
      // Escape special characters in alt text for markdown if needed
      var combinedAlt = altText
      if let poster {
        combinedAlt = "\(altText)||poster=\(poster)"
      }
      let escapedAlt = combinedAlt.replacingOccurrences(of: "[", with: "\\[").replacingOccurrences(of: "]", with: "\\]")
      
      let replacement = "![video:\(escapedAlt)](\(urlText))"
      mutableString.replaceCharacters(in: match.range, with: replacement)
    }

    return mutableString as String
  }
}
