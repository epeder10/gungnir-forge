/**
 * @name Test Basic Extraction
 * @description Test query to validate basic extraction functionality
 * @kind problem
 * @problem.severity info
 * @id js/test-basic-extraction
 */

import javascript

from ConditionalStmt cond
where cond.getLocation().getFile().getBaseName().matches("%.js")
select cond, "Found conditional: " + cond.toString() + " at line " + cond.getLocation().getStartLine()