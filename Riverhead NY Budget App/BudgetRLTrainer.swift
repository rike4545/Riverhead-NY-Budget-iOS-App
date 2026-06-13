//
//  BudgetRLTrainer.swift
//  Riverhead NY Budget App
//
//  Lightweight reinforcement-learning calibration stage for budget signals.
//  It runs a deterministic, local contextual-bandit pass over normalized
//  budget features and returns a small adjustment to the neural score.
//

import Foundation

struct BudgetRLTrainingResult {
    let adjustedProbability: Double
    let policyConfidence: Double
    let episodes: Int
}

enum RiverheadBudgetRLTrainer {
    private static let episodes = 42
    private static let learningRate = 0.18

    static func calibrateFundScore(
        neuralProbability: Double,
        reserveGap: Double,
        levyShare: Double,
        drawShare: Double,
        growthRate: Double,
        volatility: Double
    ) -> BudgetRLTrainingResult {
        let features = [
            clamp01(reserveGap),
            clamp01(levyShare),
            clamp01(drawShare * 4.0),
            clamp01(growthRate * 5.0),
            clamp01(volatility)
        ]
        let targetReward = clamp01(
            (features[0] * 0.30)
            + (features[1] * 0.18)
            + (features[2] * 0.25)
            + (features[3] * 0.14)
            + (features[4] * 0.13)
        )

        return train(
            neuralProbability: neuralProbability,
            features: features,
            targetReward: targetReward
        )
    }

    static func calibrateDepartmentScore(
        neuralProbability: Double,
        payrollMismatch: Double,
        nonPersonnelShare: Double,
        thinStaffing: Double,
        missingData: Double,
        budgetScale: Double
    ) -> BudgetRLTrainingResult {
        let features = [
            clamp01(payrollMismatch),
            clamp01(nonPersonnelShare),
            clamp01(thinStaffing),
            clamp01(missingData),
            clamp01(budgetScale)
        ]
        let targetReward = clamp01(
            (features[0] * 0.26)
            + (features[1] * 0.19)
            + (features[2] * 0.20)
            + (features[3] * 0.20)
            + (features[4] * 0.15)
        )

        return train(
            neuralProbability: neuralProbability,
            features: features,
            targetReward: targetReward
        )
    }

    private static func train(
        neuralProbability: Double,
        features: [Double],
        targetReward: Double
    ) -> BudgetRLTrainingResult {
        var policy = Array(repeating: 0.0, count: features.count)
        var value = neuralProbability

        for episode in 0..<episodes {
            let exploration = Double((episode % 7) - 3) * 0.006
            let actionScore = dot(policy, features) + exploration
            let action = actionScore >= 0 ? 1.0 : -1.0
            let predicted = clamp01(value + (action * 0.035))
            let tdError = targetReward - predicted

            for index in policy.indices {
                policy[index] += learningRate * tdError * features[index] * action
            }

            value = clamp01(value + (learningRate * tdError * 0.25))
        }

        let confidence = clamp01(0.58 + (abs(dot(policy, features)) * 0.18))
        let adjusted = clamp01((neuralProbability * 0.72) + (value * 0.28))

        return BudgetRLTrainingResult(
            adjustedProbability: adjusted,
            policyConfidence: confidence,
            episodes: episodes
        )
    }

    private static func dot(_ lhs: [Double], _ rhs: [Double]) -> Double {
        zip(lhs, rhs).reduce(0) { partial, pair in
            partial + (pair.0 * pair.1)
        }
    }

    private static func clamp01(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}
