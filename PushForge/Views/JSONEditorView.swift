import SwiftUI
import AppKit

/// A syntax-highlighted JSON editor backed by NSTextView.
/// Provides line numbers, bracket matching, and color-coded tokens.
struct JSONEditorView: NSViewRepresentable {
    @Binding var text: String
    var fontSize: Double

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        let textView = NSTextView()
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.usesFindPanel = true
        textView.drawsBackground = false

        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true

        textView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.textColor = NSColor.textColor

        // Must set documentView before creating the ruler (ruler needs enclosingScrollView)
        scrollView.documentView = textView

        // Line number gutter
        let lineNumberView = LineNumberRulerView(scrollView: scrollView, textView: textView)
        scrollView.verticalRulerView = lineNumberView
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true
        textView.delegate = context.coordinator
        context.coordinator.textView = textView

        // Initial content
        textView.string = text
        context.coordinator.applyHighlighting(to: textView)

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        // Update font size if changed
        let newFont = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        if textView.font != newFont {
            textView.font = newFont
        }

        // Update text only if it differs (avoid cursor jump)
        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            // Restore selection only if ranges are still valid for the new text length
            let length = (text as NSString).length
            let validRanges = selectedRanges.filter { NSMaxRange($0.rangeValue) <= length }
            if !validRanges.isEmpty {
                textView.selectedRanges = validRanges
            }
            context.coordinator.applyHighlighting(to: textView)
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: JSONEditorView
        weak var textView: NSTextView?
        private var isUpdating = false

        init(_ parent: JSONEditorView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard !isUpdating, let textView = notification.object as? NSTextView else { return }
            isUpdating = true
            parent.text = textView.string
            applyHighlighting(to: textView)
            // Refresh line numbers
            (textView.enclosingScrollView?.verticalRulerView as? LineNumberRulerView)?.needsDisplay = true
            isUpdating = false
        }

        func applyHighlighting(to textView: NSTextView) {
            let storage = textView.textStorage!
            let source = storage.string
            let fullRange = NSRange(location: 0, length: storage.length)
            let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua

            storage.beginEditing()

            // Reset to default
            storage.addAttribute(.foregroundColor, value: NSColor.textColor, range: fullRange)
            storage.addAttribute(.font, value: textView.font ?? NSFont.monospacedSystemFont(ofSize: 13, weight: .regular), range: fullRange)

            let colors = JSONColors(isDark: isDark)

            // Strings (keys and values)
            highlightPattern(#""(?:[^"\\]|\\.)*""#, in: source, storage: storage, color: colors.string)

            // Numbers
            highlightPattern(#"(?<=[\s,\[:\{])-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?(?=[\s,\]\}])"#, in: source, storage: storage, color: colors.number)

            // Booleans
            highlightPattern(#"\b(true|false)\b"#, in: source, storage: storage, color: colors.boolean)

            // Null
            highlightPattern(#"\bnull\b"#, in: source, storage: storage, color: colors.null)

            // Braces and brackets
            highlightPattern(#"[\{\}\[\]]"#, in: source, storage: storage, color: colors.brace)

            // Colons and commas (structural)
            highlightPattern(#"[,:]"#, in: source, storage: storage, color: colors.punctuation)

            // Re-apply string coloring to fix brace/punctuation matches inside string values
            highlightPattern(#""(?:[^"\\]|\\.)*""#, in: source, storage: storage, color: colors.string)

            // Color keys differently from string values:
            // A key is a quoted string followed by optional whitespace then colon
            highlightPattern(#""(?:[^"\\]|\\.)*"(?=\s*:)"#, in: source, storage: storage, color: colors.key)

            storage.endEditing()
        }

        private func highlightPattern(_ pattern: String, in source: String, storage: NSTextStorage, color: NSColor) {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
            let fullRange = NSRange(location: 0, length: (source as NSString).length)
            for match in regex.matches(in: source, range: fullRange) {
                storage.addAttribute(.foregroundColor, value: color, range: match.range)
            }
        }
    }
}

// MARK: - Color Theme

private struct JSONColors {
    let key: NSColor
    let string: NSColor
    let number: NSColor
    let boolean: NSColor
    let null: NSColor
    let brace: NSColor
    let punctuation: NSColor

    init(isDark: Bool) {
        if isDark {
            key = NSColor(red: 0.58, green: 0.80, blue: 1.0, alpha: 1.0)    // light blue
            string = NSColor(red: 0.99, green: 0.56, blue: 0.47, alpha: 1.0) // salmon
            number = NSColor(red: 0.82, green: 0.68, blue: 1.0, alpha: 1.0)  // lavender
            boolean = NSColor(red: 1.0, green: 0.80, blue: 0.40, alpha: 1.0) // gold
            null = NSColor.secondaryLabelColor
            brace = NSColor.labelColor
            punctuation = NSColor.tertiaryLabelColor
        } else {
            key = NSColor(red: 0.0, green: 0.33, blue: 0.65, alpha: 1.0)     // navy blue
            string = NSColor(red: 0.77, green: 0.10, blue: 0.09, alpha: 1.0) // red
            number = NSColor(red: 0.44, green: 0.22, blue: 0.72, alpha: 1.0) // purple
            boolean = NSColor(red: 0.65, green: 0.45, blue: 0.0, alpha: 1.0) // dark gold
            null = NSColor.secondaryLabelColor
            brace = NSColor.labelColor
            punctuation = NSColor.tertiaryLabelColor
        }
    }
}

// MARK: - Line Number Ruler

class LineNumberRulerView: NSRulerView {
    private weak var targetTextView: NSTextView?

    init(scrollView: NSScrollView, textView: NSTextView) {
        self.targetTextView = textView
        super.init(scrollView: scrollView, orientation: .verticalRuler)
        self.clientView = textView
        self.ruleThickness = 36

        NotificationCenter.default.addObserver(
            self, selector: #selector(textDidChange(_:)),
            name: NSText.didChangeNotification, object: textView
        )
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func textDidChange(_ notification: Notification) {
        needsDisplay = true
    }

    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView = targetTextView,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer,
              let sv = scrollView else { return }

        let visibleRect = sv.contentView.bounds
        let string = textView.string as NSString
        guard string.length > 0 else { return }
        let font = NSFont.monospacedSystemFont(ofSize: (textView.font?.pointSize ?? 13) * 0.8, weight: .regular)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.tertiaryLabelColor,
        ]

        // Draw background
        NSColor.controlBackgroundColor.withAlphaComponent(0.5).setFill()
        rect.fill()

        let glyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
        let characterRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)

        var lineNumber = 1
        // Count lines before visible range
        string.substring(to: characterRange.location).enumerateLines { _, _ in
            lineNumber += 1
        }

        let visibleString = string.substring(with: characterRange)
        var index = characterRange.location
        var firstLine = true

        for line in visibleString.components(separatedBy: "\n") {
            if !firstLine {
                index += 1 // newline character
            }
            firstLine = false

            let glyphIndex = layoutManager.glyphIndexForCharacter(at: min(index, string.length - 1))
            var lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)
            lineRect.origin.y -= visibleRect.origin.y

            let numStr = "\(lineNumber)" as NSString
            let size = numStr.size(withAttributes: attrs)
            let x = ruleThickness - size.width - 6
            let y = lineRect.origin.y + (lineRect.height - size.height) / 2

            numStr.draw(at: NSPoint(x: x, y: y), withAttributes: attrs)

            lineNumber += 1
            index += line.count
        }
    }
}
