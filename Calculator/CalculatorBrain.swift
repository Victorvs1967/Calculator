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
      case unaryOperation((Double) -> Double, ((String) -> String)?, ((Double) -> String?)?)
      case binaryOperation((Double, Double) -> Double, ((String, String) -> String)?, ((Double, Double) -> String?)?, Int)
      case equals
   }
   
   private var operations: Dictionary<String, Operation> = [
      "Ran": Operation.nullaryOperation({ Double(arc4random()) / Double(UInt32.max) }, "rand()"),
      "π": Operation.constant(Double.pi),
      "e": Operation.constant(Double(M_E)),
      "√": Operation.unaryOperation(sqrt, nil, { $0 < 0 ? "negative operand" : nil }),
      "x⁻¹": Operation.unaryOperation({ 1 / $0 }, { "(" + $0 + ")" }, { $0 == 0 ? "divide by zero" : nil }),
      "x²": Operation.unaryOperation({ $0 * $0 }, { "(" + $0 + ")²" }, nil),
      "cos⁻¹": Operation.unaryOperation(acos, nil, nil),
      "sin⁻¹": Operation.unaryOperation(asin, nil, nil),
      "tan⁻¹": Operation.unaryOperation(atan, nil, nil),
      "cos": Operation.unaryOperation(cos, nil, nil),
      "sin": Operation.unaryOperation(sin, nil, nil),
      "tan": Operation.unaryOperation(tan, nil, nil),
      "ln": Operation.unaryOperation(log, nil, nil),
      "±": Operation.unaryOperation({ -$0 }, nil, nil),
      "eˣ": Operation.unaryOperation(exp, nil, nil),
      "xʸ": Operation.binaryOperation(pow, { $0 + "^" + $1 }, nil, 2),
      "×": Operation.binaryOperation(* , nil, nil, 1),
      "÷": Operation.binaryOperation(/, nil, { $1 == 0 ? "divide by zero" : nil }, 1),
      "+": Operation.binaryOperation(+, nil, nil, 0),
      "-": Operation.binaryOperation(-, nil, nil, 0),
      "=": Operation.equals
   ]
   
   struct PendingBinaryOperation {
      let function: (Double, Double) -> Double
      let firstOperand: Double
      var descriptionFunction: (String, String) -> String
      var descriptionOperand: String
      var validator: ((Double, Double) -> String?)?
      var prevPrecedence: Int
      var precedence: Int
      
      func perform(with secondOperand: Double) -> Double {
         return function(firstOperand, secondOperand)
      }
      
      func performDescription(with secondOperand: String) -> String {
         var descriptionOperandNew = descriptionOperand
         if prevPrecedence < precedence {
            descriptionOperandNew = "(" + descriptionOperandNew + ")"
         }
         return descriptionFunction(descriptionOperandNew, secondOperand)
      }
      
      func validate(with secondOperand: Double) -> String? {
         guard let validator = validator else { return nil }
         return validator(firstOperand, secondOperand)
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
   
   func evaluate(using variables: Dictionary<String, Double>? = nil) -> (result: Double?, isPending: Bool, description: String, error: String?) {
      //evaluated variables
      var cache: (accumulator: Double?, descriptionAccumulator: String?)
      var error: String?
      var prevPrecedence = Int.max
      
      var pendingBinaryOperation: PendingBinaryOperation?
      
      var result: Double? {
         get {
            return cache.accumulator
         }
      }

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
      
      //evaluated functions
      func setOPerand(_ operand: Double) {
         cache.accumulator = operand
         
         if let value = cache.accumulator {
            cache.descriptionAccumulator = formatter.string(from: NSNumber(value: value)) ?? ""
            prevPrecedence = Int.max
         }
      }
      
      func setOperand(variable named: String) {
         cache.accumulator = variables?[named] ?? 0
         cache.descriptionAccumulator = named
         prevPrecedence = Int.max
      }
      
      func performOperation(_ symbol: String) {
         if let operation = operations[symbol] {
            error = nil
            switch operation {
            case .nullaryOperation(let function, let desctiptionValue):
               cache = (function(), desctiptionValue)
            case .constant(let value):
               cache = (value, symbol)
            case .unaryOperation(let function, var descriptionFunction, let validator):
               if let accumulator = cache.accumulator {
                  error = validator?(accumulator)
                  cache.accumulator = function(accumulator)
                  if descriptionFunction == nil {
                     descriptionFunction = { symbol + "(" + $0 + ")" }
                  }
                  cache.descriptionAccumulator = descriptionFunction!(cache.descriptionAccumulator!)
               }
            case .binaryOperation(let function, var descriptionFunction, let validator, let precedence):
               performPendingBinaryOperation()
               if cache.accumulator != nil {
                  if descriptionFunction == nil {
                     descriptionFunction = { $0 + " " + symbol + " " + $1 }
                  }
                  pendingBinaryOperation = PendingBinaryOperation(function: function,
                                                                  firstOperand: cache.accumulator!,
                                                                  descriptionFunction: descriptionFunction!,
                                                                  descriptionOperand: cache.descriptionAccumulator!,
                                                                  validator: validator,
                                                                  prevPrecedence: prevPrecedence,
                                                                  precedence: precedence)
                  cache = (nil, nil)
               }
            case .equals:
               performPendingBinaryOperation()
            }
         }
      }
      
      func performPendingBinaryOperation() {
         if pendingBinaryOperation != nil && cache.accumulator != nil {
            error = pendingBinaryOperation!.validate(with: cache.accumulator!)
            cache.accumulator = pendingBinaryOperation!.perform(with: cache.accumulator!)
            cache.descriptionAccumulator = pendingBinaryOperation!.performDescription(with: cache.descriptionAccumulator!)
            prevPrecedence = pendingBinaryOperation!.precedence
            pendingBinaryOperation = nil
         }
      }
      //evaluate body
      guard !internalProgramm.isEmpty else { return (nil, false, " ", nil) }
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
      
      return (result, resultIsPending, description ?? " ", error)
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
