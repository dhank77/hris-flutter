# Flutter AI Code Audit Checklist

Use this checklist on every meaningful AI-generated change. Do not approve code only because it compiles.

## 1. Architecture
- [ ] UI widgets do not contain HTTP calls or business rules.
- [ ] State/controller logic is outside presentation widgets.
- [ ] Services/data sources own transport details.
- [ ] Repositories expose app-facing operations and map transport models where needed.
- [ ] Dependencies point in one direction; no circular feature dependencies.
- [ ] No unnecessary abstraction or duplicated source of truth.

## 2. Riverpod 3
- [ ] `watch`, `read` and `listen` are used for the correct purpose.
- [ ] State is immutable or updated through a clear single write path.
- [ ] Loading, success, empty and error states are represented.
- [ ] Provider lifecycle/auto-dispose behavior matches the screen and cache needs.
- [ ] No side effects or network requests occur in widget `build`.
- [ ] Async operations cannot update disposed UI/state incorrectly.
- [ ] Providers are testable with overrides/fakes.

## 3. Dio / API
- [ ] Base URL and timeouts are configured centrally.
- [ ] HTTP status and transport exceptions are handled.
- [ ] Interceptors do not leak secrets or personal data.
- [ ] Token refresh cannot create an infinite retry loop.
- [ ] Request cancellation/pagination behavior is correct where relevant.
- [ ] API response shape is validated rather than blindly cast.

## 4. Freezed / JSON
- [ ] Required, nullable and default fields match the API contract.
- [ ] Nested objects and lists are mapped correctly.
- [ ] Missing/null/incorrectly typed fields are considered.
- [ ] Generated files are produced by build_runner, not hand-edited.
- [ ] Serialization/deserialization tests cover representative payloads.

## 5. GoRouter
- [ ] Resource identity uses path parameters.
- [ ] Search/filter state uses query parameters when appropriate.
- [ ] Auth redirects handle signed-in and signed-out states.
- [ ] Back navigation and deep links behave correctly.
- [ ] Route builders remain free of business logic.

## 6. Flutter UI and performance
- [ ] Lists are lazy for large data sets.
- [ ] Stable keys are used where list identity matters.
- [ ] Controllers, focus nodes, subscriptions and animations are disposed.
- [ ] Rebuild scope is reasonable.
- [ ] Loading, empty, error and retry UI are accessible.
- [ ] Layout handles small screens, text scaling and keyboard insets.

## 7. Security
- [ ] No API keys, passwords or tokens are committed.
- [ ] Sensitive values use secure storage where appropriate.
- [ ] Logs redact authorization headers and personal data.
- [ ] User input is validated at the appropriate boundary.
- [ ] Permissions and external intents are justified.

## 8. Verification
- [ ] `dart format .`
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] `dart run build_runner build --delete-conflicting-outputs` if generated code changed
- [ ] Manual run-through of affected user flows
- [ ] AI reports files changed, tests run, known risks and unverified assumptions

## Review outcome
Classify findings:
- **Blocker:** security issue, data loss, broken core flow, incorrect state ownership.
- **Major:** lifecycle bug, wrong mapping, missing error handling, broken navigation.
- **Minor:** maintainability, naming, duplication or small UX issue.
- **Note:** optional improvement with no immediate correctness impact.
