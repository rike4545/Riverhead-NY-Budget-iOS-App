//
//  SharedFormatters.swift
//  Riverhead NY Budget App
//
//  Formatters are expensive to create: building a NumberFormatter or a
//  DateFormatter loads locale data, and doing it for every value a list draws
//  made scrolling stutter. These are created once and shared. Reading from a
//  formatter (string(from:), date(from:)) is thread-safe; never change one of
//  these after it is made. Add a new one here rather than mutating a shared one.
//

import Foundation

enum SharedFormatters {
    /// Currency in the user's locale, with the locale's usual cents.
    static let currency: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        return f
    }()

    /// Whole dollars: "$1,234".
    static let currency0: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 0
        return f
    }()

    /// Whole US dollars whatever the user's locale: "$1,234".
    static let currency0USD: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 0
        return f
    }()

    /// Dollars and cents: "$1,234.56".
    static let currency2: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f
    }()

    /// A share with up to one decimal: "12.5%".
    static let percent1: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .percent
        f.maximumFractionDigits = 1
        return f
    }()

    /// Fixed-format date parsers for the Town's spreadsheets (US month/day order).
    static let usDateParsers: [DateFormatter] = ["M/d/yy", "M/d/yyyy", "MM/dd/yy", "MM/dd/yyyy"].map { format in
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = format
        return f
    }
}
