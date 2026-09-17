# Changelog

Relevant project changes should be recorded here only when supported by verifiable evidence.

## [Unreleased]

## [0.1.0] - 2026-09-17

### Added

- Consolidated automated DUnitX suite with 57 tests across 9 fixtures.
- Process-level tests for CommandLine and Security.
- Component test for service configuration and loading.
- Real Windows Service Control Manager (SCM) integration for Query, InstallRoundTrip, Lifecycle, and Restart.
- `RickWinService.Integration.ServiceHost` as the service executable used by Lifecycle and Restart scenarios.
- Restart validation that confirms service-process replacement through a PID change.
- Dedicated test strategy, structure, execution, and metrics documentation in `docs/TESTING.md` and `docs/TESTING.pt-BR.md`.

### Changed

- Integrated SCM scenarios into the main DUnitX runner.
- Consolidated the Restart scenario into `RickWinService.SCM.Restart.TestHost`.
- Finalized `RickWinService.groupproj` around the projects required by the suite.
- Reorganized documentation into `README.md` and specialized documents under `docs/`.
- Separated API, command-line, architecture, testing, and documentation migration material.

### Removed

- `RickWinService.SCM.Restart.Diagnostic.TestHost`, removed after the required diagnostics were consolidated into the canonical Restart Test Host.