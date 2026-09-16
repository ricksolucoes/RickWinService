# Migração

Este documento registra somente informações de migração que podem ser sustentadas pelo material fornecido. Ele **não reconstrói a história do projeto por inferência**.

## Limite histórico

Não foi fornecido um repositório Git, tag, release ou snapshot completo de uma versão pública anterior que permita reconstruir com segurança a evolução do Rick WinService.

O pacote atual contém alguns arquivos `.~1~` em `src/__history`, mas eles representam apenas backups locais de quatro units e não constituem uma baseline completa de release. Por esse motivo, não são usados para afirmar que uma determinada API, GUID, unit ou comportamento foi preservado entre versões públicas.

Afirmações históricas do antigo `Leia-me.md` que exigiriam comparação com uma versão anterior são classificadas abaixo como **Não confirmado** e não são promovidas a fatos de migração.

## Estado atual documentado

No estado fornecido, `src` contém 11 units `.pas`:

```text
Rick.WinService.pas
Rick.WinService.Types.pas
Rick.WinService.Interfaces.pas
Rick.WinService.Exceptions.pas
Rick.WinService.Security.pas
Rick.WinService.Manager.pas
Rick.WinService.Installer.pas
Rick.WinService.CommandLine.pas
Rick.WinService.Model.pas
Rick.WinService.Setup.pas
Rick.WinService.Service.pas
```

Além delas, existe `Rick.WinService.Service.dfm`.

A arquitetura atual está documentada em [ARCHITECTURE.md](ARCHITECTURE.md), sem inferir a estrutura de versões anteriores.

## Matriz de migração documental do antigo `Leia-me.md`

A matriz abaixo cobre todas as seções e informações relevantes do arquivo removido. O objetivo é demonstrar que o conteúdo foi migrado, corrigido, descartado de forma deliberada ou marcado como não confirmado antes da remoção da fonte concorrente.

| Conteúdo do `Leia-me.md` | Classificação | Destino/Ação | Evidência usada |
|---|---|---|---|
| Descrição: mesmo binário em modo Desktop ou Windows Service | Confirmado | `README.md` e `ARCHITECTURE.md` | `Setup.RunAsService`, `Service`, `CreateForm` |
| FMX por `PROJECT_FMX`; sem a diretiva usa VCL no Desktop | Confirmado | `README.md`, `API.md`, `ARCHITECTURE.md` | condicionais em `Rick.WinService.Setup` e `Rick.WinService.ApplicationFramework` |
| Exemplo básico com `WinServiceSetup`, `RunAsService` e `CreateForm` | Confirmado | `README.md` | contratos e implementação de `IRickWinServiceSetup` |
| Processamento principal em `OnStart`; finalização em `OnStop`/`OnShutdown` | Confirmado como orientação compatível com o runtime | `README.md` e `API.md` | callbacks associados por `RunWindowsService`; `ServiceExecute` reservado ao loop |
| `TService.OnExecute` não exposto como callback público | Confirmado | `README.md`, `API.md`, `ARCHITECTURE.md` | `IRickWinServiceSetup` não possui `OnExecute`; DFM liga `OnExecute = ServiceExecute` |
| Duas barreiras administrativas: consulta preventiva e validação nas operações mutáveis | Confirmado | `README.md` e `API.md` | `IsRunningAsAdministrator`, `RequireAdministrator`, fachada e Model/Installer |
| Framework não eleva automaticamente nem apresenta UI própria para o erro administrativo | Confirmado no código analisado | `README.md`, `API.md`, `CLI.md` | ausência de `runas`; exceções e ExitCode; units administrativas sem apresentação visual |
| Exemplo com `RickDialog` | Externo ao material fornecido | Descartado | nenhuma referência a `RickDialog` em `src` |
| Estados do serviço apresentados no exemplo | Confirmado, porém incompleto no documento antigo | Corrigido em `API.md` e `README.md` incluindo `NotInstalled` | `TRickWinServiceState` |
| `InstallService` | Confirmado | `README.md` e `API.md` | fachada `Rick.WinService` |
| `UninstallService` | Confirmado | `README.md` e `API.md` | fachada `Rick.WinService` |
| `StartService` | Confirmado | `README.md` e `API.md` | fachada `Rick.WinService` |
| `StopService` | Confirmado | `README.md` e `API.md` | fachada `Rick.WinService` |
| `RestartService` | Confirmado | `README.md` e `API.md` | fachada `Rick.WinService` |
| Exemplos de handlers `TfrmMain.btn*Click` que apenas chamavam as cinco operações administrativas | Confirmado, porém específico de UI e redundante | Simplificado para chamadas diretas em `README.md`; referência completa em `API.md` | os handlers não acrescentavam comportamento além das funções da fachada |
| Fluxo normal para Desktop | Confirmado | `ARCHITECTURE.md` | `CommandLine.Command` e `RunAsService` |
| Fluxo `-RunService` para `TService` | Confirmado | `README.md`, `CLI.md`, `ARCHITECTURE.md` | `Installer.BinaryPath`, `RunWindowsService`, `TRickWinService` |
| `ImagePath` com executável entre aspas e `-RunService` | Confirmado | `README.md`, `CLI.md`, `ARCHITECTURE.md` | `TRickWinServiceInstaller.BinaryPath` |
| Organização interna: `Rick.WinService.Types` | Parcialmente correta, mas lista antiga não inclui `TRickWinServiceOperation` | Corrigido em `API.md` e `ARCHITECTURE.md` | `Rick.WinService.Types` atual |
| Organização interna: `Rick.WinService.Interfaces` | Confirmado para o estado atual | `API.md` e `ARCHITECTURE.md` | unit atual |
| `Rick.WinService.Model` implementa `IRickWinService` | Confirmado | `API.md` e `ARCHITECTURE.md` | declaração de `TRickWinServiceModel` |
| `Rick.WinService.Setup` implementa `IRickWinServiceSetup` | Confirmado | `API.md` e `ARCHITECTURE.md` | declaração de `TRickWinServiceSetup` |
| `Rick.WinService` é a fachada procedural | Confirmado | `README.md`, `API.md`, `ARCHITECTURE.md` | interface da unit |
| `Manager` encapsula acesso ao SCM | Confirmado | `ARCHITECTURE.md` | `TRickWinServiceManager` |
| `Security` valida privilégios administrativos | Confirmado | `ARCHITECTURE.md` | `TRickWinServiceSecurity` |
| `Service` contém o `TService` de runtime | Confirmado | `ARCHITECTURE.md` | `TRickWinService` |
| `Exceptions` contém a hierarquia tipada | Confirmado | `API.md` e `ARCHITECTURE.md` | `Rick.WinService.Exceptions` |
| Diagrama antigo `Types -> Interfaces -> Model / Setup -> fachada` | Divergente/incompleto | Substituído em `ARCHITECTURE.md` | `uses` e implementação das 11 units atuais |
| Afirmação de que `Manager`, `Security` e `Service` não dependem das camadas superiores | Parcialmente imprecisa | Substituída por grafo real em `ARCHITECTURE.md` | `Manager` depende de `CommandLine`, `Exceptions` e `Types`; demais dependências atuais |
| “Antes havia 7 units” | Histórico sem baseline completa | **Não confirmado**; não promovido a fato | ausência de repositório/tag/release ou snapshot completo anterior |
| “A reorganização resultou em 9 units” | Divergente do estado atual | Descartado como descrição atual | existem 11 units `.pas` no pacote atual |
| Divisão de `Rick.WinService.Model.Interfaces` | Histórico sem baseline completa | **Não confirmado** | não há versão anterior completa para comparação |
| Divisão de `Rick.WinService.Setup.Interfaces` | Histórico sem baseline completa | **Não confirmado** | não há versão anterior completa para comparação |
| Renome de `Rick.WinService.Model.Default` para `Rick.WinService.Model` | Histórico sem baseline completa | **Não confirmado** | não há versão anterior completa para comparação |
| “Nenhuma assinatura pública foi alterada” | Histórico comparativo | **Não confirmado** | exige comparação com baseline anterior |
| “GUIDs foram preservados” | Histórico comparativo | **Não confirmado** | GUIDs atuais são conhecidos, mas preservação exige baseline anterior |
| “Nenhuma regra de negócio ou comportamento observável foi alterado” | Histórico comparativo | **Não confirmado** | exige comparação comportamental com baseline anterior |
| Instrução para trocar `uses Rick.WinService.Setup.Interfaces` por `Rick.WinService` | Migração histórica dependente de unit anterior | **Não confirmado**; omitida do guia atual | unit anterior não está disponível em uma baseline completa |
| “Identificadores públicos continuam com a mesma assinatura” | Histórico comparativo | **Não confirmado** | exige comparação com baseline anterior |

## Auditoria da remoção do `Leia-me.md`

Resultado da matriz:

- conteúdo funcional atual: migrado ou corrigido nos documentos canônicos;
- conteúdo externo sem suporte no pacote: descartado deliberadamente;
- afirmações históricas sem baseline completa: não promovidas a fatos e identificadas como **Não confirmado** na matriz;
- informações estruturais divergentes: substituídas pela estrutura atual observada em `src`.

Com todos os blocos do documento antigo classificados, ele deixa de ser necessário como segunda fonte documental.

## Pontos históricos não confirmados

Permanecem não confirmados, por ausência de baseline histórica completa:

- quantidade de units em uma versão anterior;
- origem histórica das units atuais;
- renomes de units entre releases;
- preservação de GUIDs em relação a versões anteriores;
- preservação de assinaturas públicas em relação a versões anteriores;
- preservação integral de regras de negócio e comportamento em relação a versões anteriores;
- instruções de migração baseadas em nomes de units que não existem no snapshot atual.

Se futuramente forem fornecidos commits, tags, releases ou snapshots completos anteriores, esses itens poderão ser reavaliados por comparação direta.
