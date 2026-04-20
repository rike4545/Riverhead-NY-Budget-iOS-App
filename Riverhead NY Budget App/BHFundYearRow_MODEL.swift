//
//  BHFundYearRow.swift
//  Riverhead NY Budget App
//
//  Public model for parsed SUMMARY fund rows used by BudgetHistoryShift.
//
//  Keep this type declared ONCE in the target to avoid redeclaration.
//  Swift 6 • iOS 17+
//

import Foundation

public struct BHFundYearRow: Hashable {
    public let year: Int
    public let fundCode: String
    public let fundName: String
    public let appropriations: Decimal?
    public let estRevenues: Decimal?
    public let appropFundBalance: Decimal?
    public let taxLevy: Decimal?

    public init(
        year: Int,
        fundCode: String,
        fundName: String,
        appropriations: Decimal?,
        estRevenues: Decimal?,
        appropFundBalance: Decimal?,
        taxLevy: Decimal?
    ) {
        self.year = year
        self.fundCode = fundCode
        self.fundName = fundName
        self.appropriations = appropriations
        self.estRevenues = estRevenues
        self.appropFundBalance = appropFundBalance
        self.taxLevy = taxLevy
    }
}
