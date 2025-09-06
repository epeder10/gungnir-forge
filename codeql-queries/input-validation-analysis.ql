/**
 * @name Input Validation Analysis
 * @description Analyzes input validation patterns and identifies potential security vulnerabilities
 * @kind problem
 * @problem.severity warning
 * @id js/input-validation-analysis
 * @tags security
 *       external/cwe/cwe-20
 *       external/cwe/cwe-79
 */

import javascript
import lib.PathConditions
import lib.ConstraintAnalysis

/**
 * Input validation analysis results
 */
class ValidationAnalysisResult extends ASTNode {
  string resultType;
  string message;
  string severity;
  
  ValidationAnalysisResult() {
    // Strong validation patterns (good)
    exists(ConstraintCombination cc |
      cc.isStrongValidation() and
      this = cc and
      resultType = "strong-validation" and
      message = "Strong validation: " + cc.getFirstConstraint().getConstraintType() + " AND " + cc.getSecondConstraint().getConstraintType() and
      severity = "info"
    ) or
    
    // Missing constraints (potential vulnerability)
    exists(ValidationBypass vb |
      this = vb and
      resultType = "validation-bypass" and
      message = "Potential validation bypass: User input reaches sensitive sink without proper validation" and
      severity = vb.getSeverity()
    ) or
    
    // Individual constraints found
    exists(InputConstraint ic |
      ic.isSecurityRelevant() and
      this = ic and
      resultType = "input-constraint" and
      message = "Input constraint: " + ic.getConstraintType() + " constraint with value: " + ic.getConstraintValue() and
      severity = "info"
    ) or
    
    // Web-specific validation patterns
    exists(WebInputValidation wiv |
      this = wiv and
      resultType = "web-input-validation" and
      message = "Web input validation: " + wiv.getValidationType() + " for parameter " + wiv.getParameter().getName() and
      severity = "info"
    )
  }
  
  string getResultType() { result = resultType }
  string getMessage() { result = message }
  string getSeverity() { result = severity }
}

/**
 * Express.js route parameter validation
 */
class ExpressRouteValidation extends DataFlow::CallNode {
  DataFlow::FunctionNode routeHandler;
  
  ExpressRouteValidation() {
    // Express route definition: app.get/post/etc
    exists(DataFlow::MethodCallNode route |
      route.getMethodName() in ["get", "post", "put", "delete", "patch"] and
      route.getReceiver() = DataFlow::globalVarRef("app") and
      routeHandler = route.getArgument(1).getAFunctionValue()
    ) and
    this = routeHandler.getACall()
  }
  
  /**
   * Gets validation calls within this route handler
   */
  DataFlow::CallNode getValidationCall() {
    exists(DataFlow::CallNode validation |
      validation.getCalleeName() in ["validate", "sanitize", "escape", "check"] and
      validation.getEnclosingFunction() = routeHandler.getFunction() and
      result = validation
    )
  }
  
  /**
   * Checks if this route has input validation
   */
  predicate hasInputValidation() {
    exists(this.getValidationCall()) or
    exists(InputConstraint ic |
      ic.getLocation().getFile() = routeHandler.getFile() and
      ic.getLocation().getStartLine() >= routeHandler.getStartLine() and
      ic.getLocation().getEndLine() <= routeHandler.getEndLine()
    )
  }
}

/**
 * SQL injection prevention analysis
 */
class SqlInjectionPrevention extends DataFlow::CallNode {
  DataFlow::Node sqlQuery;
  
  SqlInjectionPrevention() {
    // Database query calls
    this.getCalleeName() in ["query", "execute", "prepare"] and
    sqlQuery = this.getArgument(0) and
    exists(string queryStr | queryStr = sqlQuery.asExpr().(Literal).getValue() |
      queryStr.matches("%SELECT%") or
      queryStr.matches("%INSERT%") or
      queryStr.matches("%UPDATE%") or
      queryStr.matches("%DELETE%")
    )
  }
  
  /**
   * Checks if this query uses parameterized queries (safe)
   */
  predicate usesParameterizedQuery() {
    exists(string queryStr | queryStr = sqlQuery.asExpr().(Literal).getValue() |
      queryStr.matches("%$%") or  // PostgreSQL style
      queryStr.matches("%?%")     // MySQL style
    )
  }
  
  /**
   * Checks if this query concatenates user input (dangerous)
   */
  predicate concatenatesUserInput() {
    exists(DataFlow::Node userInput |
      // User input from request
      userInput.asExpr().(DataFlow::PropRead).getBase().(DataFlow::ParameterNode).getName() = "req" and
      
      // Used in string concatenation or template for SQL
      exists(AddExpr concat | 
        concat.getAnOperand() = sqlQuery.asExpr() and
        DataFlow::localFlow(userInput, DataFlow::valueNode(concat.getAnOperand()))
      )
    )
  }
}

from ValidationAnalysisResult result
where 
  // Focus on security-relevant results
  result.getSeverity() in ["critical", "high", "warning"] or
  result.getResultType() in ["strong-validation", "web-input-validation"]
select result, result.getMessage() + " [" + result.getSeverity() + "]"