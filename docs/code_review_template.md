# Code Review Template

## General Checks
- [ ] Code follows project style guidelines
- [ ] No obvious bugs or logic errors
- [ ] Proper error handling
- [ ] Adequate test coverage
- [ ] Documentation updated if needed

## Date/Time Parsing Specific Checks
- [ ] **CRITICAL**: Does the code handle TAF date parsing correctly?
- [ ] Does it avoid comparing days to determine months?
- [ ] Does it handle month transitions (e.g., 3020/0100)?
- [ ] Does it handle year transitions (e.g., 3120/0100)?
- [ ] Are there unit tests for the specific problematic case (2315/2500)?
- [ ] Is the logic documented with aviation-specific context?

## Aviation-Specific Checks
- [ ] Does the code handle aviation data formats correctly?
- [ ] Are TAF validity periods parsed relative to current month?
- [ ] Does the code handle UTC time zones properly?
- [ ] Are aviation abbreviations and codes handled correctly?

## Performance Checks
- [ ] No unnecessary API calls
- [ ] Proper caching implementation
- [ ] Efficient data structures
- [ ] No memory leaks

## Security Checks
- [ ] No hardcoded API keys
- [ ] Proper input validation
- [ ] No SQL injection vulnerabilities
- [ ] Secure data handling

## UI/UX Checks
- [ ] Consistent with existing design
- [ ] Proper error states
- [ ] Loading states implemented
- [ ] Accessibility considerations

## Comments
<!-- Add specific comments about the changes -->

## Approval
- [ ] **Reviewer**: 
- [ ] **Date**: 
- [ ] **Status**: Approved/Needs Changes/Rejected 