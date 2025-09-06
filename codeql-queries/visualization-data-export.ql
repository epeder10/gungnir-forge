/**
 * @name Visualization Data Export
 * @description Exports structured data optimized for visualization tools and dashboards
 * @kind table
 * @id js/visualization-data-export
 * @tags security
 *       visualization
 *       data-export
 */

import javascript
import lib.PathConditions
import lib.ConstraintAnalysis

/**
 * Structured data for visualization export
 */
class VisualizationDataPoint extends ASTNode {
  string nodeType;
  string nodeId;
  string label;
  string category;
  float xPos;
  float yPos;
  string metadata;
  string sourceFile;
  int startLine;
  int endLine;
  
  VisualizationDataPoint() {
    // Conditional nodes
    exists(ConditionalStatement cond |
      this = cond and
      nodeType = "condition" and
      nodeId = "cond_" + cond.getLocation().getStartLine() + "_" + cond.getLocation().getStartColumn() and
      label = cond.getConditionType() + ": " + cond.getCondition().toString().prefix(50) and
      category = "control-flow" and
      xPos = cond.getLocation().getStartColumn().(float) and
      yPos = cond.getLocation().getStartLine().(float) and
      metadata = "{\"condition_type\": \"" + cond.getConditionType() + "\", \"full_condition\": \"" + cond.getCondition().toString() + "\"}" and
      sourceFile = cond.getFile().getBaseName() and
      startLine = cond.getLocation().getStartLine() and
      endLine = cond.getLocation().getEndLine()
    ) or
    
    // Parameter validation nodes
    exists(ParameterValidation pv |
      this = pv and
      nodeType = "validation" and
      nodeId = "val_" + pv.getLocation().getStartLine() + "_" + pv.getLocation().getStartColumn() and
      label = "Validate: " + pv.getParameter().getName() and
      category = "validation" and
      xPos = pv.getLocation().getStartColumn().(float) and
      yPos = pv.getLocation().getStartLine().(float) and
      metadata = "{\"validation_type\": \"" + pv.getValidationType() + "\", \"parameter\": \"" + pv.getParameter().getName() + "\"}" and
      sourceFile = pv.getFile().getBaseName() and
      startLine = pv.getLocation().getStartLine() and
      endLine = pv.getLocation().getEndLine()
    ) or
    
    // Input constraint nodes
    exists(InputConstraint ic |
      this = ic and
      nodeType = "constraint" and
      nodeId = "const_" + ic.getLocation().getStartLine() + "_" + ic.getLocation().getStartColumn() and
      label = ic.getConstraintType() + ": " + ic.getConstraintValue() and
      category = "constraint" and
      xPos = ic.getLocation().getStartColumn().(float) and
      yPos = ic.getLocation().getStartLine().(float) and
      metadata = "{\"constraint_type\": \"" + ic.getConstraintType() + "\", \"constraint_value\": \"" + ic.getConstraintValue() + "\"}" and
      sourceFile = ic.getFile().getBaseName() and
      startLine = ic.getLocation().getStartLine() and
      endLine = ic.getLocation().getEndLine()
    ) or
    
    // Function entry/exit points
    exists(Function f |
      f.getNumParameter() > 0 and
      this = f and
      nodeType = "function" and
      nodeId = "func_" + f.getLocation().getStartLine() + "_" + f.getName() and
      label = "Function: " + f.getName() and
      category = "entry-point" and
      xPos = f.getLocation().getStartColumn().(float) and
      yPos = f.getLocation().getStartLine().(float) and
      metadata = "{\"function_name\": \"" + f.getName() + "\", \"parameter_count\": " + f.getNumParameter() + "}" and
      sourceFile = f.getFile().getBaseName() and
      startLine = f.getLocation().getStartLine() and
      endLine = f.getLocation().getEndLine()
    )
  }
  
  string getNodeType() { result = nodeType }
  string getNodeId() { result = nodeId }
  string getLabel() { result = label }
  string getCategory() { result = category }
  float getXPosition() { result = xPos }
  float getYPosition() { result = yPos }
  string getMetadata() { result = metadata }
  string getSourceFile() { result = sourceFile }
  int getStartLine() { result = startLine }
  int getEndLine() { result = endLine }
}

/**
 * Edges/connections between nodes for flow visualization
 */
class VisualizationEdge extends ASTNode {
  string edgeId;
  string sourceNodeId;
  string targetNodeId;
  string edgeType;
  string label;
  
  VisualizationEdge() {
    // Control flow edges (conditions to their branches)
    exists(ConditionalStatement cond, Stmt branch |
      branch = cond.getThenBranch() and
      this = cond and
      edgeId = "edge_" + cond.getLocation().getStartLine() + "_to_" + branch.getLocation().getStartLine() and
      sourceNodeId = "cond_" + cond.getLocation().getStartLine() + "_" + cond.getLocation().getStartColumn() and
      targetNodeId = "stmt_" + branch.getLocation().getStartLine() + "_" + branch.getLocation().getStartColumn() and
      edgeType = "control-flow" and
      label = "then"
    ) or
    
    // Data flow edges (parameter to validation)
    exists(ParameterValidation pv, Parameter param |
      param = pv.getParameter() and
      this = pv and
      edgeId = "edge_param_" + param.getLocation().getStartLine() + "_to_val_" + pv.getLocation().getStartLine() and
      sourceNodeId = "param_" + param.getLocation().getStartLine() + "_" + param.getName() and
      targetNodeId = "val_" + pv.getLocation().getStartLine() + "_" + pv.getLocation().getStartColumn() and
      edgeType = "data-flow" and
      label = "validates"
    ) or
    
    // Field dependency edges
    exists(FieldDependency fd |
      this = fd and
      edgeId = "edge_dep_" + fd.getLocation().getStartLine() + "_" + fd.getLocation().getStartColumn() and
      sourceNodeId = "field_" + fd.getSourceField().toString() and
      targetNodeId = "field_" + fd.getTargetField().toString() and
      edgeType = "dependency" and
      label = fd.getDependencyType()
    )
  }
  
  string getEdgeId() { result = edgeId }
  string getSourceNodeId() { result = sourceNodeId }
  string getTargetNodeId() { result = targetNodeId }
  string getEdgeType() { result = edgeType }
  string getLabel() { result = label }
}

/**
 * Security annotations for highlighting important nodes
 */
class SecurityAnnotation extends ASTNode {
  string annotationId;
  string nodeId;
  string severity;
  string description;
  string recommendation;
  
  SecurityAnnotation() {
    // High-security conditions
    exists(ConditionalStatement cond |
      (
        cond.getCondition().toString().matches("%token%") or
        cond.getCondition().toString().matches("%auth%") or
        cond.getCondition().toString().matches("%password%")
      ) and
      this = cond and
      annotationId = "sec_" + cond.getLocation().getStartLine() and
      nodeId = "cond_" + cond.getLocation().getStartLine() + "_" + cond.getLocation().getStartColumn() and
      severity = "high" and
      description = "Security-critical authentication check" and
      recommendation = "Ensure proper error handling and logging"
    ) or
    
    // Input validation gaps
    exists(ValidationBypass vb |
      this = vb and
      annotationId = "bypass_" + vb.getLocation().getStartLine() and
      nodeId = "bypass_" + vb.getLocation().getStartLine() + "_" + vb.getLocation().getStartColumn() and
      severity = vb.getSeverity() and
      description = "Potential validation bypass detected" and
      recommendation = "Add input validation before sensitive operations"
    )
  }
  
  string getAnnotationId() { result = annotationId }
  string getNodeId() { result = nodeId }
  string getSeverity() { result = severity }
  string getDescription() { result = description }
  string getRecommendation() { result = recommendation }
}

// Export nodes for visualization
select
  node.getNodeId() as node_id,
  node.getNodeType() as node_type,
  node.getLabel() as label,
  node.getCategory() as category,
  node.getXPosition() as x_position,
  node.getYPosition() as y_position,
  node.getSourceFile() as source_file,
  node.getStartLine() as start_line,
  node.getEndLine() as end_line,
  node.getMetadata() as metadata
from VisualizationDataPoint node