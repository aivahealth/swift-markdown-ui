import MarkdownUI
import SwiftUI

struct ImagesView: View {
  private let content = """
    You can display an image by adding `!` and wrapping the alt text in `[ ]`.
    Then wrap the link for the image in parentheses `()`.

    ```
    ![This is an image](https://picsum.photos/id/91/400/300)
    ```

    ![This is an image](https://picsum.photos/id/91/400/300)

    ― Photo by Jennifer Trovato
    """

  private let inlineImageContent = """
    You can also insert images in a line of text, such as
    ![](https://picsum.photos/id/237/50/25) or
    ![](https://picsum.photos/id/433/50/25).

    ```
    You can also insert images in a line of text, such as
    ![](https://picsum.photos/id/237/50/25) or
    ![](https://picsum.photos/id/433/50/25).
    ```

    Note that MarkdownUI **cannot** apply any styling to
    inline images.

    ― Photos by André Spieker and Thomas Lefebvre
    """

  @State private var lastTappedImageURL: URL?
  @State private var lastTappedImageData: Data?
  @State private var showingFullScreenImage = false

  var body: some View {
    DemoView {
      Markdown(self.content)
        .markdownImageAction { imageData, url in
          self.lastTappedImageURL = url
          self.lastTappedImageData = imageData
          self.showingFullScreenImage = true
          print("Image tapped: \(url), size: \(imageData.count) bytes")
        }

      if let url = self.lastTappedImageURL, let imageData = self.lastTappedImageData {
        Section("Last Tapped Image") {
          Text("URL: \(url.absoluteString)")
            .font(.caption)
            .foregroundColor(.secondary)
          Text("Image Data Size: \(ByteCountFormatter.string(fromByteCount: Int64(imageData.count), countStyle: .file))")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }

      Section("Inline images") {
        Markdown(self.inlineImageContent)
          .markdownImageAction { imageData, url in
            print("Inline image tapped: \(url), size: \(imageData.count) bytes")
          }
      }

      Section("Customization Example") {
        Markdown(self.content)
          .markdownImageAction { imageData, url in
            print("Custom styled image tapped: \(url), size: \(imageData.count) bytes")
          }
      }
      .markdownBlockStyle(\.image) { configuration in
        configuration.label
          .clipShape(RoundedRectangle(cornerRadius: 8))
          .shadow(radius: 8, y: 8)
          .markdownMargin(top: .em(1.6), bottom: .em(1.6))
      }
    }
    .fullScreenCover(isPresented: $showingFullScreenImage) {
      if let imageData = self.lastTappedImageData {
        FullScreenImageView(imageData: imageData)
      }
    }
  }
}

#if canImport(UIKit)
import UIKit

struct FullScreenImageView: View {
  let imageData: Data
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    NavigationView {
      if let uiImage = UIImage(data: imageData) {
        Image(uiImage: uiImage)
          .resizable()
          .scaledToFit()
          .navigationTitle("Full Screen Image")
          .navigationBarTitleDisplayMode(.inline)
          .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
              Button("Done") {
                dismiss()
              }
            }
          }
      } else {
        Text("Failed to load image")
          .navigationTitle("Full Screen Image")
          .navigationBarTitleDisplayMode(.inline)
          .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
              Button("Done") {
                dismiss()
              }
            }
          }
      }
    }
  }
}
#elseif canImport(AppKit)
import AppKit

struct FullScreenImageView: View {
  let imageData: Data
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    if let nsImage = NSImage(data: imageData) {
      Image(nsImage: nsImage)
        .resizable()
        .scaledToFit()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
          ToolbarItem(placement: .automatic) {
            Button("Done") {
              dismiss()
            }
          }
        }
    } else {
      Text("Failed to load image")
    }
  }
}
#endif

struct ImagesView_Previews: PreviewProvider {
  static var previews: some View {
    ImagesView()
  }
}
