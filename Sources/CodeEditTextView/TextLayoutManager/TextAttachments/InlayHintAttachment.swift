//
//  InlayHintAttachment.swift
//  CodeEditTextView
//
//  Created by Khan Winter on 4/24/25.
//

import AppKit

/// A ``TextAttachment`` that renders a lightweight, inline hint (ghost text) — for example a type annotation
/// or a parameter name — without modifying the document. It occupies horizontal space equal to its rendered width.
public final class InlayHintAttachment: TextAttachment {
    /// The hint text to display.
    public let text: String
    /// The font used to render the hint.
    public var font: NSFont
    /// The hint's text color.
    public var textColor: NSColor
    /// An optional rounded background behind the hint.
    public var backgroundColor: NSColor?
    /// Padding between the text and the attachment's edges.
    public var padding: NSEdgeInsets
    /// The corner radius of the background.
    public var cornerRadius: CGFloat
    /// Whether the hint's range is currently selected.
    public var isSelected: Bool = false

    private var cachedWidth: CGFloat?

    public init(
        text: String,
        font: NSFont,
        textColor: NSColor,
        backgroundColor: NSColor? = nil,
        padding: NSEdgeInsets = NSEdgeInsets(top: 0, left: 4, bottom: 0, right: 4),
        cornerRadius: CGFloat = 3
    ) {
        self.text = text
        self.font = font
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.padding = padding
        self.cornerRadius = cornerRadius
    }

    public var width: CGFloat {
        if let cachedWidth {
            return cachedWidth
        }
        let size = (text as NSString).size(withAttributes: [.font: font])
        let width = ceil(size.width) + padding.left + padding.right
        cachedWidth = width
        return width
    }

    public func draw(in context: CGContext, rect: NSRect) {
        if let backgroundColor {
            context.saveGState()
            context.setFillColor(backgroundColor.cgColor)
            let backgroundRect = rect.insetBy(dx: 0, dy: 1)
            context.addPath(
                CGPath(
                    roundedRect: backgroundRect,
                    cornerWidth: cornerRadius,
                    cornerHeight: cornerRadius,
                    transform: nil
                )
            )
            context.fillPath()
            context.restoreGState()
        }

        let attributed = NSAttributedString(string: text, attributes: [
            .font: font,
            .foregroundColor: textColor
        ])
        let line = CTLineCreateWithAttributedString(attributed)

        context.saveGState()
        context.textMatrix = .init(scaleX: 1, y: -1)
        let baseline = rect.midY - font.capHeight / 2
        context.textPosition = CGPoint(x: rect.minX + padding.left, y: baseline)
        CTLineDraw(line, context)
        context.restoreGState()
    }

    /// Invoking a hint discards it (it is not part of the document).
    public func attachmentAction() -> TextAttachmentAction { .discard }
}
