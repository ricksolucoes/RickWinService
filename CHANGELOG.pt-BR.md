# Changelog

Alterações relevantes do projeto devem ser registradas aqui somente quando sustentadas por evidência verificável.

## [Unreleased]

## [0.1.0] - 2026-09-17

### Added

- Suíte automatizada DUnitX consolidada com 57 testes distribuídos em 9 fixtures.
- Testes por processo para CommandLine e Security.
- Teste de componente para configuração e carregamento do serviço.
- Integração real com o Windows Service Control Manager (SCM) para Query, InstallRoundTrip, Lifecycle e Restart.
- `RickWinService.Integration.ServiceHost` como executável de serviço para os cenários Lifecycle e Restart.
- Validação de Restart com confirmação de substituição do processo do serviço por meio da mudança do PID.
- Documentação dedicada da estratégia, estrutura, execução e métricas da suíte em `docs/TESTING.md` e `docs/TESTING.pt-BR.md`.

### Changed

- Integração dos cenários SCM ao runner DUnitX principal.
- Consolidação do cenário de Restart no `RickWinService.SCM.Restart.TestHost`.
- Organização final do `RickWinService.groupproj` para os projetos necessários à suíte.
- Reorganização da documentação em `README.md` e documentos especializados em `docs/`.
- Separação da referência de API, linha de comando, arquitetura, testes e migração documental.

### Removed

- `RickWinService.SCM.Restart.Diagnostic.TestHost`, removido após a consolidação dos diagnósticos necessários no Restart Test Host canônico.
