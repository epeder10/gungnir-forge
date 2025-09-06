/**
 * @name Constraint Analysis Library
 * @description Advanced constraint and input validation analysis
 * @kind library
 */

import javascript

/**
 * A constraint on input data
 */
abstract class InputConstraint extends Expr {
  /**
   * Gets the input variable or property being constrained
   */
  abstract DataFlow::Node getConstrainedInput();
  
  /**
   * Gets the type of constraint (length, format, range, etc.)
   */
  abstract string getConstraintType();
  
  /**
   * Gets the constraint value or pattern
   */
  abstract string getConstraintValue();
  
  /**
   * Checks if this constraint is security-relevant
   */
  predicate isSecurityRelevant() {
    this.getConstraintType() = "length" or
    this.getConstraintType() = "format" or
    this.getConstraintType() = "sanitization" or
    this.getConstraintType() = "authorization"
  }
}

/**
 * Length constraints on strings or arrays
 */
class LengthConstraint extends InputConstraint, RelationalComparison {
  DataFlow::Node input;
  
  LengthConstraint() {
    exists(DataFlow::PropRead lengthRead |
      lengthRead.getPropertyName() = "length" and
      lengthRead = this.getLesserOperand() and
      input = lengthRead.getBase()
    ) or
    exists(DataFlow::PropRead lengthRead |
      lengthRead.getPropertyName() = "length" and
      lengthRead = this.getGreaterOperand() and
      input = lengthRead.getBase()
    )
  }
  
  override DataFlow::Node getConstrainedInput() { result = input }
  
  override string getConstraintType() { result = "length" }
  
  override string getConstraintValue() {
    exists(Literal lit | lit = this.getAnOperand() |
      result = lit.getValue()
    )
  }
}

/**
 * Format/pattern constraints using regex or string methods
 */
class FormatConstraint extends InputConstraint {
  DataFlow::Node input;
  string pattern;
  
  FormatConstraint() {
    // Regex test
    exists(DataFlow::MethodCallNode regexTest |
      regexTest.getMethodName() = "test" and
      this = regexTest.asExpr() and
      input = regexTest.getArgument(0) and
      exists(RegExpLiteral regex | regex = regexTest.getReceiver().asExpr() |
        pattern = regex.getValue()
      )
    ) or
    
    // String match
    exists(DataFlow::MethodCallNode match |
      match.getMethodName() = "match" and
      this = match.asExpr() and
      input = match.getReceiver() and
      exists(RegExpLiteral regex | regex = match.getArgument(0).asExpr() |
        pattern = regex.getValue()
      )
    ) or
    
    // String includes/startsWith/endsWith
    exists(DataFlow::MethodCallNode strMethod |
      strMethod.getMethodName() in ["includes", "startsWith", "endsWith"] and
      this = strMethod.asExpr() and
      input = strMethod.getReceiver() and
      exists(Literal lit | lit = strMethod.getArgument(0).asExpr() |
        pattern = lit.getValue()
      )
    )
  }
  
  override DataFlow::Node getConstrainedInput() { result = input }
  
  override string getConstraintType() { result = "format" }
  
  override string getConstraintValue() { result = pattern }
}

/**
 * Sanitization constraints
 */
class SanitizationConstraint extends InputConstraint, DataFlow::CallNode {
  DataFlow::Node input;
  
  SanitizationConstraint() {
    this.getCalleeName() in ["escape", "sanitize", "clean", "filter", "validate"] and
    input = this.getArgument(0)
  }
  
  override DataFlow::Node getConstrainedInput() { result = input }
  
  override string getConstraintType() { result = "sanitization" }
  
  override string getConstraintValue() { result = this.getCalleeName() }
}

/**
 * Authorization constraints
 */
class AuthorizationConstraint extends InputConstraint {
  DataFlow::Node input;
  
  AuthorizationConstraint() {
    exists(DataFlow::CallNode authCheck |
      authCheck.getCalleeName() in ["authorize", "authenticate", "checkPermission", "hasRole"] and
      this = authCheck.asExpr() and
      input = authCheck.getArgument(0)
    ) or
    
    exists(DataFlow::PropRead tokenRead |
      tokenRead.getPropertyName() in ["token", "authorization", "jwt"] and
      input = tokenRead.getBase() and
      this = tokenRead.asExpr()
    )
  }
  
  override DataFlow::Node getConstrainedInput() { result = input }
  
  override string getConstraintType() { result = "authorization" }
  
  override string getConstraintValue() { result = "auth-required" }
}

/**
 * Complex constraint combinations
 */
class ConstraintCombination extends ASTNode {
  InputConstraint constraint1;
  InputConstraint constraint2;
  string operator;
  
  ConstraintCombination() {
    exists(LogicalBinaryExpr logical |
      logical = this and
      constraint1.getAChild*() = logical.getLeftOperand() and
      constraint2.getAChild*() = logical.getRightOperand() and
      (
        (logical instanceof LogicalAndExpr and operator = "AND") or
        (logical instanceof LogicalOrExpr and operator = "OR")
      )
    )
  }
  
  /**
   * Gets the first constraint in the combination
   */
  InputConstraint getFirstConstraint() { result = constraint1 }
  
  /**
   * Gets the second constraint in the combination
   */
  InputConstraint getSecondConstraint() { result = constraint2 }
  
  /**
   * Gets the logical operator combining the constraints
   */
  string getOperator() { result = operator }
  
  /**
   * Checks if this combination creates a strong validation pattern
   */
  predicate isStrongValidation() {
    operator = "AND" and
    constraint1.getConstraintType() != constraint2.getConstraintType() and
    constraint1.isSecurityRelevant() and
    constraint2.isSecurityRelevant()
  }
}

/**
 * Input validation bypass patterns
 */
class ValidationBypass extends DataFlow::Node {
  InputConstraint constraint;
  
  ValidationBypass() {
    // Input used without validation
    exists(DataFlow::Node source, DataFlow::Node sink |
      // Source is user input (req.body, req.query, etc.)
      source.asExpr().(DataFlow::PropRead).getBase().(DataFlow::ParameterNode).getName() = "req" and
      
      // Sink is a sensitive operation
      sink = DataFlow::globalVarRef(["eval", "Function", "setTimeout", "setInterval"]).getACall().getArgument(0) and
      
      // There's a path from source to sink
      DataFlow::localFlow(source, sink) and
      
      // No constraint validation on this path
      not exists(InputConstraint ic |
        DataFlow::localFlow(source, ic.getConstrainedInput()) and
        DataFlow::localFlow(ic.getConstrainedInput(), sink)
      ) and
      
      this = sink
    )
  }
  
  /**
   * Gets the constraint that should have been applied
   */
  InputConstraint getMissingConstraint() { result = constraint }
  
  /**
   * Gets the severity level of this bypass
   */
  string getSeverity() {
    if this.asExpr() = DataFlow::globalVarRef("eval").getACall().getArgument(0).asExpr()
    then result = "critical"
    else if this.asExpr() = DataFlow::globalVarRef(["Function", "setTimeout", "setInterval"]).getACall().getArgument(0).asExpr()
    then result = "high"
    else result = "medium"
  }
}