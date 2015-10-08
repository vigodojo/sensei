//
//  HeightPickerDelegate.swift
//  Sensei
//
//  Created by Sauron Black on 6/24/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

enum Length: CustomStringConvertible {
    case USLength(feet: Int, inches: Int)
    case MetricLength(Int)
    
    var realValue: Double {
        switch self {
            case .USLength(let feet, let inches): return DataFormatter.feetAndInchToCm(feet, inches: Double(inches))
            case .MetricLength(let height): return Double(height)
        }
    }
    
    var description: String {
        switch self {
            case .USLength(let feet, let inches): return "\(feet)' \(inches)\""
            case .MetricLength(let height): return "\(height) " + Abbreviation.Centimetres
        }
    }
}

class HeightPickerDelegate: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
    
    struct Constants {
        static let MinHeightCm = 30
        static let MaxHeightCm = 272
        static let MinHeightFt = 1
        static let MaxHeightFt = 8
        static let MinHeightIn = 0
        static let MaxHeightIn = 11
		static let USComponentWidth = CGFloat(70)
		static let MetricComponentWidth = CGFloat(200)
    }
    
    var didChangeValueEvent: ((newHeight: Length) -> Void)?
    
    func currentValueForPickerView(picker: UIPickerView) -> Length {
        switch Settings.sharedSettings.dataFormat {
            case .US:
                let feet = Constants.MinHeightFt + picker.selectedRowInComponent(0)
                let inches = Constants.MinHeightIn + picker.selectedRowInComponent(1)
                return Length.USLength(feet: feet, inches: inches)
            case .Metric:
                return Length.MetricLength(Constants.MinHeightCm + picker.selectedRowInComponent(0))
        }
    }
    
    // MARK - UIPickerViewDataSource
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
         return Settings.sharedSettings.dataFormat == .US ? 2: 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch (Settings.sharedSettings.dataFormat, component) {
            case (.Metric, 0): return Constants.MaxHeightCm - Constants.MinHeightCm + 1
            case (.US, 0): return Constants.MaxHeightFt - Constants.MinHeightFt + 1
            case (.US, 1): return Constants.MaxHeightIn - Constants.MinHeightIn + 1
            default: return 0
        }
    }
    
    // MARK - UIPickerViewDelegate
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch (Settings.sharedSettings.dataFormat, component) {
            case (.Metric, 0): return "\(Constants.MinHeightCm + row) " + Abbreviation.Centimetres
            case (.US, 0): return "\(Constants.MinHeightFt + row)" + Abbreviation.Feet
            case (.US, 1): return "\(Constants.MinHeightIn + row)" + Abbreviation.Inch
            default: return ""
        }
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if let eventHandler = didChangeValueEvent {
            eventHandler(newHeight: currentValueForPickerView(pickerView))
        }
    }

	func pickerView(pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
		return Settings.sharedSettings.dataFormat == .US ? Constants.USComponentWidth : Constants.MetricComponentWidth
	}
}
