# Code Review Skill

## Purpose
Perform thorough code reviews focusing on:
- Code quality and maintainability
- Security vulnerabilities
- Performance considerations
- Best practices adherence
- Test coverage

## Usage
When reviewing code, check for:

### Security
- [ ] No hardcoded credentials or API keys
- [ ] Input validation for user-provided data
- [ ] Proper error handling without information leakage
- [ ] Dependencies are up to date and vetted
- [ ] Secrets managed via environment variables or secret managers

### Code Quality
- [ ] Clear, self-documenting variable and function names
- [ ] Functions do one thing well (single responsibility)
- [ ] DRY principle followed (no unnecessary duplication)
- [ ] Appropriate abstraction levels
- [ ] Consistent with project style guide
- [ ] Error handling is explicit and comprehensive

### Performance
- [ ] No obvious performance bottlenecks
- [ ] Efficient algorithms and data structures
- [ ] Resource cleanup (connections, file handles, etc.)
- [ ] Appropriate caching where beneficial
- [ ] Database queries optimized (indexes, n+1 queries)

### Testing
- [ ] Critical paths have test coverage
- [ ] Tests are meaningful and not just for coverage
- [ ] Edge cases considered
- [ ] Tests are maintainable and clear
- [ ] Integration tests for critical workflows

### Documentation
- [ ] Complex logic has explanatory comments
- [ ] Public APIs documented
- [ ] README updated if user-facing changes
- [ ] Breaking changes clearly noted
- [ ] Migration guides for breaking changes

### Nix-Specific (when applicable)
- [ ] Pure functions preferred
- [ ] Proper use of `lib` functions
- [ ] Formatted with `nixpkgs-fmt`
- [ ] Dependencies pinned appropriately
- [ ] Build reproducibility maintained