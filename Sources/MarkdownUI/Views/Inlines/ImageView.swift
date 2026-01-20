import SwiftUI
import Foundation

struct ImageView: View {
  @SwiftUI.Environment(\.theme.image) private var image
  @SwiftUI.Environment(\.imageProvider) private var imageProvider
  @SwiftUI.Environment(\.imageBaseURL) private var baseURL
  @SwiftUI.Environment(\.imageAction) private var imageAction

  private let data: RawImageData
  
  @State private var loadedImageData: Data?

  init(data: RawImageData) {
    self.data = data
  }

  var body: some View {
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
