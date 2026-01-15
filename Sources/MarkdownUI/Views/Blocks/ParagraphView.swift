import SwiftUI

struct ParagraphView: View {
  @Environment(\.theme.paragraph) private var paragraph
  @Environment(\.markdownLogger) private var logger

  private let content: [InlineNode]

  init(content: String) {
    self.init(
      content: [
        .text(content.hasSuffix("\n") ? String(content.dropLast()) : content)
      ]
    )
  }

  init(content: [InlineNode]) {
    self.content = content
  }

  var body: some View {
    self.paragraph.makeBody(
      configuration: .init(
        label: .init(self.label),
        content: .init(block: .paragraph(content: self.content))
      )
    )
  }

  @ViewBuilder private var label: some View {
    // #region agent log
    let _ = {
      let imageCount = content.filter { if case .image = $0 { return true }; return false }.count
      let videoCount = content.filter { if case .video = $0 { return true }; return false }.count
      let linkCount = content.filter { if case .link = $0 { return true }; return false }.count
      logger?.logDebug("[P1] ParagraphView decide: inlines=\(content.count), images=\(imageCount), videos=\(videoCount), links=\(linkCount), logger=\(logger != nil ? "present" : "nil")")
    }()
    // #endregion

    if let videoView = VideoView(content) {
      // #region agent log
      let _ = { logger?.logDebug("[P2] ParagraphView chose VideoView") }()
      // #endregion
      videoView
    } else if let imageView = ImageView(content) {
      // #region agent log
      let _ = { logger?.logDebug("[P2] ParagraphView chose ImageView(single)") }()
      // #endregion
      imageView
    } else if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *),
      let imageFlow = ImageFlow(content)
    {
      // #region agent log
      let _ = { logger?.logDebug("[P2] ParagraphView chose ImageFlow") }()
      // #endregion
      imageFlow
    } else if Self.shouldRenderSplitLines(content) {
      // We have evidence that some markdown emits paragraphs like:
      //   [strong, text("- ..."), softBreak, image]
      // If we render that as InlineText, the image becomes an inline glyph and can overlap/blow up layout.
      // Instead: split by breaks and render image-only "lines" as block images below the text.
      // #region agent log
      let _ = { logger?.logDebug("[P2] ParagraphView chose SplitLines") }()
      // #endregion
      SplitLinesParagraph(content: content)
    } else {
      // #region agent log
      let _ = { logger?.logDebug("[P2] ParagraphView chose InlineText") }()
      // #endregion
      InlineText(content)
    }
  }
}

private extension ParagraphView {
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
}

private struct SplitLinesParagraph: View {
  @Environment(\.markdownLogger) private var logger
  @Environment(\.theme.bulletedListMarker) private var bulletedListMarker
  @Environment(\.listLevel) private var listLevel
  let content: [InlineNode]

  var body: some View {
    let lines = Self.splitLines(content)
    // #region agent log
    let _ = {
      let imageLineCount = lines.filter { line in
        line.inlines.contains(where: { if case .image = $0 { return true }; return false })
      }.count
      let bulletLineCount = lines.filter { $0.isBullet }.count
      logger?.logDebug("[P3] SplitLinesParagraph: lines=\(lines.count), bulletLines=\(bulletLineCount), imageLines=\(imageLineCount)")
    }()
    // #endregion

    VStack(alignment: .leading, spacing: 0) {
      ForEach(lines.indices, id: \.self) { idx in
        let line = lines[idx]
        let needsTopSpacing = idx > 0 && !lines[idx - 1].isBullet && line.isBullet
        if line.isBullet {
          bulletRow(for: line.inlines, addTopSpacing: needsTopSpacing)
        } else {
          plainRow(for: line.inlines)
        }
      }
    }
  }

  @ViewBuilder private func plainRow(for inlines: [InlineNode]) -> some View {
    if let imageView = ImageView(inlines) {
      imageView
    } else if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *),
              let imageFlow = ImageFlow(inlines) {
      imageFlow
    } else {
      InlineText(inlines)
    }
  }

  @ViewBuilder private func bulletRow(for inlines: [InlineNode], addTopSpacing: Bool) -> some View {
    // We are inside a numbered list item. To match MarkdownUI's default
    // disc/circle/square behavior for nested bullets, use listLevel+1.
    let marker = bulletedListMarker
      .makeBody(configuration: .init(listLevel: self.listLevel + 1, itemNumber: 1))
      .textStyleFont()
      .relativeFrame(minWidth: .em(1.5), alignment: .trailing)

    let isImageOnly = inlines.count == 1 && inlines.contains(where: { if case .image = $0 { return true }; return false })

    return TextStyleAttributesReader { attributes in
      let topSpacing = addTopSpacing ? RelativeSize.em(0.35).points(relativeTo: attributes.fontProperties) : 0

      if isImageOnly {
        // For image rows, center the marker vertically relative to the image.
        HStack(alignment: .center, spacing: 8) {
          marker
          plainRow(for: inlines)
        }
        .padding(.top, topSpacing)
      } else {
        // For text rows, align the marker with the first line of text.
        HStack(alignment: .centerOfFirstLine, spacing: 8) {
          marker
          plainRow(for: inlines)
        }
        .padding(.top, topSpacing)
      }
    }
  }

  private struct RenderLine {
    var inlines: [InlineNode]
    var isBullet: Bool
  }

  private static func splitLines(_ inlines: [InlineNode]) -> [RenderLine] {
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

// Note: `VerticalAlignment.centerOfFirstLine` is already defined in `ListItemView.swift`.
