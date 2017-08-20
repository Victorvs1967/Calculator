//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Victor Smirnov on 28/07/2017.
//  Copyright © 2017 Victor Smirnov. All rights reserved.
//

import Foundation

struct CalculatorBrain {
   
   private enum Operation {
      case constant(Double)
      case unaryOperation((Double) -> Double)
      case binaryOperation((Double, Double) -> Double)
      case equals
      
   }
   
   private struct PendingBinaryOperation {
      let function: (Double, Double) -> Double
      let firstOperand: Double
      func perform(with secondOperand: Double) -> Double {
         return function(firstOperand, secondOperand)
      }
   }
   
   var resultIsPending: Bool {
      get {
         return (pendingBinaryOperation != nil)
      }
   }
   var description: String?
   
   private var accumulator: Double?
   var result: Double? {
      get {
         return accumulator
      }
   }
   
   private var pendingBinaryOperation: PendingBinaryOperation?
   
   private var operations: Dictionary<String, Operation> =
      [
         "π": Operation.constant(Double.pi),
         "e": Operation.constant(Double(M_E)),
         "√": Operation.unaryOperation(sqrt),
         "x²": Operation.unaryOperation({ $0 * $0 }),
         "cos": Operation.unaryOperation(cos),
         "±": Operation.unaryOperation({ -$0 }),
         "×": Operation.binaryOperation({ $0 * $1 }),
         "÷": Operation.binaryOperation({ $0 / $1 }),
         "+": Operation.binaryOperation({ $0 + $1 }),
         "-": Operation.binaryOperation({ $0 - $1 }),
         "=": Operation.equals,
         "C": Operation.unaryOperation({ $0 * 0 })
      ]
   
   mutating func setOPerand(_ operand: Double) {
      accumulator = operand
   }
   
   mutating func performOperation(_ symbol: String) {
      if let operation = operations[symbol] {
         switch operation {
         case .constant(let value):
            accumulator = value
         case .unaryOperation(let function):
            if accumulator != nil {
               accumulator = function(accumulator!)
            }
         case .binaryOperation(let function):
            if accumulator != nil {
               pendingBinaryOperation = PendingBinaryOperation(function: function, firstOperand: accumulator!)
               accumulator = nil
            }
         case .equals:
            performPendingBinaryOperation()
         }
      }
   }
   
   private mutating func performPendingBinaryOperation() {
      if pendingBinaryOperation != nil && accumulator != nil {
         accumulator = pendingBinaryOperation!.perform(with: accumulator!)
         pendingBinaryOperation = nil
      }
   }
   
}
