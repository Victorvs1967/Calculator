import Foundation

struct CalculatorBrain {
   
   private enum OpStack {
      case operand(Double)
      case operation(String)
      case variable(String)
   }
   
   private var internalProgramm = [OpStack]()
   
   private enum Operation {
      case nullaryOperation(() -> Double, String)
      case constant(Double)
      case unaryOperation((Double) -> Double, ((String) -> String)?)
      case binaryOperation((Double, Double) -> Double, ((String, String) -> String)?)
      case equals
   }
   
   private var operations: Dictionary<String, Operation> = [
      "Ran": Operation.nullaryOperation({ Double(arc4random()) / Double(UInt32.max) }, "rand()"),
      "π": Operation.constant(Double.pi),
      "e": Operation.constant(Double(M_E)),
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
   
   struct PendingBinaryOperation {
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
   
   mutating func setOperand(variable named: String) {
      internalProgramm.append(OpStack.variable(named))
   }
   
   mutating func setOPerand(_ operand: Double) {
      internalProgramm.append(OpStack.operand(operand))
   }
   
   mutating func performOperation(_ symbol: String) {
      internalProgramm.append(OpStack.operation(symbol))
   }
   
   mutating func clear() {
      internalProgramm.removeAll()
   }
   
   mutating func undo() {
      if !internalProgramm.isEmpty {
         internalProgramm = Array(internalProgramm.dropLast())
      }      
   }
   
   func evaluate(using variables: Dictionary<String, Double>? = nil) -> (result: Double?, isPending: Bool, description: String) {
      //evaluated variables
      var cache: (accumulator: Double?, descriptionAccumulator: String?)
      
      var pendingBinaryOperation: PendingBinaryOperation?
      
      var resultIsPending: Bool {
         get {
            return pendingBinaryOperation != nil
         }
      }
      
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
      //evaluated functions
      func setOPerand(_ operand: Double) {
         cache.accumulator = operand
         
         if let value = cache.accumulator {
            cache.descriptionAccumulator = formatter.string(from: NSNumber(value: value)) ?? " "
         }
      }
      
      func setOperand(variable named: String) {
         cache.accumulator = variables?[named] ?? 0
         cache.descriptionAccumulator = named
      }
      
      func performOperation(_ symbol: String) {
         if let operation = operations[symbol] {
            switch operation {
            case .nullaryOperation(let function, let desctiptionValue):
               cache = (function(), desctiptionValue)
            case .constant(let value):
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
                  pendingBinaryOperation = PendingBinaryOperation(function: function,
                                                                  firstOperand: cache.accumulator!,
                                                                  descriptionFunction: descriptionFunction!,
                                                                  descriptionOperand: cache.descriptionAccumulator!)
                  cache = (nil, nil)
               }
            case .equals:
               performPendingBinaryOperation()
            }
         }
      }
      
      func performPendingBinaryOperation() {
         if pendingBinaryOperation != nil && cache.accumulator != nil {
            cache.accumulator = pendingBinaryOperation!.perform(with: cache.accumulator!)
            cache.descriptionAccumulator = pendingBinaryOperation!.performDescription(with: cache.descriptionAccumulator!)
            pendingBinaryOperation = nil
         }
      }
      //evaluate body
      guard !internalProgramm.isEmpty else { return (nil, false, " ") }
      for op in internalProgramm {
         switch op {
         case .operand(let operand):
            setOPerand(operand)
         case .operation(let operation):
            performOperation(operation)
         case .variable(let symbol):
            setOperand(variable: symbol)
         }
      }
      
      return (result, resultIsPending, description ?? " ")
   }
   
   var description: String {
      get {
         return evaluate().description
      }
   }
   
   var result: Double? {
      get {
         return evaluate().result
      }
   }
   
   var resultIsPending: Bool {
      get {
         return evaluate().isPending
      }
   }
   
}

let formatter: NumberFormatter = {
   let formatter = NumberFormatter()
   formatter.numberStyle = .decimal
   formatter.maximumFractionDigits = 6
   formatter.notANumberSymbol = "Error"
   formatter.groupingSeparator = " "
   formatter.locale = Locale.current
   return formatter
}()
