/**
 * @name Validate Queries Test
 * @description Validates that our queries can find expected patterns in the codebase
 * @kind problem
 * @problem.severity info
 * @id js/validate-queries-test
 */

import javascript
import lib.PathConditions
import lib.ConstraintAnalysis

/**
 * Test that we can find authentication-related conditionals
 */
from ConditionalStatement cond
where 
  cond.getCondition().toString().matches("%token%") or
  cond.getCondition().toString().matches("%password%") or
  cond.getCondition().toString().matches("%length%") or
  cond.getCondition().toString().matches("%rows%")
select cond, "Found auth/validation condition: " + cond.getCondition().toString() + " in " + cond.getFile().getBaseName() + ":" + cond.getLocation().getStartLine()