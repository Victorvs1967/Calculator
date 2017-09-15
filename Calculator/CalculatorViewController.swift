import UIKit

class CalculatorViewController: UIViewController {
  
  @IBOutlet weak var display: UILabel!
  @IBOutlet weak var displayDescription: UILabel!
  @IBOutlet weak var displayM: UILabel!
  @IBOutlet weak var point: UIButton! {
    didSet {
      point.setTitle(decimalSeparator, for: .normal)
    }
  }
  
  private var brain = CalculatorBrain()
  private var variableValues = [String: Double]()
  
  var userIsInTheMiddleOfTyping = false
  var operationSimbol: String!
  let decimalSeparator = formatter.decimalSeparator ?? "."
  
  var pointPresented: Bool {
    get {
      return display.text!.contains(decimalSeparator)
    }
  }
  
  var displayValue: Double? {
    get {
      if let text = display.text, let value = Double(text) {
        return value
      }
      return nil
    }
    set {
      if let value = newValue {
        display.text = formatter.string(from: NSNumber(value: value))
      }
    }
  }
  
  var displayResult: (result: Double?, isPending: Bool, description: String) = (nil, false, " ") {
    didSet {
      displayValue = displayResult.result
      if displayResult.result == nil && displayResult.description == " " {
        displayValue = 0
      }
      displayDescription.text = displayResult.description != " " ? displayResult.description + (displayResult.isPending ? " ..." : " =") : " "
      displayM.text = formatter.string(from: NSNumber(value: variableValues["M"] ?? 0))
    }
  }
  
  @IBAction func touchDigit(_ sender: UIButton) {
    if let digit = sender.currentTitle {
      if userIsInTheMiddleOfTyping {
        if !pointPresented || (digit != decimalSeparator) { display.text! += digit }
      } else {
        display.text = digit == decimalSeparator ? "0" + decimalSeparator : digit
      }
      userIsInTheMiddleOfTyping = true
    }
  }
  
  @IBAction func performOperation(_ sender: UIButton) {
    if userIsInTheMiddleOfTyping {
      // set operand
      if let value = displayValue {
        brain.setOPerand(value)
      }
      userIsInTheMiddleOfTyping = false
    }
    if let mathematicalSymbol = sender.currentTitle {
      brain.performOperation(mathematicalSymbol)
    }
    displayResult = brain.evaluate(using: variableValues)
  }
  
  @IBAction func clearAll(_ sender: UIButton) {
    brain.clear()
    variableValues = [:]
    displayResult = brain.evaluate()
  }
  
  @IBAction func backspace(_ sender: UIButton) {
    if userIsInTheMiddleOfTyping {
      guard !display.text!.isEmpty else { return }
      display.text = String(display.text!.characters.dropLast())
      if display.text!.isEmpty {
        displayValue = 0
        userIsInTheMiddleOfTyping = false
        displayResult = brain.evaluate(using: variableValues)
      }
    } else {
      brain.undo()
      displayResult = brain.evaluate(using: variableValues)
    }
  }
  
  @IBAction func setM(_ sender: UIButton) {
    userIsInTheMiddleOfTyping = false
    let symbol = String(sender.currentTitle!.characters.dropFirst())
    variableValues[symbol] = displayValue
    displayResult = brain.evaluate(using: variableValues)
  }
  
  @IBAction func pushM(_ sender: UIButton) {
    brain.setOperand(variable: sender.currentTitle!)
    displayResult = brain.evaluate(using: variableValues)
  }
}
