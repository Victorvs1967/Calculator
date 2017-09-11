import UIKit

class CalculatorViewController: UIViewController {
  
  @IBOutlet weak var display: UILabel!
  @IBOutlet weak var displayDescription: UILabel!
  @IBOutlet weak var point: UIButton! {
    didSet {
      point.setTitle(decimalSeparator, for: .normal)
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
  
  private var brain = CalculatorBrain()
  
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
      displayValue = brain.result
  }
  
  @IBAction func clearAll(_ sender: UIButton) {
    brain.clear()
    display.text = "0"
    displayDescription.text = " "
  }
  
  @IBAction func backspace(_ sender: UIButton) {
    guard userIsInTheMiddleOfTyping && !display.text!.isEmpty else { return }
    display.text = String(display.text!.characters.dropLast())
    if display.text!.isEmpty { displayValue = 0 }
  }
  
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
      displayDescription.text = brain.description! + (brain.resultIsPending ? " ..." : " =")
    }
  }
  
  
}
