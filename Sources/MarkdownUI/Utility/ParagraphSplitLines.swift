import Foundation

enum ParagraphSplitLines {
  struct RenderLine: Equatable {
    let inlines: [InlineNode]
    let isBullet: Bool
  }

  static func shouldRenderSplitLines(_ inlines: [InlineNode]) -> Bool {
    let hasImage = inlines.contains { if case .image = $0 { return true }; return false }
    guard hasImage else { return false }

    let hasBreak = inlines.contains { inline in
      if case .softBreak = inline { return true }
      if case .lineBreak = inline { return true }
      return false
    }
    guard hasBreak else { return false }

    // If there's anything besides images + breaks + whitespace text, we’re in the problematic case.
    let hasNonImageContent = inlines.contains { inline in
      switch inline {
      case .image, .softBreak, .lineBreak:
        return false
      case .text(let t):
        let trimmed = t.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\u{00A0}", with: "")
        return !trimmed.isEmpty
      default:
        return true
      }
    }
    return hasNonImageContent
  }

  static func splitLines(_ inlines: [InlineNode]) -> [RenderLine] {
    var rawLines: [[InlineNode]] = [[]]
    for inline in inlines {
      switch inline {
      case .softBreak, .lineBreak:
        if !rawLines.last!.isEmpty {
          rawLines.append([])
        } else {
          // multiple breaks: keep a single empty line
          continue
        }
      default:
        rawLines[rawLines.count - 1].append(inline)
      }
    }

    // Trim whitespace-only text at the start/end of each line.
    func isIgnorableText(_ inline: InlineNode) -> Bool {
      guard case .text(let t) = inline else { return false }
      let trimmed = t.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\u{00A0}", with: "")
      return trimmed.isEmpty
    }

    // Helper to detect and strip "- " bullet prefix in a .text node.
    func stripDashPrefix(_ t: String) -> String? {
      // Allow leading whitespace (including NBSP) before "- "
      let normalized = t.replacingOccurrences(of: "\u{00A0}", with: " ")
      // Find first non-whitespace index
      let scalars = Array(normalized)
      var i = 0
      while i < scalars.count, scalars[i].isWhitespace { i += 1 }
      guard i + 1 < scalars.count, scalars[i] == "-", scalars[i + 1] == " " else { return nil }
      return String(scalars[(i + 2)...])
    }

    // First, trim whitespace-only boundaries.
    var trimmedLines: [[InlineNode]] = rawLines.compactMap { line in
      var l = line
      while let first = l.first, isIgnorableText(first) { l.removeFirst() }
      while let last = l.last, isIgnorableText(last) { l.removeLast() }
      return l.isEmpty ? nil : l
    }

    // Second, split a line like: [strong(...), text("- ...")] into:
    //   1) [strong(...)] (plain)
    //   2) [text("...")] (bullet)
    var expanded: [RenderLine] = []
    for line in trimmedLines {
      // Find first .text that looks like "- ..."
      if let idx = line.firstIndex(where: {
        guard case .text(let t) = $0 else { return false }
        return stripDashPrefix(t) != nil
      }) {
        // Pre-part (before the dash text)
        let pre = Array(line.prefix(upTo: idx)).filter { !isIgnorableText($0) }
        if !pre.isEmpty {
          expanded.append(.init(inlines: pre, isBullet: false))
        }

        // Bullet-part: strip "- " from that text node, keep any following nodes too
        var bulletPart = Array(line.suffix(from: idx))
        if case .text(let t) = bulletPart.first, let stripped = stripDashPrefix(t) {
          // Render exactly what the markdown source provides (no synthetic "Subtitle:" prefix).
          bulletPart[0] = .text(stripped)
        }
        expanded.append(.init(inlines: bulletPart, isBullet: true))
      } else {
        expanded.append(.init(inlines: line, isBullet: false))
      }
    }

    // Third, if we have any bullet line and an image-only line, treat the image line as bullet too
    // to match the expected "bullet marker beside image" appearance.
    let hasBulletTextLine = expanded.contains { $0.isBullet && $0.inlines.contains(where: { if case .image = $0 { return false }; return true }) }
    if hasBulletTextLine {
      expanded = expanded.map { rl in
        if !rl.isBullet,
           rl.inlines.count == 1,
           rl.inlines.contains(where: { if case .image = $0 { return true }; return false }) {
          return .init(inlines: rl.inlines, isBullet: true)
        }
        return rl
      }
    }

    return expanded
  }
}
