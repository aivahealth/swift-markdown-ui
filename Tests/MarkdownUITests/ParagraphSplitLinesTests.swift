#if os(iOS)
import XCTest

@testable import MarkdownUI

final class ParagraphSplitLinesTests: XCTestCase {
  func testShouldRenderSplitLinesForTextAndImageParagraph() {
    let inlines: [InlineNode] = [
      .strong(children: [.text("Shoulder X-Ray (break)")]),
      .text(" - Original clavicle break"),
      .softBreak,
      .image(source: "https://example.com/237-500x300", children: [.text("image")])
    ]

    XCTAssertTrue(ParagraphSplitLines.shouldRenderSplitLines(inlines))
  }

  func testSplitLinesCreatesBulletTextAndBulletImageLines() {
    let inlines: [InlineNode] = [
      .strong(children: [.text("Shoulder X-Ray (break)")]),
      .text(" - Original clavicle break"),
      .softBreak,
      .image(source: "https://example.com/237-500x300", children: [.text("image")])
    ]

    let lines = ParagraphSplitLines.splitLines(inlines)

    XCTAssertEqual(lines.count, 3)

    // Line 1: title (plain)
    XCTAssertEqual(lines[0].isBullet, false)
    XCTAssertEqual(lines[0].inlines, [.strong(children: [.text("Shoulder X-Ray (break)")])])

    // Line 2: bullet text (dash stripped)
    XCTAssertEqual(lines[1].isBullet, true)
    XCTAssertEqual(lines[1].inlines, [.text("Original clavicle break")])

    // Line 3: image-only line treated as bullet
    XCTAssertEqual(lines[2].isBullet, true)
    XCTAssertEqual(
      lines[2].inlines,
      [.image(source: "https://example.com/237-500x300", children: [.text("image")])]
    )
  }
}
#endif
