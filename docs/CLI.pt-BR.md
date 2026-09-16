# Linha de comando

A interpretação da linha de comando está centralizada em `Rick.WinService.CommandLine`. A execução dos modos especiais é coordenada por `TRickWinServiceSetup.RunAsService`.

## Comandos reconhecidos

```text
/Install
/UnInstall
-RunService
/Silent
```

`FindCmdLineSwitch` é chamado com os prefixos `-` e `/` e comparação case-insensitive. Assim, os comandos pesquisados aceitam ambos os prefixos e não dependem de caixa.

## Precedência

`TRickWinServiceCommandLine.Command` testa os modos nesta ordem:

1. `INSTALL`;
2. `UNINSTALL`;
3. `RUNSERVICE`;
4. caso nenhum esteja presente, `Desktop`.

Consequentemente, se uma linha de comando contiver mais de um desses modos, o primeiro encontrado nessa ordem é o selecionado.

`/Silent` não participa da escolha do modo.

## Desktop

Sem `Install`, `Uninstall` ou `RunService`, `Command` retorna `Desktop` e `WinServiceSetup.RunAsService` retorna `False` sem iniciar o runtime do serviço.

Fluxo típico:

```text
Aplicacao.exe
  -> RunAsService
      -> Desktop
          -> retorna False
              -> aplicação consumidora pode chamar CreateForm
```

## Instalação

Exemplo:

```text
Aplicacao.exe /Install /Silent
```

Fluxo:

```text
RunAsService
  -> ExecuteInstallCommand
      -> RequireAdministrator
      -> OnBeforeInstall, se configurado
      -> TRickWinServiceInstaller.Install
          -> SCM
          -> descrição, quando informada
          -> tentativa de configurar Event Log
      -> OnAfterInstall, se a operação terminou sem exceção
```

O comando não usa `TServiceApplication.RegisterServices` para registrar o serviço. O Installer chama o SCM diretamente.

## Desinstalação

Exemplo:

```text
Aplicacao.exe /UnInstall /Silent
```

Fluxo:

```text
RunAsService
  -> ExecuteUninstallCommand
      -> RequireAdministrator
      -> OnBeforeUninstall, se configurado
      -> TRickWinServiceInstaller.Uninstall
          -> DeleteService no SCM
          -> tentativa de remover a origem do Event Log
      -> OnAfterUninstall, se a operação terminou sem exceção
```

## Execução como Windows Service

O Installer registra o `ImagePath` no formato:

```text
"<executavel>" -RunService
```

Quando o SCM inicia esse comando:

```text
RunAsService
  -> RunWindowsService
      -> Vcl.SvcMgr.Application
      -> cria TRickWinService
      -> associa callbacks configurados
      -> Application.Run
```

O `TRickWinService` mantém `OnExecute = ServiceExecute` no DFM. `ServiceExecute` processa solicitações enquanto `Terminated` for `False`.

## `/Silent`

`TRickWinServiceCommandLine.IsSilent` informa se o switch `SILENT` está presente.

No código atual, esse valor não altera o fluxo de `RunAsService`. Os comandos administrativos do `Setup` já capturam exceções e não apresentam UI própria; o caminho de compatibilidade de `IRickWinService.Install/Uninstall` acrescenta `/Silent` ao processo auxiliar.

## ExitCode

`ExecuteInstallCommand` e `ExecuteUninstallCommand` inicializam `System.ExitCode` com `0` e capturam qualquer `Exception` do comando.

`TRickWinServiceCommandLine.ExitCodeForException` aplica o seguinte mapeamento:

| Constante | Valor | Condição |
|---|---:|---|
| `RICK_WINSERVICE_EXIT_SUCCESS` | `0` | comando terminou sem exceção capturada |
| `RICK_WINSERVICE_EXIT_ADMIN_REQUIRED` | `10` | `ERickWinServiceAdministratorRequired` |
| `RICK_WINSERVICE_EXIT_OPERATION_ERROR` | `20` | qualquer outra `ERickWinServiceException` |
| `RICK_WINSERVICE_EXIT_UNEXPECTED_ERROR` | `99` | qualquer outra `Exception` |

Esse tratamento está explicitamente implementado nos caminhos `Install` e `Uninstall` do `Setup`. Esta documentação não estende essa garantia a falhas ocorridas dentro de `RunWindowsService`, porque esse caminho não usa a mesma fronteira `try/except`.

## Processo auxiliar de `IRickWinService`

`TRickWinServiceModel.Install` e `Uninstall` executam o binário configurado em `ExeName` por meio de `CreateProcess`.

Linhas de comando base:

```text
/Install /Silent
/UnInstall /Silent
```

O processo pai aguarda indefinidamente (`WaitForSingleObject(..., INFINITE)`), lê o código de saída e aplica:

- `0`: sucesso;
- `10`: lança `ERickWinServiceAdministratorRequired`;
- qualquer outro valor: lança `ERickWinServiceOperationException`.

Falhas ao criar o processo, aguardar o processo ou ler seu ExitCode também são convertidas em `ERickWinServiceOperationException`.

## Observação de segurança

Os caminhos de instalação e desinstalação exigem privilégio administrativo antes da operação principal. O framework não chama `runas` e não implementa elevação automática.
