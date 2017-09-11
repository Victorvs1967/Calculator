import Foundation

let formatter: NumberFormatter = {
   let formatter = NumberFormatter()
   formatter.numberStyle = .decimal
   formatter.maximumFractionDigits = 6
   formatter.notANumberSymbol = "Error"
   formatter.groupingSeparator = " "
   formatter.locale = Locale.current
   return formatter
}()

struct CalculatorBrain {
   
   private var cache: (accumulator: Double?, descriptionAccumulator: String?)
   
   var description: String? {
      get {
         if resultIsPending {
            return pendingBinaryOperation!.descriptionFunction(pendingBinaryOperation!.descriptionOperand, cache.descriptionAccumulator ?? "")
         } else {
            return cache.descriptionAccumulator
         }
      }
   }
   
   var result: Double? {
      get {
         return cache.accumulator
      }
   }
   
   private enum Operation {
      case nullaryOperation(() -> Double, String)
      case constant(Double, String)
      case unaryOperation((Double) -> Double, ((String) -> String)?)
      case binaryOperation((Double, Double) -> Double, ((String, String) -> String)?)
      case equals
   }
   
   private var operations: Dictionary<String, Operation> = [
      "Ran": Operation.nullaryOperation({ Double(arc4random()) / Double(UInt32.max) }, "rand()"),
      "π": Operation.constant(Double.pi, Double.pi.description),
      "e": Operation.constant(Double(M_E), Double(M_E).description),
      "√": Operation.unaryOperation(sqrt, nil),
      "x⁻¹": Operation.unaryOperation({ 1 / $0 }, { "(" + $0 + ")" }),
      "x²": Operation.unaryOperation({ $0 * $0 }, { "(" + $0 + ")²" }),
      "cos⁻¹": Operation.unaryOperation(acos, nil),
      "sin⁻¹": Operation.unaryOperation(asin, nil),
      "tan⁻¹": Operation.unaryOperation(atan, nil),
      "cos": Operation.unaryOperation(cos, nil),
      "sin": Operation.unaryOperation(sin, nil),
      "tan": Operation.unaryOperation(tan, nil),
      "ln": Operation.unaryOperation(log, nil),
      "±": Operation.unaryOperation({ -$0 }, nil),
      "eˣ": Operation.unaryOperation(exp, nil),
      "xʸ": Operation.binaryOperation(pow, { $0 + "^" + $1 }),
      "×": Operation.binaryOperation({ $0 * $1 }, nil),
      "÷": Operation.binaryOperation({ $0 / $1 }, nil),
      "+": Operation.binaryOperation({ $0 + $1 }, nil),
      "-": Operation.binaryOperation({ $0 - $1 }, nil),
      "=": Operation.equals
   ]
   
   private struct PendingBinaryOperation {
      let function: (Double, Double) -> Double
      let firstOperand: Double
      var descriptionFunction: (String, String) -> String
      var descriptionOperand: String
      
      func perform(with secondOperand: Double) -> Double {
         return function(firstOperand, secondOperand)
      }
      func performDescription(with secondOperand: String) -> String {
         return descriptionFunction(descriptionOperand, secondOperand)
      }
   }
   
   mutating func setOPerand(_ operand: Double) {
      cache.accumulator = operand
      
      if let value = cache.accumulator {
         cache.descriptionAccumulator = formatter.string(from: NSNumber(value: value))
      }
   }
   
   mutating func performOperation(_ symbol: String) {
      if let operation = operations[symbol] {
         switch operation {
         case .nullaryOperation(let function, let desctiptionValue):
            cache = (function(), desctiptionValue)
         case .constant(let value, _):
            cache = (value, symbol)
         case .unaryOperation(let function, var descriptionFunction):
            if let accumulator = cache.accumulator {
               if descriptionFunction == nil {
                  descriptionFunction = { symbol + "(" + $0 + ")" }
               }
               cache = (function(accumulator), descriptionFunction!(cache.descriptionAccumulator!))
            }
         case .binaryOperation(let function, var descriptionFunction):
            performPendingBinaryOperation()
            if cache.accumulator != nil {
               if descriptionFunction == nil {
                  descriptionFunction = { $0 + " " + symbol + " " + $1 }
               }
               pendingBinaryOperation = PendingBinaryOperation(function: function, firstOperand: cache.accumulator!, descriptionFunction: descriptionFunction!, descriptionOperand: cache.descriptionAccumulator!)
               cache = (nil, nil)
            }
         case .equals:
            performPendingBinaryOperation()
         }
      }
   }
   
   mutating func clear() {
      cache = (nil, nil)
      pendingBinaryOperation = nil
   }
   
   private var pendingBinaryOperation: PendingBinaryOperation?
   
   private mutating func performPendingBinaryOperation() {
      if let pendingBinaryOperation = self.pendingBinaryOperation {
         if let accumulator = cache.accumulator {
            cache = (pendingBinaryOperation.perform(with: accumulator), pendingBinaryOperation.performDescription(with: cache.descriptionAccumulator!))
            self.pendingBinaryOperation = nil
         }
      }
   }
   
   var resultIsPending: Bool {
      get {
         return pendingBinaryOperation != nil
      }
   }
}
