/**
 * @name Authentication Flow Analysis  
 * @description Analyzes authentication and authorization flow patterns in web applications
 * @kind problem
 * @problem.severity info
 * @id js/authentication-flow-analysis
 * @tags security
 *       authentication
 *       authorization
 */

import javascript

/**
 * Authentication middleware usage
 */
class AuthMiddleware extends DataFlow::CallNode {
  AuthMiddleware() {
    // Direct auth middleware calls
    this.getCalleeName() in ["authMiddleware", "authenticate", "authorize"] or
    
    // Express route with auth middleware as parameter
    exists(DataFlow::MethodCallNode route |
      route.getMethodName() in ["get", "post", "put", "delete", "patch"] and
      route.getReceiver() = DataFlow::globalVarRef("app") and
      this = route.getArgument(1)
    )
  }
  
  /**
   * Gets the route this middleware protects
   */
  string getProtectedRoute() {
    exists(DataFlow::MethodCallNode route |
      route.getMethodName() in ["get", "post", "put", "delete", "patch"] and
      route.getReceiver() = DataFlow::globalVarRef("app") and
      this = route.getArgument(1) and
      result = route.getArgument(0).asExpr().(Literal).getValue()
    )
  }
}

/**
 * Token validation patterns
 */
class TokenValidation extends DataFlow::CallNode {
  TokenValidation() {
    // JWT verify calls
    this.getCalleeName() = "verify" and
    this.getReceiver() = DataFlow::globalVarRef("jwt") or
    
    // Token header extraction
    exists(DataFlow::MethodCallNode headerCall |
      headerCall.getMethodName() = "header" and
      headerCall.getArgument(0).asExpr().(Literal).getValue() = "Authorization" and
      this = headerCall
    )
  }
  
  /**
   * Gets the token validation pattern type
   */
  string getValidationType() {
    if this.getCalleeName() = "verify" then result = "jwt-verify"
    else if this.getMethodName() = "header" then result = "token-extract"
    else result = "other"
  }
}

/**
 * Password validation patterns
 */
class PasswordValidation extends DataFlow::CallNode {
  PasswordValidation() {
    // bcrypt compare
    this.getCalleeName() = "compare" and
    this.getReceiver() = DataFlow::globalVarRef("bcrypt") or
    
    // bcrypt hash
    this.getCalleeName() = "hash" and
    this.getReceiver() = DataFlow::globalVarRef("bcrypt")
  }
  
  /**
   * Gets the password operation type
   */
  string getPasswordOperation() {
    if this.getCalleeName() = "compare" then result = "password-verify"
    else if this.getCalleeName() = "hash" then result = "password-hash"
    else result = "other"
  }
}

/**
 * Authentication flow paths
 */
class AuthenticationPath extends DataFlow::PathNode {
  AuthenticationPath() {
    // Path that includes token validation
    exists(TokenValidation tv |
      this.getNode().asExpr().getEnclosingFunction() = tv.asExpr().getEnclosingFunction()
    ) or
    
    // Path that includes password validation
    exists(PasswordValidation pv |
      this.getNode().asExpr().getEnclosingFunction() = pv.asExpr().getEnclosingFunction()
    )
  }
  
  /**
   * Gets authentication steps in this path
   */
  DataFlow::CallNode getAuthStep() {
    result instanceof TokenValidation and
    result.asExpr().getEnclosingFunction() = this.getNode().asExpr().getEnclosingFunction()
    or
    result instanceof PasswordValidation and
    result.asExpr().getEnclosingFunction() = this.getNode().asExpr().getEnclosingFunction()
  }
}

/**
 * Input parameter extraction from requests
 */
class RequestParameterExtraction extends DataFlow::Node {
  string paramSource;
  string paramName;
  
  RequestParameterExtraction() {
    // Destructuring from req.body
    exists(DestructuringPattern dp, DataFlow::PropRead bodyRead |
      bodyRead.getPropertyName() = "body" and
      bodyRead.getBase().(DataFlow::ParameterNode).getName() = "req" and
      dp.getAnElement().asExpr() = this.asExpr() and
      paramSource = "body" and
      paramName = this.asExpr().(Identifier).getName()
    ) or
    
    // Direct property access req.body.param
    exists(DataFlow::PropRead paramRead, DataFlow::PropRead bodyRead |
      bodyRead.getPropertyName() = "body" and
      bodyRead.getBase().(DataFlow::ParameterNode).getName() = "req" and
      paramRead.getBase() = bodyRead and
      this = paramRead and
      paramSource = "body" and
      paramName = paramRead.getPropertyName()
    ) or
    
    // Query parameters req.query.param
    exists(DataFlow::PropRead paramRead, DataFlow::PropRead queryRead |
      queryRead.getPropertyName() = "query" and
      queryRead.getBase().(DataFlow::ParameterNode).getName() = "req" and
      paramRead.getBase() = queryRead and
      this = paramRead and
      paramSource = "query" and
      paramName = paramRead.getPropertyName()
    )
  }
  
  /**
   * Gets the source of the parameter (body, query, headers)
   */
  string getParameterSource() { result = paramSource }
  
  /**
   * Gets the parameter name
   */
  string getParameterName() { result = paramName }
  
  /**
   * Checks if this parameter is used in authentication
   */
  predicate isAuthParameter() {
    paramName in ["username", "password", "email", "token", "authorization"]
  }
}

/**
 * Route security analysis
 */
class RouteSecurityAnalysis extends DataFlow::MethodCallNode {
  RouteSecurityAnalysis() {
    this.getMethodName() in ["get", "post", "put", "delete", "patch"] and
    this.getReceiver() = DataFlow::globalVarRef("app")
  }
  
  /**
   * Gets the route path
   */
  string getRoutePath() {
    result = this.getArgument(0).asExpr().(Literal).getValue()
  }
  
  /**
   * Checks if this route has authentication middleware
   */
  predicate hasAuthMiddleware() {
    exists(AuthMiddleware auth |
      auth = this.getArgument(1) or
      auth.asExpr().getEnclosingFunction() = this.getArgument(-1).getAFunctionValue().getFunction()
    )
  }
  
  /**
   * Checks if this route handles sensitive operations
   */
  predicate isSensitiveRoute() {
    this.getRoutePath().matches("%admin%") or
    this.getRoutePath().matches("%delete%") or
    this.getRoutePath().matches("%password%") or
    this.getMethodName() = "delete" or
    exists(DataFlow::CallNode dbCall |
      dbCall.getCalleeName() in ["query", "execute"] and
      dbCall.asExpr().getEnclosingFunction() = this.getArgument(-1).getAFunctionValue().getFunction() and
      dbCall.getArgument(0).asExpr().(Literal).getValue().matches("%DELETE%")
    )
  }
}

from DataFlow::Node result, string message, string category
where
  // Authentication middleware usage
  exists(AuthMiddleware auth |
    result = auth and
    message = "Authentication middleware used on route: " + auth.getProtectedRoute() and
    category = "auth-middleware"
  ) or
  
  // Token validation
  exists(TokenValidation tv |
    result = tv and
    message = "Token validation: " + tv.getValidationType() and
    category = "token-validation"
  ) or
  
  // Password operations
  exists(PasswordValidation pv |
    result = pv and
    message = "Password operation: " + pv.getPasswordOperation() and
    category = "password-validation"
  ) or
  
  // Request parameter extraction
  exists(RequestParameterExtraction rpe |
    rpe.isAuthParameter() and
    result = rpe and
    message = "Authentication parameter extracted: " + rpe.getParameterName() + " from req." + rpe.getParameterSource() and
    category = "auth-parameter"
  ) or
  
  // Unprotected sensitive routes
  exists(RouteSecurityAnalysis rsa |
    rsa.isSensitiveRoute() and
    not rsa.hasAuthMiddleware() and
    result = rsa and
    message = "Potentially unprotected sensitive route: " + rsa.getRoutePath() + " (" + rsa.getMethodName().toUpperCase() + ")" and
    category = "unprotected-route"
  )
select result, message + " [" + category + "]"