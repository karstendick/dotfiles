# Personal Claude Code Rules

## Workflow Rules

- Always run tests before declaring a task complete. Never say 'tests pass' without actually running them.

## PR Creation

- When asked to create a PR, just do it. Do not ask for confirmation or whether you should create it — proceed directly.

## Investigation & Debugging

- When investigating issues, always read the actual code/config/logs first. Do not speculate or make assumptions about what the codebase does. Do not claim you cannot access tools (AWS CLI, local test runners, etc.) without trying first.
- Check the actual code, AWS CLI, CDK config, and any other available tools before asking. Only ask if you hit a genuine blocker or need a design decision.

## Testing

- When modifying code, always grep for related test files and update them. Do not wait for the user to ask about tests.

## Scope & Decision Tracking

- When a user defers a decision or marks something as out-of-scope, do not implement it. Respect deferred items strictly.

## Linear Integration

- For Linear tickets, always read the actual project field and full ticket details (including images/attachments) rather than inferring from titles.
