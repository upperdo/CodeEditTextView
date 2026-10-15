//
//  TextView+MultiCursor.swift
//  CodeEditTextView
//
//  Created by Khan Winter on 6/19/25.
//

import AppKit

extension TextView {
    // MARK: - Select Occurrences

    /// Selects the word under the cursor, or extends the current selection to the next occurrence of
    /// the selected text. Subsequent calls keep adding the following occurrences.
    public func selectNextOccurrence() {
        let text = textStorage.string as NSString

        guard let primary = selectionManager.textSelections.first, !primary.range.isEmpty else {
            // No selection yet: select the word under the cursor.
            guard let caret = selectionManager.textSelections.first?.range.location else { return }
            let wordRange = findWordBoundary(at: caret)
            guard wordRange.length > 0 else { return }
            selectionManager.setSelectedRange(wordRange)
            return
        }

        let query = text.substring(with: primary.range)
        guard !query.isEmpty else { return }

        let searchStart = min(selectionManager.textSelections.map(\.range.max).max() ?? primary.range.max, text.length)
        var found = text.range(
            of: query,
            options: [],
            range: NSRange(location: searchStart, length: text.length - searchStart)
        )
        if found.location == NSNotFound {
            // Wrap around from the start.
            let wrapped = text.range(of: query, options: [], range: NSRange(location: 0, length: searchStart))
            if wrapped.location != NSNotFound {
                found = wrapped
            }
        }
        guard found.location != NSNotFound else { return }
        selectionManager.addSelectedRange(found)
        // Bring the newly added occurrence into view (no-op if it is already visible).
        scrollToRange(found, center: true)
    }

    /// Selects every occurrence of the current selection (or the word under the cursor).
    public func selectAllOccurrences() {
        let text = textStorage.string as NSString

        let query: String
        if let primary = selectionManager.textSelections.first, !primary.range.isEmpty {
            query = text.substring(with: primary.range)
        } else if let caret = selectionManager.textSelections.first?.range.location {
            let wordRange = findWordBoundary(at: caret)
            guard wordRange.length > 0 else { return }
            query = text.substring(with: wordRange)
        } else {
            return
        }

        guard !query.isEmpty else { return }
        let ranges = occurrences(of: query, in: text)
        guard !ranges.isEmpty else { return }
        selectionManager.setSelectedRanges(ranges)
    }

    private func occurrences(of query: String, in text: NSString) -> [NSRange] {
        var result: [NSRange] = []
        var start = 0
        while start < text.length {
            let found = text.range(of: query, options: [], range: NSRange(location: start, length: text.length - start))
            if found.location == NSNotFound {
                break
            }
            result.append(found)
            start = max(found.max, found.location + 1)
        }
        return result
    }

    // MARK: - Add Cursors

    /// Adds a caret on the line above each existing selection, at the same column.
    public func addCursorAbove() {
        addCursors(byLineDelta: -1)
    }

    /// Adds a caret on the line below each existing selection, at the same column.
    public func addCursorBelow() {
        addCursors(byLineDelta: 1)
    }

    private func addCursors(byLineDelta delta: Int) {
        guard let layoutManager else { return }
        var newRanges: [NSRange] = []
        for selection in selectionManager.textSelections {
            let offset = selection.range.location
            guard let line = layoutManager.textLineForOffset(offset),
                  let targetLine = layoutManager.textLineForIndex(line.index + delta) else {
                continue
            }
            let column = min(offset - line.range.location, targetLine.range.length)
            newRanges.append(NSRange(location: targetLine.range.location + column, length: 0))
        }
        for range in newRanges {
            selectionManager.addSelectedRange(range)
        }
        needsDisplay = true
    }
}
