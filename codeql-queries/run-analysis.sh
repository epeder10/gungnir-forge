#!/bin/bash

# Enhanced CodeQL Analysis Script for Gungnir Forge
# This script demonstrates how to run the path condition analysis queries

set -e

REPO_ROOT="../"
DB_NAME="gungnir-forge-db"
QUERIES_DIR="."

echo "🔍 Enhanced CodeQL Path Conditions Analysis"
echo "=========================================="

# Check if CodeQL CLI is available
if ! command -v codeql &> /dev/null; then
    echo "❌ CodeQL CLI not found. Please install CodeQL CLI first."
    echo "   Download from: https://github.com/github/codeql-cli-binaries"
    exit 1
fi

echo "📁 Repository: $REPO_ROOT"
echo "🗄️  Database: $DB_NAME"
echo "📋 Queries: $QUERIES_DIR"

# Create CodeQL database for JavaScript analysis
echo ""
echo "🔧 Creating CodeQL database..."
if [ -d "$DB_NAME" ]; then
    echo "   Database already exists, removing old database..."
    rm -rf "$DB_NAME"
fi

codeql database create "$DB_NAME" \
    --language=javascript \
    --source-root="$REPO_ROOT" \
    --overwrite

echo "✅ Database created successfully"

# Run comprehensive flow extraction
echo ""
echo "🚀 Running Comprehensive Flow Extraction..."
codeql query run comprehensive-flow-extraction.ql \
    --database="$DB_NAME" \
    --output=results-flow-extraction.sarif \
    --format=sarif-latest

echo "📄 Results saved to: results-flow-extraction.sarif"

# Run authentication flow analysis
echo ""
echo "🔐 Running Authentication Flow Analysis..."
codeql query run authentication-flow-analysis.ql \
    --database="$DB_NAME" \
    --output=results-auth-analysis.sarif \
    --format=sarif-latest

echo "📄 Results saved to: results-auth-analysis.sarif"

# Run input validation analysis
echo ""
echo "🛡️  Running Input Validation Analysis..."
codeql query run input-validation-analysis.ql \
    --database="$DB_NAME" \
    --output=results-validation-analysis.sarif \
    --format=sarif-latest

echo "📄 Results saved to: results-validation-analysis.sarif"

# Generate human-readable report
echo ""
echo "📊 Generating Human-Readable Reports..."

# Convert SARIF to CSV for easy reading
for result_file in results-*.sarif; do
    if [ -f "$result_file" ]; then
        base_name=$(basename "$result_file" .sarif)
        echo "Converting $result_file to ${base_name}.csv"
        codeql bqrs decode --format=csv \
            --output="${base_name}.csv" \
            "$result_file" 2>/dev/null || echo "   Note: Direct CSV conversion not available, using SARIF format"
    fi
done

# Display summary
echo ""
echo "📈 Analysis Summary"
echo "=================="
echo "🔍 Flow Extraction: Extracts all conditional branches, parameter validations, and path constraints"
echo "🔐 Authentication Analysis: Identifies auth middleware usage, token validation, and password operations"  
echo "🛡️  Validation Analysis: Detects input validation patterns and potential security issues"
echo ""
echo "📁 Output Files:"
ls -la results-*.sarif 2>/dev/null || echo "   SARIF files generated"
ls -la results-*.csv 2>/dev/null || echo "   CSV conversion may require additional steps"
echo ""
echo "✨ Analysis complete! Review the generated files for detailed results."
echo ""
echo "🔗 Next Steps:"
echo "   1. Review SARIF files with CodeQL extension in VS Code"
echo "   2. Import results into security analysis tools" 
echo "   3. Use structured data for visualization dashboards"
echo "   4. Integrate into CI/CD pipeline for continuous monitoring"