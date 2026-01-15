import SwiftUI
import AivaSDK

struct ResizeToFit<Content>: View where Content: View {
  private let idealSize: CGSize
  private let content: Content

  init(idealSize: CGSize, @ViewBuilder content: () -> Content) {
    self.idealSize = idealSize
    self.content = content()
    // #region agent log
    // Note: Can't access logger here as it's not in environment yet
    // #endregion
  }

  var body: some View {
    // Temporarily use ResizeToFit1 for all iOS versions to enable logging
    // This will help debug the proposal sizes when video markdown is present
    ResizeToFit1(idealSize: self.idealSize, content: self.content)
    // TODO: Re-enable ResizeToFit2 after debugging
    // if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
    //   ResizeToFit2(idealSize: self.idealSize) { self.content }
    // } else {
    //   ResizeToFit1(idealSize: self.idealSize, content: self.content)
    // }
  }
}

// MARK: - Geometry reader based

private struct ResizeToFit1<Content>: View where Content: View {
  @SwiftUI.Environment(\.markdownLogger) private var logger
  @SwiftUI.State private var size: CGSize?

  let idealSize: CGSize
  let content: Content

  var body: some View {
    let aspectRatio = idealSize.width / idealSize.height
    
    // #region agent log
    let _ = {
      let logMsg = "[H2] ResizeToFit1 body: idealSize=\(idealSize.width)x\(idealSize.height), aspectRatio=\(aspectRatio), logger=\(logger != nil ? "present" : "nil")"
      logger?.logInfo(logMsg)
      print(logMsg)
    }()
    // #endregion
    
    self.content
      // Fit to the width proposed by the parent, but cap at 400pt to avoid giant images.
      .aspectRatio(aspectRatio, contentMode: .fit)
      .frame(maxWidth: .infinity, alignment: .leading)
      .frame(maxWidth: 400, alignment: .leading)
      .background(
        GeometryReader { proxy in
          // #region agent log
          let _ = {
            let logMsg = "[H9] ResizeToFit1 final frame size: width=\(proxy.size.width), height=\(proxy.size.height)"
            logger?.logInfo(logMsg)
            print(logMsg)
          }()
          // #endregion
          Color.clear
        }
      )
  }

  private func sizeThatFits(proposal: CGSize) -> CGSize {
    // Always cap at a reasonable screen width to prevent oversized images
    // Most phone screens are ~375-430pt wide, so use 400pt as a safe maximum
    let screenMaxWidth: CGFloat = 400
    
    // Determine the maximum width we should use
    let maxWidth: CGFloat
    if proposal.width > 0 {
      // If proposal width is provided and valid, use it but cap at screen max
      // This prevents huge proposals from causing oversized images
      maxWidth = min(proposal.width, screenMaxWidth, idealSize.width)
    } else {
      // If no proposal width or it's invalid, use screen max
      maxWidth = min(idealSize.width, screenMaxWidth)
    }
    
    // Calculate height based on aspect ratio
    let aspectRatio = idealSize.width / idealSize.height
    return CGSize(width: maxWidth, height: maxWidth / aspectRatio)
  }
}

private struct SizePreference: PreferenceKey {
  static let defaultValue: CGSize? = nil

  static func reduce(value: inout CGSize?, nextValue: () -> CGSize?) {
    value = value ?? nextValue()
  }
}

// MARK: - Layout based

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
private struct ResizeToFit2: Layout {
  let idealSize: CGSize
  
  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    guard let view = subviews.first else {
      return .zero
    }

    // Get the view's intrinsic size first (this should match the loaded image)
    var size = view.sizeThatFits(.unspecified)
    
    // If the view's size is zero or invalid, fall back to idealSize
    if size.width <= 0 || size.height <= 0 {
      size = idealSize
    }
    
    // Use idealSize for aspect ratio to ensure correct proportions
    let aspectRatio = idealSize.width / idealSize.height
    
    // Determine the maximum width we should use
    // Always cap at a reasonable screen width to prevent oversized images
    // Most phone screens are ~375-430pt wide, so use 400pt as a safe maximum
    let screenMaxWidth: CGFloat = 400
    
    // Determine the maximum width we should use
    let maxWidth: CGFloat
    if let proposalWidth = proposal.width, proposalWidth > 0 {
      // If proposal width is provided and valid, use it but cap at screen max
      // This prevents huge proposals from causing oversized images
      maxWidth = min(proposalWidth, screenMaxWidth, idealSize.width)
    } else {
      // If no proposal width or it's invalid, use screen max
      maxWidth = min(idealSize.width, screenMaxWidth)
    }
    
    // Always constrain width to maxWidth to prevent oversized images
    if size.width > maxWidth {
      size.width = maxWidth
      size.height = maxWidth / aspectRatio
    } else if size.width <= 0 {
      // If size is invalid, use maxWidth
      size.width = maxWidth
      size.height = maxWidth / aspectRatio
    }
    
    // Also respect proposal height if provided and it would make the image smaller
    if let proposalHeight = proposal.height, size.height > proposalHeight {
      size.height = proposalHeight
      size.width = proposalHeight * aspectRatio
    }
    
    return size
  }

  func placeSubviews(
    in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
  ) {
    guard let view = subviews.first else { return }
    view.place(at: bounds.origin, proposal: .init(bounds.size))
  }
}
