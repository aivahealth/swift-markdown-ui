import SwiftUI
import Foundation
import AivaSDK

struct ImageView: View {
  @SwiftUI.Environment(\.theme.image) private var image
  @SwiftUI.Environment(\.imageProvider) private var imageProvider
  @SwiftUI.Environment(\.imageBaseURL) private var baseURL
  @SwiftUI.Environment(\.imageAction) private var imageAction
  @SwiftUI.Environment(\.markdownLogger) private var logger

  private let data: RawImageData
  
  @State private var loadedImageData: Data?

  init(data: RawImageData) {
    self.data = data
  }

  var body: some View {
    // #region agent log
    let _ = {
      let logMsg = "[H7] ImageView body: url=\(url?.absoluteString ?? "nil"), logger=\(logger != nil ? "present" : "nil")"
      logger?.logInfo(logMsg)
      // Fallback print to ensure we see this even if logger isn't available
      print(logMsg)
    }()
    // #endregion
    self.image.makeBody(
      configuration: .init(
        label: .init(self.label),
        content: .init(block: self.content)
      )
    )
  }

  private var label: some View {
    self.imageProvider.makeImage(url: self.url)
      .imageTapHandler(
        action: self.imageAction,
        destination: self.data.destination,
        imageURL: self.url,
        loadedImageData: self.loadedImageData
      )
      .task(id: self.url) {
        // Load the full-resolution image data for the action callback
        guard let url = self.url else {
          self.loadedImageData = nil
          return
        }
        do {
          let (data, _) = try await URLSession.shared.data(from: url)
          self.loadedImageData = data
        } catch {
          self.loadedImageData = nil
        }
      }
      .accessibilityLabel(self.data.alt)
  }

  private var content: BlockNode {
    if let destination = self.data.destination {
      return .paragraph(
        content: [
          .link(
            destination: destination,
            children: [.image(source: self.data.source, children: [.text(self.data.alt)])]
          )
        ]
      )
    } else {
      return .paragraph(
        content: [.image(source: self.data.source, children: [.text(self.data.alt)])]
      )
    }
  }

  private var url: URL? {
    URL(string: self.data.source, relativeTo: self.baseURL)
  }
}

extension ImageView {
  init?(_ inlines: [InlineNode]) {
    // In markdown lists, an "image-only paragraph" is often indented, which introduces
    // whitespace-only `.text("  ")` nodes around the `.image(...)` node.
    // If we don't ignore those, we fall back to InlineText which renders images as inline glyphs
    // (and can lead to incorrect sizing / overlap).
    let significantInlines = inlines.filter { inline in
      switch inline {
      case .text(let text):
        // Treat NBSP as whitespace too (list indentation sometimes produces it)
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\u{00A0}", with: "")
        return !trimmed.isEmpty
      case .softBreak:
        return false
      case .lineBreak:
        return false
      default:
        return true
      }
    }

    guard significantInlines.count == 1, let data = significantInlines.first?.imageData else {
      // #region agent log
      // This is our "canary" for why image paragraphs fall back to InlineText.
      // Kept intentionally short to avoid log spam.
      if inlines.contains(where: { if case .image = $0 { return true }; return false }) {
        func describe(_ inline: InlineNode) -> String {
          switch inline {
          case .text(let t):
            let trimmed = t.trimmingCharacters(in: .whitespacesAndNewlines)
            let prefix = String(trimmed.prefix(12))
            return "text(len=\(t.count), trimmedLen=\(trimmed.count), prefix=\(prefix.debugDescription))"
          case .softBreak:
            return "softBreak"
          case .lineBreak:
            return "lineBreak"
          case .code(let t):
            return "code(len=\(t.count))"
          case .html(let t):
            let trimmed = t.trimmingCharacters(in: .whitespacesAndNewlines)
            let prefix = String(trimmed.prefix(12))
            return "html(len=\(t.count), trimmedLen=\(trimmed.count), prefix=\(prefix.debugDescription))"
          case .emphasis(let children):
            return "emphasis(children=\(children.count))"
          case .strong(let children):
            return "strong(children=\(children.count))"
          case .strikethrough(let children):
            return "strikethrough(children=\(children.count))"
          case .link:
            return "link"
          case .image:
            return "image"
          case .video:
            return "video"
          }
        }

        let allDesc = inlines.map(describe).joined(separator: ", ")
        let sigDesc = significantInlines.map(describe).joined(separator: ", ")
        print("[IV0] ImageView init? rejected: inlines=\(inlines.count), significant=\(significantInlines.count), all=[\(allDesc)], significant=[\(sigDesc)]")
      }
      // #endregion
      return nil
    }

    self.init(data: data)
  }
}

extension View {
  fileprivate func imageTapHandler(
    action: ImageAction?,
    destination: String?,
    imageURL: URL?,
    loadedImageData: Data?
  ) -> some View {
    self.modifier(ImageTapModifier(action: action, destination: destination, imageURL: imageURL, loadedImageData: loadedImageData))
  }
}

private struct ImageTapModifier: ViewModifier {
  @SwiftUI.Environment(\.baseURL) private var baseURL
  @SwiftUI.Environment(\.openURL) private var openURL

  let action: ImageAction?
  let destination: String?
  let imageURL: URL?
  let loadedImageData: Data?

  var destinationURL: URL? {
    self.destination.flatMap {
      URL(string: $0, relativeTo: self.baseURL)
    }
  }

  func body(content: Content) -> some View {
    // If there's an imageAction, use it (takes priority)
    if let action = self.action, let imageURL = self.imageURL {
      Button {
        // Pass both the loaded image data and URL to the action
        // If image hasn't loaded yet, load it on-demand
        if let loadedImageData = self.loadedImageData {
          action(loadedImageData, imageURL)
        } else {
          // If image hasn't loaded yet, load it asynchronously
          Task {
            do {
              let (data, _) = try await URLSession.shared.data(from: imageURL)
              await MainActor.run {
                action(data, imageURL)
              }
            } catch {
              // If loading fails, we can't call the action
              // The user should handle this case
            }
          }
        }
      } label: {
        content
      }
      .buttonStyle(.plain)
    }
    // Otherwise, if there's a destination link, use the link behavior
    else if let destinationURL = self.destinationURL {
      Button {
        self.openURL(destinationURL)
      } label: {
        content
      }
      .buttonStyle(.plain)
    }
    // Otherwise, just show the content
    else {
      content
    }
  }
}
