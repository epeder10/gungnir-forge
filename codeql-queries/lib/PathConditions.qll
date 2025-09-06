/**
 * @name Path Conditions Library
 * @description Predicates for extracting path conditions, branch logic, and constraints
 * @kind library
 */

import javascript

/**
 * A conditional statement that can affect program flow
 */
abstract class ConditionalStatement extends Stmt {
  /**
   * Gets the condition expression for this conditional
   */
  abstract Expr getCondition();
  
  /**
   * Gets a description of the conditional type
   */
  abstract string getConditionType();
  
  /**
   * Gets the then branch (if applicable)
   */
  abstract Stmt getThenBranch();
  
  /**
   * Gets the else branch (if applicable) 
   */
  Stmt getElseBranch() { none() }
}

/**
 * An if statement that creates branching paths
 */
class IfConditional extends ConditionalStatement, IfStmt {
  override Expr getCondition() { result = this.getCondition() }
  
  override string getConditionType() { result = "if" }
  
  override Stmt getThenBranch() { result = this.getThen() }
  
  override Stmt getElseBranch() { result = this.getElse() }
}

/**
 * A while loop that creates iterative paths
 */
class WhileConditional extends ConditionalStatement, WhileStmt {
  override Expr getCondition() { result = this.getCondition() }
  
  override string getConditionType() { result = "while" }
  
  override Stmt getThenBranch() { result = this.getBody() }
}

/**
 * A for loop that creates iterative paths
 */
class ForConditional extends ConditionalStatement, ForStmt {
  override Expr getCondition() { result = this.getCondition() }
  
  override string getConditionType() { result = "for" }
  
  override Stmt getThenBranch() { result = this.getBody() }
}

/**
 * A switch statement that creates multiple branching paths
 */
class SwitchConditional extends ConditionalStatement, SwitchStmt {
  override Expr getCondition() { result = this.getExpr() }
  
  override string getConditionType() { result = "switch" }
  
  override Stmt getThenBranch() { result = this.getACase().getBody() }
  
  /**
   * Gets all case statements in this switch
   */
  Case getACase() { result = this.getACase() }
}

/**
 * A parameter validation check
 */
class ParameterValidation extends Expr {
  /**
   * Gets the parameter being validated
   */
  abstract Parameter getParameter();
  
  /**
   * Gets the validation type (e.g., "null-check", "type-check", "range-check")
   */
  abstract string getValidationType();
  
  /**
   * Gets the validation condition
   */
  abstract Expr getValidationCondition();
}

/**
 * A null or undefined parameter check
 */
class NullParameterCheck extends ParameterValidation, EqualityTest {
  Parameter param;
  
  NullParameterCheck() {
    exists(VarAccess va | 
      va = this.getAnOperand() and
      va.getVariable().getADeclaration() = param and
      (this.getAnOperand().(Literal).getValue() = "null" or
       this.getAnOperand().(Literal).getValue() = "undefined")
    )
  }
  
  override Parameter getParameter() { result = param }
  
  override string getValidationType() { result = "null-check" }
  
  override Expr getValidationCondition() { result = this }
}

/**
 * A type validation check using typeof or instanceof
 */
class TypeParameterCheck extends ParameterValidation {
  Parameter param;
  Expr typeCheck;
  
  TypeParameterCheck() {
    exists(VarAccess va |
      va.getVariable().getADeclaration() = param and
      (
        // typeof check
        typeCheck.(TypeofExpr).getOperand() = va or
        // instanceof check  
        typeCheck.(InstanceofExpr).getLeftOperand() = va
      ) and
      this = typeCheck
    )
  }
  
  override Parameter getParameter() { result = param }
  
  override string getValidationType() { result = "type-check" }
  
  override Expr getValidationCondition() { result = typeCheck }
}

/**
 * A field dependency relationship
 */
class FieldDependency extends DataFlow::Node {
  /**
   * Gets the source field that is depended upon
   */
  abstract DataFlow::PropRead getSourceField();
  
  /**
   * Gets the target field that depends on the source
   */
  abstract DataFlow::PropWrite getTargetField();
  
  /**
   * Gets the dependency type (e.g., "conditional", "validation", "transformation")
   */
  abstract string getDependencyType();
}

/**
 * A conditional field dependency (field A is used only when field B has certain value)
 */
class ConditionalFieldDependency extends FieldDependency {
  DataFlow::PropRead source;
  DataFlow::PropWrite target;
  ConditionalStatement condition;
  
  ConditionalFieldDependency() {
    exists(ControlFlowNode cfn |
      cfn = condition and
      source.asExpr() = condition.getCondition().getAChild*() and
      target.getContainer().getBasicBlock() = cfn.getASuccessor+() and
      this = target
    )
  }
  
  override DataFlow::PropRead getSourceField() { result = source }
  
  override DataFlow::PropWrite getTargetField() { result = target }
  
  override string getDependencyType() { result = "conditional" }
}

/**
 * Path feasibility analysis
 */
module PathFeasibility {
  /**
   * A path through the program that includes conditions
   */
  class AnalyzablePath extends DataFlow::PathNode {
    /**
     * Gets all conditions that must be satisfied for this path
     */
    ConditionalStatement getACondition() {
      exists(ControlFlowNode cfn |
        cfn = result and
        this.getNode().asExpr().getBasicBlock() = cfn.getASuccessor+()
      )
    }
    
    /**
     * Checks if this path is potentially feasible
     */
    predicate isFeasible() {
      not exists(ConditionalStatement c1, ConditionalStatement c2 |
        c1 = this.getACondition() and
        c2 = this.getACondition() and
        c1 != c2 and
        // Simplified contradiction check - would need more sophisticated analysis
        c1.getCondition().toString() = "!" + c2.getCondition().toString()
      )
    }
  }
}