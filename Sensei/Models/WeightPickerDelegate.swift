//
//  WeightPickerDelegate.swift
//  Sensei
//
//  Created by Sauron Black on 6/24/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

enum Mass: Printable {
    case USMass(pounds: Int)
    case MetricMass(kilograms: Int)
    
    var realValue: Double {
        switch self {
            case .USMass(let pounds): return DataFormatter.poundsToKilograms(Double(pounds))
            case .MetricMass(let kilograms): return Double(kilograms)
        }
    }
    
    var description: String {
        switch self {
            case .USMass(let pounds): return "\(pounds) " + Abbreviation.Pounds
            case .MetricMass(let kilograms): return "\(kilograms) " + Abbreviation.Kilograms
        }
    }
}

class WeightPickerDelegate: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {
    
    struct Constants {
        static let MinWeightKg = 11
        static let MaxWeightKg = 227
        static let MinWeightLb = 25
        static let MaxWeightLb = 500
    }
    
    var didChangeValueEvent: ((newWeight: Mass) -> Void)?
    
    func currentValueForPickerView(picker: UIPickerView) -> Mass {
        switch Settings.sharedSettings.dataFormat {
            case .US:
                return Mass.USMass(pounds: Constants.MinWeightLb + picker.selectedRowInComponent(0))
            case .Metric:
                return Mass.MetricMass(kilograms: Constants.MinWeightKg + picker.selectedRowInComponent(0))
        }
    }
    
    // MARK - UIPickerViewDataSource

    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch Settings.sharedSettings.dataFormat {
            case .Metric: return Constants.MaxWeightKg - Constants.MinWeightKg + 1
            case .US: return Constants.MaxWeightLb - Constants.MinWeightLb + 1
        }
    }
    
    // MARK - UIPickerViewDelegate
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        switch Settings.sharedSettings.dataFormat {
            case .Metric: return "\(Constants.MinWeightKg + row) " + Abbreviation.Kilograms
            case .US: return "\(Constants.MinWeightLb + row) " + Abbreviation.Pounds
        }
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if let eventHandler = didChangeValueEvent {
            eventHandler(newWeight: currentValueForPickerView(pickerView))
        }
    }
}
