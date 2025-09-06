# CodeQL Queries for Gungnir Forge

This directory contains CodeQL queries for analyzing the Gungnir Forge web application to extract path conditions, branch logic, and validation constraints.

## Query Structure

- `comprehensive-flow-extraction.ql` - Main query for extracting flow paths and conditions
- `lib/` - Shared predicates and utility functions
- `tests/` - Test queries and examples

## Usage

Run queries using CodeQL CLI:
```bash
codeql query run comprehensive-flow-extraction.ql --database=<database-path>
```