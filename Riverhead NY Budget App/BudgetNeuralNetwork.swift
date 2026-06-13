//
//  BudgetNeuralNetwork.swift
//  Riverhead NY Budget App
//
//  Tiny on-device feed-forward neural networks used to rank budget signals.
//  These are hand-calibrated inference models, not live-trained networks.
//

import Foundation

enum BudgetNNActivation {
    case relu
    case sigmoid
    case linear

    func apply(to value: Double) -> Double {
        switch self {
        case .relu:
            return max(0, value)
        case .sigmoid:
            return 1 / (1 + exp(-value))
        case .linear:
            return value
        }
    }
}

struct BudgetDenseLayer {
    let weights: [[Double]]
    let biases: [Double]
    let activation: BudgetNNActivation

    func forward(_ input: [Double]) -> [Double] {
        guard !weights.isEmpty else { return input }

        return zip(weights, biases).map { row, bias in
            let sum = zip(row, input).reduce(bias) { partial, pair in
                partial + (pair.0 * pair.1)
            }
            return activation.apply(to: sum)
        }
    }
}

struct BudgetNeuralNetwork {
    let layers: [BudgetDenseLayer]

    func predict(_ input: [Double]) -> Double {
        let output = layers.reduce(input) { partial, layer in
            layer.forward(partial)
        }
        return output.first ?? 0
    }
}

enum RiverheadBudgetNeuralSignals {
    static let fundModel = BudgetNeuralNetwork(layers: [
        BudgetDenseLayer(
            weights: [
                [1.60, 1.10, 1.35, 0.85, 0.55],
                [0.25, 1.45, 0.60, 0.95, 0.10],
                [1.20, 0.20, 1.55, 0.15, 0.75],
                [0.95, 0.55, 0.35, 1.40, 0.40],
                [0.20, 0.95, 0.95, 0.25, 1.35],
                [1.10, 0.40, 0.40, 0.90, 0.95]
            ],
            biases: [-0.80, -0.55, -0.70, -0.60, -0.45, -0.50],
            activation: .relu
        ),
        BudgetDenseLayer(
            weights: [
                [0.95, 0.55, 0.90, 0.65, 0.75, 0.70]
            ],
            biases: [-1.20],
            activation: .sigmoid
        )
    ])

    static let departmentModel = BudgetNeuralNetwork(layers: [
        BudgetDenseLayer(
            weights: [
                [1.40, 1.25, 0.60, 0.45, 0.95],
                [0.35, 0.65, 1.30, 0.95, 0.30],
                [0.85, 0.30, 0.45, 1.35, 0.90],
                [1.10, 0.70, 0.25, 0.40, 1.20],
                [0.20, 1.00, 1.05, 0.70, 0.45]
            ],
            biases: [-0.70, -0.55, -0.60, -0.65, -0.45],
            activation: .relu
        ),
        BudgetDenseLayer(
            weights: [
                [0.95, 0.80, 0.60, 0.85, 0.70]
            ],
            biases: [-1.05],
            activation: .sigmoid
        )
    ])

    static func fundProbability(
        reserveGap: Double,
        levyShare: Double,
        drawShare: Double,
        growthRate: Double,
        volatility: Double
    ) -> Double {
        fundModel.predict([
            clamp01(reserveGap),
            clamp01(levyShare),
            clamp01(drawShare * 4.0),
            clamp01(growthRate * 5.0),
            clamp01(volatility)
        ])
    }

    static func departmentProbability(
        payrollMismatch: Double,
        nonPersonnelShare: Double,
        thinStaffing: Double,
        missingData: Double,
        budgetScale: Double
    ) -> Double {
        departmentModel.predict([
            clamp01(payrollMismatch),
            clamp01(nonPersonnelShare),
            clamp01(thinStaffing),
            clamp01(missingData),
            clamp01(budgetScale)
        ])
    }

    private static func clamp01(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}
