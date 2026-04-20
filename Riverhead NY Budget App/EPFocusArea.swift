//
//  EPFocusArea.swift
//  Riverhead NY Budget App
//
//  Compatibility aliases.
//  If older code references EPFocusArea / EPUrgency / PolicyAction / FundingProgram,
//  these aliases route to the canonical types in EnergyFocusArea.swift.
//
//  If you are not using the old names, you can remove this file from the target.
//
//  Swift 6 • iOS 17+
//

import SwiftUI
import Foundation

@available(*, deprecated, message: "Use EnergyFocusArea instead.")
public typealias EPFocusArea = EnergyFocusArea

@available(*, deprecated, message: "Use EnergyUrgency instead.")
public typealias EPUrgency = EnergyUrgency

@available(*, deprecated, message: "Use EnergyPolicyAction instead.")
public typealias PolicyAction = EnergyPolicyAction

@available(*, deprecated, message: "Use EnergyFundingProgram instead.")
public typealias FundingProgram = EnergyFundingProgram
