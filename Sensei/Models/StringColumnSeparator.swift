//
//  StringColumnSeparator.swift
//  ColumnTextView
//
//  Created by Sauron Black on 7/14/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

class StringColumnSeparator {
    
    var font: UIFont
    var columnSize: CGSize
    
    init(font: UIFont, columnSize: CGSize) {
        self.font = font
        self.columnSize = columnSize
    }
    
    func separateString(string: String) -> [String] {
        var strings = [String]()
        
        let attributes = attributesWithFont(font)
        let attributedString = NSAttributedString(string: string, attributes: attributes)
        let framesetter = CTFramesetterCreateWithAttributedString((attributedString as CFAttributedString))
        
        var location = 0
        var fitCFRange = CFRangeMake(0, 0)
        let stringLength = (string as NSString).length
        while location < stringLength {
            CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(location, 0), nil, columnSize, &fitCFRange)
            let fitRange = NSRangeFromCFRange(fitCFRange)
            let substring = string.substringWithNSRange(fitRange)
            strings.append(substring)
            location = fitRange.location + fitRange.length
        }
        
        return strings
    }
    
    func separateAttributedString(attributedString: NSAttributedString) -> [NSAttributedString] {
        var attributedStrings = [NSAttributedString]()
        
        let framesetter = CTFramesetterCreateWithAttributedString((attributedString as CFAttributedString))
        
        var location = 0
        var fitCFRange = CFRangeMake(0, 0)
        let stringLength = attributedString.length
        while location < stringLength {
            CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(location, 0), nil, columnSize, &fitCFRange)
            let fitRange = NSRangeFromCFRange(fitCFRange)
            let attributedSubstring = attributedString.attributedSubstringFromRange(fitRange)
            attributedStrings.append(attributedSubstring)
            location = fitRange.location + fitRange.length
        }
        
        return attributedStrings
    }
    
    // MARK: - Private
    
    private func attributesWithFont(font: UIFont) -> [String: AnyObject] {
        let font = CTFontCreateWithName(font.fontName, font.pointSize, nil)
        var lineBreakMode = CTLineBreakMode.ByWordWrapping
        let lineBreakModeSet = CTParagraphStyleSetting(spec: CTParagraphStyleSpecifier.LineBreakMode, valueSize: sizeof(CTLineBreakMode), value: &lineBreakMode)
        let paragraphStypeSettings = [lineBreakModeSet]
        let paragraphStyle = CTParagraphStyleCreate(paragraphStypeSettings, paragraphStypeSettings.count);
        return [String(kCTFontAttributeName): font, String(kCTParagraphStyleAttributeName): paragraphStyle]
    }
}

// MARK: - String

extension String {
    
    func rangeFromNSRange(nsRange: NSRange) -> Range<String.Index>? {
		let from16 = utf16.startIndex.advancedBy(nsRange.location, limit: utf16.endIndex)
        if let from = String.Index(from16, within: self),
            let to = String.Index(from16.advancedBy(nsRange.length, limit: utf16.endIndex), within: self) {
                return from ..< to
        }
        return nil
    }
    
    func substringWithNSRange(nsRange: NSRange) -> String {
        if let range = rangeFromNSRange(nsRange) {
            return substringWithRange(range)
        } else {
            return (self as NSString).substringWithRange(nsRange)
        }
    }
}

// MARK: - CFRange - NSRange

func NSRangeFromCFRange(range: CFRange) -> NSRange {
    return NSMakeRange(range.location, range.length)
}
