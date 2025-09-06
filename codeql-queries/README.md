# Enhanced CodeQL Queries for Path Conditions

This directory contains enhanced CodeQL queries for analyzing the Gungnir Forge web application to extract branch conditions, parameter requirements, and path constraints. These queries implement comprehensive static analysis to identify security-relevant control flow patterns and validation logic.

## Features Implemented

✅ **Branch Conditions Extraction**: Identifies all conditional branches (if/else, switch, loops) along flow paths  
✅ **Parameter Requirements Analysis**: Detects parameter checks and validation logic  
✅ **Field Dependencies Tracking**: Maps relationships between input fields and their usage  
✅ **Path Feasibility Analysis**: Evaluates the feasibility of different execution paths  
✅ **Input Validation Analysis**: Comprehensive constraint analysis for input validation  
✅ **Authentication Flow Analysis**: Specialized analysis for auth patterns  
✅ **Visualization Data Export**: Structured output for visualization tools

## Query Structure

### Core Queries
- `comprehensive-flow-extraction.ql` - Main query extracting all types of conditions and constraints
- `authentication-flow-analysis.ql` - Specialized authentication and authorization analysis
- `input-validation-analysis.ql` - Input validation patterns and vulnerability detection
- `visualization-data-export.ql` - Structured data export for visualization tools

### Libraries
- `lib/PathConditions.qll` - Core predicates for conditional statements, parameter validation, and field dependencies
- `lib/ConstraintAnalysis.qll` - Advanced constraint analysis including length, format, and sanitization checks

### Tests and Examples
- `tests/validate-queries.ql` - Query validation tests
- `tests/test-basic-extraction.ql` - Basic functionality tests
- `USAGE_EXAMPLES.md` - Detailed usage examples and expected outputs

### Configuration
- `qlpack.yml` - CodeQL package configuration
- `.codeqlmanifest.json` - Query metadata and structure
- `run-analysis.sh` - Automated analysis script

## Quick Start

### 1. Prerequisites
- Install [CodeQL CLI](https://github.com/github/codeql-cli-binaries)
- Ensure the CLI is in your PATH

### 2. Run Analysis
```bash
# Navigate to the queries directory
cd codeql-queries

# Run the automated analysis script
./run-analysis.sh

# Or run individual queries
codeql database create gungnir-forge-db --language=javascript --source-root=../
codeql query run comprehensive-flow-extraction.ql --database=gungnir-forge-db
```

### 3. View Results
Results are generated in SARIF format and can be viewed in:
- VS Code with CodeQL extension
- GitHub Security tab (when integrated with CI/CD)
- Any SARIF-compatible security analysis tool

## Query Capabilities

### 1. Comprehensive Flow Extraction
Extracts and categorizes:
- **Conditional Branches**: All if/else, switch, and loop conditions
- **Parameter Validations**: Input validation patterns
- **Field Dependencies**: Relationships between data fields
- **Path Analysis**: Execution path feasibility assessment

### 2. Authentication Flow Analysis  
Identifies:
- Authentication middleware usage
- Token validation patterns (JWT, Bearer tokens)
- Password operations (hashing, verification)
- Request parameter extraction
- Unprotected sensitive routes

### 3. Input Validation Analysis
Detects:
- Strong validation patterns (multiple constraint types)
- Validation bypasses (potential vulnerabilities)
- Web-specific validation (req.body, req.query, req.headers)
- SQL injection prevention patterns

### 4. Visualization Data Export
Generates structured data for:
- Flow diagram generation
- Security audit dashboards
- Compliance reporting
- Automated vulnerability assessment

## Example Output

```
# Conditional Branch Analysis
Result: Conditional branch: if with condition: existingUser.rows.length > 0
Location: server.js:31
Data: {"condition_type": "if", "condition": "existingUser.rows.length > 0"}

# Authentication Analysis  
Result: Authentication middleware used on route: /api/applications
Location: server.js:94
Category: auth-middleware

# Input Validation Analysis
Result: Web input validation: web-input-validation for parameter req
Location: server.js:22
Category: web-input-validation
```

## Integration

### CI/CD Integration
Add to your GitHub Actions workflow:
```yaml
- name: CodeQL Path Analysis
  run: |
    cd codeql-queries
    ./run-analysis.sh
    # Upload SARIF results to GitHub Security tab
```

### Visualization Tools
The structured JSON output can be consumed by:
- Custom security dashboards
- Flow diagram generators
- Compliance reporting tools
- Vulnerability management systems

## Security Focus Areas

The queries specifically target:
- **Authentication & Authorization**: Token validation, middleware usage
- **Input Validation**: Parameter checking, sanitization patterns  
- **SQL Injection Prevention**: Parameterized query usage
- **Path Traversal**: File access patterns
- **Cross-Site Scripting (XSS)**: Output encoding analysis

## Contributing

When extending these queries:
1. Follow the existing pattern structure
2. Add comprehensive documentation
3. Include test cases in the `tests/` directory
4. Update `USAGE_EXAMPLES.md` with new capabilities
5. Maintain backward compatibility with existing output formats