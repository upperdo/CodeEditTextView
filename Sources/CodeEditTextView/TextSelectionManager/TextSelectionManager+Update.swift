//
//  TextSelectionManager+Update.swift
//  CodeEditTextView
//
//  Created by Khan Winter on 10/22/23.
//

import Foundation

extension TextSelectionManager {
    public func didReplaceCharacters(in range: NSRange, replacementLength: Int) {
        // Net length change of the edit. A pure replacement changes length by
        // `replacementLength - range.length` (not just `replacementLength`), otherwise selections after
        // the edit drift by the length of the replaced text.
        let delta = replacementLength - range.length
        for textSelection in self.textSelections {
            if textSelection.range.location > range.max {
                // Entirely after the edit: shift it.
                textSelection.range.location = max(0, textSelection.range.location + delta)
                textSelection.range.length = 0
            } else if textSelection.range.intersection(range) != nil
                        || textSelection.range == range
                        || (textSelection.range.isEmpty && textSelection.range.location == range.max) {
                // Overlaps (or sits at the end of) the edit: collapse to the edit's new end.
                if replacementLength > 0 {
                    textSelection.range.location = range.location + replacementLength
                } else {
                    textSelection.range.location = range.location
                }
                textSelection.range.length = 0
            }
            // Otherwise the selection is entirely before the edit; leave it untouched. (Previously this
            // collapsed such selections to zero length, which broke multi-cursor edits by discarding the
            // other selections before their own replacement was applied.)
        }

        // Clean up duplicate selection ranges
        var allRanges: Set<NSRange> = []
        for (idx, selection) in self.textSelections.enumerated().reversed() {
            if allRanges.contains(selection.range) {
                self.textSelections.remove(at: idx)
            } else {
                allRanges.insert(selection.range)
            }
        }
    }

    public func notifyAfterEdit(force: Bool = false) {
        updateSelectionViews(force: force)
        NotificationCenter.default.post(Notification(name: Self.selectionChangedNotification, object: self))
    }
}
