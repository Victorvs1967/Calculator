//
//  ViewController.swift
//  Calculator
//
//  Created by Victor Smirnov on 25/07/2017.
//  Copyright © 2017 Victor Smirnov. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  
  @IBOutlet weak var display: UILabel!
  @IBOutlet weak var displayDescription: UILabel!
  
  var userIsInTheMiddleOfTyping = false
  
  var operationSimbol: String!
  
  var pointPresented: Bool {
    get {
      return display.text!.contains(".")
    }
  }
  
  var displayValue: Double {
    get {
      return Double(display.text!)!
    }
    set {
      display.text = String(newValue)
    }
  }
  
  @IBAction func touchDigit(_ sender: UIButton) {
    let digit = sender.currentTitle!
    if userIsInTheMiddleOfTyping {
      if !pointPresented {
        display.text = display.text! + digit
      } else if digit != "." {
        display.text = display.text! + digit
      }
    } else {
      display.text = digit == "." ? "0." : digit
      userIsInTheMiddleOfTyping = true
    }
  }
  
  private var brain = CalculatorBrain()
  
  @IBAction func performOperation(_ sender: UIButton) {
    if userIsInTheMiddleOfTyping {
      brain.setOPerand(displayValue)
      displayDescription.text = displayDescription.text! + String(displayValue)
      userIsInTheMiddleOfTyping = false
    }
    if let mathematicalSymbol = sender.currentTitle {
      switch mathematicalSymbol {
      case "C":
        displayDescription.text = " "
      case "=":
        displayDescription.text = displayDescription.text! + " " + mathematicalSymbol
      default:
        displayDescription.text = displayDescription.text! + " " + mathematicalSymbol + " "
      }
      brain.description = displayDescription.text
      brain.performOperation(mathematicalSymbol)
    }
    if let result = brain.result {
      displayValue = result
    }
  }
  
}
