import SwiftUI

class Calculator: ObservableObject {
    @Published var display: String = "0"
    private var currentNumber: Double = 0
    private var storedNumber: Double = 0
    private var currentOperator: String? = nil
    private var shouldResetDisplay: Bool = false

    func input(_ value: String) {
        switch value {
        case "0"..."9", ".":
            if shouldResetDisplay || display == "0" {
                display = value
                shouldResetDisplay = false
            } else {
                display += value
            }
            currentNumber = Double(display) ?? 0

        case "+", "-", "×", "÷":
            storedNumber = currentNumber
            currentOperator = value
            shouldResetDisplay = true

        case "=":
            if let op = currentOperator {
                switch op {
                case "+":
                    currentNumber = storedNumber + currentNumber
                case "-":
                    currentNumber = storedNumber - currentNumber
                case "×":
                    currentNumber = storedNumber * currentNumber
                case "÷":
                    currentNumber = storedNumber / (currentNumber != 0 ? currentNumber : 1) // ゼロ除算防止
                default:
                    break
                }
                display = formatNumber(currentNumber)
                currentOperator = nil
                shouldResetDisplay = true
            }

        case "C":
            display = "0"
            currentNumber = 0
            storedNumber = 0
            currentOperator = nil
            shouldResetDisplay = false

        default:
            break
        }
    }

    private func formatNumber(_ number: Double) -> String {
        if number.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(number))
        } else {
            return String(format: "%.2f", number)
        }
    }
}
