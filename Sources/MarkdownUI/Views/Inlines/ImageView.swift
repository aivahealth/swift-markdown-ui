import SwiftUI
import Foundation

struct ImageView: View {
  @Environment(\.theme.image) private var image
  @Environment(\.imageProvider) private var imageProvider
  @Environment(\.imageBaseURL) private var baseURL
  @Environment(\.imageAction) private var imageAction

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
    guard inlines.count == 1, let data = inlines.first?.imageData else {
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
  @Environment(\.baseURL) private var baseURL
  @Environment(\.openURL) private var openURL

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
