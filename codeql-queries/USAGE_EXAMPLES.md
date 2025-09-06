# CodeQL Query Usage Examples

This document demonstrates the usage and expected outputs of the enhanced CodeQL queries for the Gungnir Forge web application.

## Query Overview

### 1. Comprehensive Flow Extraction (`comprehensive-flow-extraction.ql`)

Extracts all types of conditions, validations, and path constraints from the codebase.

**Example Output for `webapp/backend/server.js`:**
```
Result Type: conditional-branch | Description: Conditional branch: if with condition: existingUser.rows.length > 0 | Location: server.js:31 | Data: {"condition_type": "if", "condition": "existingUser.rows.length > 0"}

Result Type: conditional-branch | Description: Conditional branch: if with condition: result.rows.length === 0 | Location: server.js:64 | Data: {"condition_type": "if", "condition": "result.rows.length === 0"}

Result Type: conditional-branch | Description: Conditional branch: if with condition: !validPassword | Location: server.js:72 | Data: {"condition_type": "if", "condition": "!validPassword"}

Result Type: parameter-validation | Description: Parameter validation: web-input-validation for parameter req | Location: server.js:22 | Data: {"validation_type": "web-input-validation", "parameter": "req"}
```

### 2. Authentication Flow Analysis (`authentication-flow-analysis.ql`)

Analyzes authentication and authorization patterns.

**Example Output for `webapp/backend/middleware/auth.js`:**
```
Token validation: token-extract [token-validation] | Location: auth.js:4
Token validation: jwt-verify [token-validation] | Location: auth.js:11
Authentication parameter extracted: token from req.header [auth-parameter] | Location: auth.js:4
```

**Example Output for `webapp/backend/server.js`:**
```
Authentication middleware used on route: /api/applications [auth-middleware] | Location: server.js:94
Authentication parameter extracted: username from req.body [auth-parameter] | Location: server.js:22
Authentication parameter extracted: password from req.body [auth-parameter] | Location: server.js:22
Password operation: password-hash [password-validation] | Location: server.js:36
Password operation: password-verify [password-validation] | Location: server.js:71
```

### 3. Input Validation Analysis (`input-validation-analysis.ql`)

Identifies validation patterns and potential security vulnerabilities.

**Example Output:**
```
Strong validation: length AND format [strong-validation] | Location: server.js:22 (if validation is enhanced)
Input constraint: length constraint with value: 0 [input-constraint] | Location: server.js:31
Web input validation: web-input-validation for parameter req [web-input-validation] | Location: server.js:22
```

## Code Analysis Results

### Conditional Branches Found

1. **User Existence Check** (`server.js:31`)
   - Condition: `existingUser.rows.length > 0`
   - Type: Registration validation
   - Security Relevance: Prevents duplicate user creation

2. **User Authentication Check** (`server.js:64`)
   - Condition: `result.rows.length === 0`
   - Type: Login validation
   - Security Relevance: User existence verification

3. **Password Validation** (`server.js:72`)
   - Condition: `!validPassword`
   - Type: Authentication validation
   - Security Relevance: Password verification

4. **Token Existence Check** (`middleware/auth.js:6`)
   - Condition: `!token`
   - Type: Authorization validation
   - Security Relevance: Token presence verification

### Parameter Requirements Identified

1. **Registration Parameters**
   - Required: `username`, `email`, `password`
   - Source: `req.body`
   - Validation: Existence checked implicitly through destructuring

2. **Login Parameters**
   - Required: `username`, `password`
   - Source: `req.body`
   - Validation: Database lookup and password comparison

3. **Authentication Token**
   - Required: `Authorization` header
   - Format: `Bearer <token>`
   - Validation: JWT signature verification

### Field Dependencies

1. **User Creation Flow**
   - `username` → Database uniqueness check
   - `email` → Database uniqueness check
   - `password` → Hash generation → Storage

2. **Authentication Flow**
   - `username/email` → User lookup
   - `password` → Hash comparison
   - Valid credentials → JWT token generation

3. **Protected Route Access**
   - `Authorization` header → Token extraction
   - Token → JWT verification → User ID extraction
   - User ID → Database queries for user-specific data

### Path Feasibility Analysis

1. **Successful Registration Path**
   - User doesn't exist → Password hashed → User created → Token generated
   - Feasible: Yes
   - Conditions: 1 (user uniqueness)

2. **Successful Login Path**
   - User exists → Password valid → Token generated
   - Feasible: Yes
   - Conditions: 2 (user existence, password validity)

3. **Protected Resource Access**
   - Token present → Token valid → Resource accessed
   - Feasible: Yes
   - Conditions: 2 (token presence, token validity)

## Security Insights

### Strengths Identified
- Parameterized SQL queries prevent injection
- Password hashing using bcrypt
- JWT token authentication
- Middleware-based authorization

### Areas for Enhancement
- Add input length validation
- Implement rate limiting checks
- Add email format validation
- Consider password strength requirements
- Add CSRF protection analysis

## Integration with Visualization Tools

The structured JSON output from these queries can be easily integrated with visualization tools:

```json
{
  "conditional_branches": [
    {
      "type": "if",
      "condition": "existingUser.rows.length > 0",
      "location": "server.js:31",
      "security_category": "input-validation"
    }
  ],
  "parameter_validations": [
    {
      "type": "web-input-validation",
      "parameter": "req",
      "location": "server.js:22"
    }
  ],
  "field_dependencies": [
    {
      "source": "req.body.username",
      "target": "database_query",
      "type": "conditional"
    }
  ]
}
```

This structured data enables:
- Flow diagram generation
- Security audit reports
- Compliance checking
- Automated vulnerability assessment