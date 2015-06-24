//
//  DataFormatter.swift
//  Sensei
//
//  Created by Sauron Black on 6/24/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import Foundation

enum DataFormat: String {
    case US = "US"
    case Metric = "METRIC"
}

struct Abbreviation {
    static let Kilograms = "kilos"
    static let Pounds = "lbs"
    static let Centimetres = "cm"
    static let Feet = "'"
    static let Inch = "\""
}

class DataFormatter {
    
    private struct Constants {
        static let USDateFormatString = "MM.dd.yyyy"
        static let MetricDateFormatString = "dd.MM.yyyy"
        static let USTimeFormatString = "hh:mm a"
        static let MetricTimeFormatString = "HH:mm"
        static let USALocaleIdentifier = "en_US"
        static let UKLocaleIdentifier = "en_GB"
    }
    
    static let USMeasureSystemCountryLocale = NSLocale(localeIdentifier: Constants.USALocaleIdentifier)
    static let MetricMeasureSystemCountryLocale = NSLocale(localeIdentifier: Constants.UKLocaleIdentifier)
    
    class var locale: NSLocale {
        switch Settings.sharedSettings.dataFormat {
        case .US:
            return USMeasureSystemCountryLocale
        case .Metric:
            return MetricMeasureSystemCountryLocale
        }
    }
    
    private class var dateFormatter: NSDateFormatter {
        let formatter = NSDateFormatter()
        switch Settings.sharedSettings.dataFormat {
            case .US:
                formatter.dateFormat = Constants.USDateFormatString
            case .Metric:
                formatter.dateFormat = Constants.MetricDateFormatString
        }
        return formatter
    }
    
    private class var timeFormatter: NSDateFormatter {
        let formatter = NSDateFormatter()
        switch Settings.sharedSettings.dataFormat {
            case .US:
                formatter.dateFormat = Constants.USTimeFormatString
            case .Metric:
                formatter.dateFormat = Constants.MetricTimeFormatString
        }
        return formatter
    }
    
    class func centimetersToFeetAndInches(cmValue: Double) -> (Int, Double) {
        let feet = Int(cmValue / 30.48)
        let inches = (cmValue / 30.48 - Double(feet)) * 12.0
        return (feet, inches)
    }
    
    class func feetAndInchToCm(feet: Int, inches: Double) -> Double {
        return Double(feet) * 30.480 + inches * 2.54
    }
    
    class func kilogramsToPounds(kgValue: Double) -> Double {
        return kgValue * 2.2046228
    }
    
    class func poundsToKilograms(lbValue: Double) -> Double {
        return lbValue * 0.4535923
    }
    
    class func stringFromDate(date: NSDate) -> String {
        return dateFormatter.stringFromDate(date)
    }
    
    class func dateFromString(string: String) -> NSDate? {
        return dateFormatter.dateFromString(string)
    }
    
    class func stringFromTime(time: NSDate) -> String {
        return timeFormatter.stringFromDate(time)
    }
    
    class func timeFromString(string: String) -> NSDate? {
        return timeFormatter.dateFromString(string)
    }
}