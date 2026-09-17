# Testes

Este documento descreve a suíte de testes atualmente mantida para o RickWinService, incluindo testes DUnitX, Test Hosts executados em processos separados e cenários de integração real com o Windows Service Control Manager (SCM).

A documentação registra somente o comportamento e as validações observadas no estado atual do projeto. Os resultados apresentados abaixo correspondem ao ambiente em que a suíte foi efetivamente compilada e executada; eles não constituem garantia de comportamento em qualquer máquina, versão do Windows ou configuração do Delphi.

## Escopo da suíte

A suíte cobre quatro níveis complementares:

- **testes unitários**, para contratos, tipos, configuração e comportamento isolado;
- **testes por processo**, para cenários em que argumentos ou privilégios dependem do processo real;
- **teste de componente**, incluindo a criação de `TRickWinService` e o carregamento do `OnExecute` definido no DFM;
- **integração real com o SCM**, incluindo consulta, instalação, inicialização, parada, reinicialização e remoção de serviços temporários.

O código de produção em `../src` é consumido pela suíte como dependência e não faz parte da organização dos testes descrita neste documento.

## Ambiente validado

A validação registrada foi executada com:

```text
Windows
Delphi 10.+ ou superior
Target Win32
DUnitX
```

Os testes que modificam o SCM precisam de privilégios administrativos. Por esse motivo, para executar a suíte completa, o runner DUnitX deve ser iniciado como Administrador.

Os testes unitários, os Test Hosts de CommandLine, a validação de Security e a consulta SCM read-only não dependem, por contrato da própria suíte, de uma execução elevada. A fixture de Security adapta a expectativa ao estado real de elevação do processo.

## Estrutura

```text
tests/
├── RickWinService.Tests.dpr
├── RickWinService.Tests.dproj
├── RickWinService.Tests.res
├── RickWinService.groupproj
└── src/
    ├── units/
    │   ├── Rick.WinService.Tests.CommandLine.pas
    │   ├── Rick.WinService.Tests.CommandLine.Process.pas
    │   ├── Rick.WinService.Tests.Exceptions.pas
    │   ├── Rick.WinService.Tests.Facade.pas
    │   ├── Rick.WinService.Tests.Model.pas
    │   ├── Rick.WinService.Tests.Security.Process.pas
    │   ├── Rick.WinService.Tests.Service.Component.pas
    │   └── Rick.WinService.Tests.Setup.pas
    ├── component/
    │   ├── RickWinService.CommandLine.TestHost.*
    │   └── RickWinService.Security.TestHost.*
    └── integration/
        ├── src/
        |    └── Rick.WinService.Tests.Scm.Process.pas
        ├── RickWinService.Integration.ServiceHost.*
        ├── RickWinService.SCM.Query.TestHost.*
        ├── RickWinService.SCM.InstallRoundTrip.TestHost.*
        ├── RickWinService.SCM.Lifecycle.TestHost.*
        └── RickWinService.SCM.Restart.TestHost.*
```

### `tests/src/units`

Contém as fixtures DUnitX responsáveis pelas validações unitárias, por processo e de componente.

### `tests/src/component`

Contém executáveis auxiliares usados quando o comportamento precisa ser observado em um processo real:

- `RickWinService.CommandLine.TestHost`;
- `RickWinService.Security.TestHost`.

### `tests/src/integration`

Contém a fixture que orquestra os testes reais do SCM, os Test Hosts dos cenários de integração e o executável de serviço usado nos cenários Lifecycle e Restart.

## Runner DUnitX

O ponto de entrada da suíte é:

```text
RickWinService.Tests.dpr
```

O runner utiliza `DUnitX.Loggers.GUI.VCL` e registra nove fixtures:

| Fixture | Categoria | Testes |
|---|---|---:|
| `CommandLine` | Unitário | 4 |
| `CommandLine.Process` | Processo | 19 |
| `Exceptions` | Unitário | 6 |
| `Facade` | Unitário | 5 |
| `Model` | Unitário | 6 |
| `Security.Process` | Processo | 1 |
| `Service.Component` | Componente | 4 |
| `Setup` | Unitário | 8 |
| `Scm.Process` | Integração SCM | 4 |
| **Total** |  | **57** |

## Testes por processo

### CommandLine

`Rick.WinService.Tests.CommandLine.Process` inicia `RickWinService.CommandLine.TestHost.exe` com combinações reais de argumentos.

Os 19 testes cobrem, entre outros pontos:

- execução Desktop sem argumentos;
- `/Silent`;
- Install, Uninstall e RunService;
- variantes com prefixo `-` e `/`;
- comparação case-insensitive;
- precedência entre comandos;
- permanência em Desktop diante de switch desconhecido.

O Test Host utiliza códigos de saída semânticos para representar o comando e o modo Silent. Portanto, **não existe uma convenção global de `ExitCode = 100` para todos os Test Hosts do projeto**.

### Security

`Rick.WinService.Tests.Security.Process` inicia `RickWinService.Security.TestHost.exe`.

O Test Host compara:

```text
TRickWinServiceSecurity.IsRunningAsAdministrator
IsRunningAsAdministrator
```

e valida `RequireAdministrator` conforme o token real do processo.

O resultado esperado muda de acordo com a elevação:

```text
100 = processo não elevado validado
200 = processo elevado validado
```

## Teste de componente do serviço

`Rick.WinService.Tests.Service.Component` valida a criação do componente de serviço e cobre:

- aplicação do `ServiceName`;
- aplicação do `ServiceTitle`;
- associação do service controller;
- carregamento de `ServiceExecute` a partir do DFM.

Esse teste não inicia um serviço real no SCM.

## Integração real com o SCM

A fixture:

```text
Rick.WinService.Tests.Scm.Process
```

executa quatro Test Hosts em processos separados.

A consulta read-only possui timeout externo de `30000 ms`. Os hosts que modificam o SCM possuem timeout externo de `180000 ms`. Se um host ultrapassar o timeout, o runner encerra o processo e registra falha.

Para os quatro Test Hosts SCM, a fixture utiliza:

```text
ExitCode = 100
```

como indicação de sucesso do cenário completo.

### Query

Executável:

```text
RickWinService.SCM.Query.TestHost.exe
```

Usa um nome de serviço reservado para o teste e valida, por meio de `TRickWinServiceManager` e `IRickWinService`, que um serviço deliberadamente ausente é reportado como:

```text
NotInstalled
IsInstalled = False
IsRunning = False
```

É um cenário read-only.

### InstallRoundTrip

Executável:

```text
RickWinService.SCM.InstallRoundTrip.TestHost.exe
```

Fluxo:

```text
pré-condições
    ↓
Install
    ↓
validação via Manager
    ↓
validação via Model
    ↓
Uninstall
    ↓
NotInstalled
```

O serviço é instalado e removido sem ser iniciado.

### Lifecycle

Executável:

```text
RickWinService.SCM.Lifecycle.TestHost.exe
```

Usa:

```text
RickWinService.Integration.ServiceHost.exe
```

como executável do serviço temporário.

Fluxo validado:

```text
Install
  ↓
Stopped
  ↓
Start
  ↓
Running
  ↓
Stop
  ↓
Stopped
  ↓
Uninstall
  ↓
NotInstalled
```

As validações de estado utilizam tanto o Manager quanto o Model onde aplicável.

### Restart

Executável:

```text
RickWinService.SCM.Restart.TestHost.exe
```

Também utiliza `RickWinService.Integration.ServiceHost.exe`.

Fluxo:

```text
Install
  ↓
Start
  ↓
Running
  ↓
PID inicial
  ↓
Restart
  ↓
Running
  ↓
novo PID
  ↓
Stop
  ↓
Uninstall
```

O teste não considera apenas o retorno ao estado `Running`. Ele consulta o PID associado ao serviço antes e depois do `Restart` e exige:

```text
PID inicial <> 0
PID após Restart <> 0
PID após Restart <> PID inicial
```

Assim, o cenário valida que o processo do serviço foi substituído durante o Restart executado no ambiente de teste.

## `Integration.ServiceHost`

`RickWinService.Integration.ServiceHost.exe` é um executável mínimo configurado com `WinServiceSetup`.

Ele é utilizado como processo de serviço pelos cenários Lifecycle e Restart. Quando iniciado pelo SCM com `-RunService`, entra no runtime de serviço do RickWinService.

Ele não é uma fixture DUnitX; é infraestrutura da integração.

## Serviços temporários e cleanup

Os cenários SCM usam nomes de serviço iniciados por:

```text
RickWinService_IntegrationTest_
```

Os Test Hosts mutáveis implementam cleanup defensivo quando o cenário falha. Entretanto, uma interrupção externa do processo durante uma operação SCM pode deixar um serviço ou processo temporário no Windows.

Para inspecionar resíduos:

```powershell
Get-CimInstance Win32_Service |
  Where-Object {
    $_.Name -like "RickWinService_IntegrationTest_*"
  } |
  Select-Object Name, State, ProcessId, PathName
```

Antes de remover manualmente qualquer entrada, confirme que ela pertence à suíte de integração do RickWinService.

## Build

Abra:

```text
tests/RickWinService.groupproj
```

e execute:

```text
Build All Projects
```

O grupo contém oito projetos:

1. `RickWinService.Tests`;
2. `RickWinService.CommandLine.TestHost`;
3. `RickWinService.Security.TestHost`;
4. `RickWinService.SCM.Query.TestHost`;
5. `RickWinService.SCM.InstallRoundTrip.TestHost`;
6. `RickWinService.Integration.ServiceHost`;
7. `RickWinService.SCM.Lifecycle.TestHost`;
8. `RickWinService.SCM.Restart.TestHost`.

O runner e os executáveis auxiliares são configurados para serem gerados em `App\<Config>` relativo ao repositório. Essa disposição permite que as fixtures localizem os Test Hosts no mesmo diretório do runner.

## Execução

Para executar a suíte completa:

1. compile o grupo;
2. inicie `RickWinService.Tests.exe` como Administrador;
3. execute a suíte pelo runner gráfico DUnitX.

Executar como Administrador é necessário para os três cenários SCM mutáveis:

```text
InstallRoundTrip
Lifecycle
Restart
```

## Baseline validado

Em **17/09/2026**, no ambiente de validação utilizado durante a revisão do projeto, o `Build All Projects` terminou com:

```text
Success
```

A execução completa do runner DUnitX reportou:

```text
Tests Found   : 57
Tests Ignored : 0
Tests Passed  : 57
Tests Leaked  : 0
Tests Failed  : 0
Tests Errored : 0
```

Esses valores registram a execução observada naquele ambiente. `Tests Leaked : 0` é o resultado reportado pelo DUnitX para essa execução e não deve ser interpretado como prova geral de ausência de vazamentos em qualquer cenário possível.

## Method Toxicity Metrics

Foi fornecido um CSV real exportado pelo **RAD Studio Method Toxicity Metrics** para a suíte.

O relatório contém **84 métodos** distribuídos pelas **9 units `.pas`** registradas no runner DUnitX.

Os maiores valores observados no relatório foram:

| Métrica | Máximo observado | Threshold do projeto |
|---|---:|---:|
| `Length` | 10 | 20 |
| `Parameters` | 3 | 6 |
| `If Depth` | 1 | 5 |
| `Cyclomatic Complexity` | 2 | 6 |
| `Toxicity` | 0,346 | 1 |

Nenhum dos métodos presentes nesse relatório ultrapassou os thresholds configurados para o projeto.

### Limitação da medição

O CSV fornecido não contém os métodos implementados diretamente nos arquivos `.dpr` dos Test Hosts.

Consequentemente:

- os valores acima constituem **métrica real** para os métodos presentes nas 9 units `.pas` do relatório;
- os Test Hosts `.dpr` foram compilados e exercitados durante as validações correspondentes;
- o valor composto real de `Toxicity` dos métodos declarados nos `.dpr` é **Não confirmado**.

Não deve ser atribuído aos `.dpr` um valor de Toxicity estimado ou derivado manualmente.

## Manutenção da suíte

Ao adicionar ou alterar testes:

- mantenha `RickWinService.Tests.dpr` sincronizado com as fixtures;
- mantenha `RickWinService.groupproj` sincronizado com os Test Hosts necessários;
- preserve nomes exclusivos para serviços temporários;
- mantenha o cleanup defensivo dos cenários SCM;
- atualize a contagem documentada somente depois de confirmar a suíte real;
- registre resultados de build, execução e Method Toxicity somente quando efetivamente medidos.
