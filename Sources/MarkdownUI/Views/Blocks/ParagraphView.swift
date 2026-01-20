import SwiftUI

struct ParagraphView: View {
  @Environment(\.theme.paragraph) private var paragraph

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
    if let videoView = VideoView(content) {
      videoView
    } else if let imageView = ImageView(content) {
      imageView
    } else if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *),
      let imageFlow = ImageFlow(content)
    {
      imageFlow
    } else if ParagraphSplitLines.shouldRenderSplitLines(content) {
      // We have evidence that some markdown emits paragraphs like:
      //   [strong, text("- ..."), softBreak, image]
      // If we render that as InlineText, the image becomes an inline glyph and can overlap/blow up layout.
      // Instead: split by breaks and render image-only "lines" as block images below the text.
      SplitLinesParagraph(content: content)
    } else {
      InlineText(content)
    }
  }
}

private struct SplitLinesParagraph: View {
  @Environment(\.theme.bulletedListMarker) private var bulletedListMarker
  @Environment(\.listLevel) private var listLevel
  let content: [InlineNode]

  var body: some View {
    let lines = ParagraphSplitLines.splitLines(content)

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

}