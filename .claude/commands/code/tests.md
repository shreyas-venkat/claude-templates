---
description: Write comprehensive tests for a file or function
---

Write tests for: $ARGUMENTS

Read the target code carefully. Identify the testing framework already in use (jest, pytest, vitest, go test, etc.) and follow existing test conventions in the project.

Cover:

**Happy path**
- Core expected behavior with typical inputs

**Edge cases**
- Empty / null / zero inputs
- Boundary values (off-by-one, max length, etc.)
- Type coercion or unexpected types if the language allows it

**Error cases**
- What should throw or return an error?
- Are errors the right type with the right message?

**Integration points** (if applicable)
- Mock external dependencies (DB, HTTP, filesystem) at the right boundary
- Test that side effects (writes, emails, events) are triggered correctly

**Don'ts**
- Don't test implementation details, test behavior
- Don't write tests that can only pass if the code is already correct by coincidence

Write the tests in the appropriate test file (create it if it doesn't exist, following the project's naming convention). Run them after writing.
