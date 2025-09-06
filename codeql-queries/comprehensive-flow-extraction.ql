/**
 * @name Comprehensive Flow Extraction
 * @description Extracts branch conditions, parameter requirements, and path constraints from JavaScript/TypeScript code
 * @kind problem
 * @problem.severity info
 * @id js/comprehensive-flow-extraction
 * @tags security
 *       maintainability
 *       external/cwe/cwe-20
 */

import javascript
import lib.PathConditions

/**
 * Main query results for flow extraction
 */
class FlowExtractionResult extends ASTNode {
  string resultType;
  string description;
  Location loc;
  string additionalData;
  
  FlowExtractionResult() {
    // Conditional branches
    exists(ConditionalStatement cond |
      this = cond and
      resultType = "conditional-branch" and
      description = "Conditional branch: " + cond.getConditionType() + " with condition: " + cond.getCondition().toString() and
      loc = cond.getLocation() and
      additionalData = "{\"condition_type\": \"" + cond.getConditionType() + "\", \"condition\": \"" + cond.getCondition().toString() + "\"}"
    ) or
    
    // Parameter validations
    exists(ParameterValidation pv |
      this = pv and
      resultType = "parameter-validation" and
      description = "Parameter validation: " + pv.getValidationType() + " for parameter " + pv.getParameter().getName() and
      loc = pv.getLocation() and
      additionalData = "{\"validation_type\": \"" + pv.getValidationType() + "\", \"parameter\": \"" + pv.getParameter().getName() + "\"}"
    ) or
    
    // Field dependencies
    exists(FieldDependency fd |
      this = fd and
      resultType = "field-dependency" and
      description = "Field dependency: " + fd.getDependencyType() + " between " + fd.getSourceField().toString() + " and " + fd.getTargetField().toString() and
      loc = fd.getLocation() and
      additionalData = "{\"dependency_type\": \"" + fd.getDependencyType() + "\", \"source\": \"" + fd.getSourceField().toString() + "\", \"target\": \"" + fd.getTargetField().toString() + "\"}"
    ) or
    
    // Path feasibility
    exists(PathFeasibility::AnalyzablePath path |
      this = path.getNode().asExpr() and
      resultType = "path-analysis" and
      description = "Path feasibility: " + (if path.isFeasible() then "feasible" else "potentially infeasible") + " path with " + count(path.getACondition()) + " conditions" and
      loc = path.getNode().asExpr().getLocation() and
      additionalData = "{\"feasible\": " + (if path.isFeasible() then "true" else "false") + ", \"condition_count\": " + count(path.getACondition()) + "}"
    )
  }
  
  /**
   * Gets the type of result (conditional-branch, parameter-validation, field-dependency, path-analysis)
   */
  string getResultType() { result = resultType }
  
  /**
   * Gets the human-readable description
   */
  string getDescription() { result = description }
  
  /**
   * Gets the location of this result
   */
  Location getResultLocation() { result = loc }
  
  /**
   * Gets additional structured data as JSON string
   */
  string getAdditionalData() { result = additionalData }
}

/**
 * Enhanced conditional extraction for specific security patterns
 */
class SecurityRelevantCondition extends ConditionalStatement {
  SecurityRelevantCondition() {
    // Authentication checks
    this.getCondition().toString().matches("%auth%") or
    this.getCondition().toString().matches("%token%") or
    this.getCondition().toString().matches("%login%") or
    this.getCondition().toString().matches("%permission%") or
    this.getCondition().toString().matches("%Bearer%") or
    this.getCondition().toString().matches("%Authorization%") or
    
    // Input validation
    this.getCondition().toString().matches("%validate%") or
    this.getCondition().toString().matches("%sanitize%") or
    this.getCondition().toString().matches("%escape%") or
    this.getCondition().toString().matches("%req.body%") or
    this.getCondition().toString().matches("%req.query%") or
    
    // Existence checks for parameters
    this.getCondition().toString().matches("%username%") or
    this.getCondition().toString().matches("%password%") or
    this.getCondition().toString().matches("%email%") or
    
    // Null/undefined checks
    exists(EqualityTest eq | eq = this.getCondition() and
      (eq.getAnOperand().(Literal).getValue() = "null" or
       eq.getAnOperand().(Literal).getValue() = "undefined")
    ) or
    
    // Length checks for arrays/strings  
    exists(Comparison comp | comp = this.getCondition() and
      comp.toString().matches("%.length%")
    ) or
    
    // Type checks
    exists(TypeofExpr te | te.getAChild*() = this.getCondition()) or
    exists(InstanceofExpr ie | ie = this.getCondition())
  }
  
  /**
   * Gets the security relevance category
   */
  string getSecurityCategory() {
    if this.getCondition().toString().matches("%auth%") or
       this.getCondition().toString().matches("%token%") or
       this.getCondition().toString().matches("%login%") or
       this.getCondition().toString().matches("%permission%")
    then result = "authentication"
    else if this.getCondition().toString().matches("%validate%") or
            this.getCondition().toString().matches("%sanitize%") or
            this.getCondition().toString().matches("%escape%")
    then result = "input-validation"
    else if exists(EqualityTest eq | eq = this.getCondition() and
                   (eq.getAnOperand().(Literal).getValue() = "null" or
                    eq.getAnOperand().(Literal).getValue() = "undefined"))
    then result = "null-safety"
    else if exists(TypeofExpr te | te.getAChild*() = this.getCondition()) or
            exists(InstanceofExpr ie | ie = this.getCondition())
    then result = "type-safety"
    else result = "other"
  }
}

/**
 * Input validation patterns specifically for web applications
 */
class WebInputValidation extends ParameterValidation {
  WebInputValidation() {
    // Request body validation
    exists(DataFlow::PropRead pr |
      pr.getPropertyName() = "body" and
      pr.getBase().(DataFlow::ParameterNode).getName() = "req" and
      this.getValidationCondition().getAChild*() = pr.asExpr()
    ) or
    
    // Query parameter validation
    exists(DataFlow::PropRead pr |
      pr.getPropertyName() = "query" and
      pr.getBase().(DataFlow::ParameterNode).getName() = "req" and
      this.getValidationCondition().getAChild*() = pr.asExpr()
    ) or
    
    // Header validation
    exists(DataFlow::PropRead pr |
      pr.getPropertyName() = "headers" and
      pr.getBase().(DataFlow::ParameterNode).getName() = "req" and
      this.getValidationCondition().getAChild*() = pr.asExpr()
    )
  }
  
  override Parameter getParameter() {
    result.getName() = "req" and
    exists(Function f | f.getAParameter() = result)
  }
  
  override string getValidationType() { result = "web-input-validation" }
  
  override Expr getValidationCondition() {
    exists(ConditionalStatement cs |
      cs.getCondition() = result and
      (
        result.toString().matches("%req.body%") or
        result.toString().matches("%req.query%") or
        result.toString().matches("%req.headers%")
      )
    )
  }
}

from FlowExtractionResult result
select result, result.getDescription() + " | Type: " + result.getResultType() + " | Data: " + result.getAdditionalData()