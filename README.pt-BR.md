# ⚙️ Rick WinService

<p align="center">
  <strong>Framework Delphi para executar a mesma aplicação como Desktop ou Windows Service.</strong>
</p>

<p align="center">
  <a href="https://docwiki.embarcadero.com/RADStudio/en/Delphi_Language_Guide_Index">
    <img src="https://img.shields.io/badge/Language-Object%20Pascal-5C2D91?style=for-the-badge&logo=delphi&logoColor=white" alt="Object Pascal">
  </a>
  <a href="https://www.embarcadero.com/products/delphi">
    <img src="https://img.shields.io/badge/IDE-Delphi-E62431?style=for-the-badge&logo=delphi&logoColor=white" alt="IDE Delphi">
  </a>
  <a href="https://docwiki.embarcadero.com/RADStudio/en/FireMonkey_Application_Platform">
    <img src="https://img.shields.io/badge/UI-FireMonkey-2563EB?style=for-the-badge" alt="FireMonkey">
  </a>
  <a href="#-visão-geral">
    <img src="https://img.shields.io/badge/UI-VCL-0E7490?style=for-the-badge" alt="VCL">
  </a>
</p>

<p align="center">
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/License-Revocable%20Software%20License-8250DF?style=flat-square" alt="License">
  </a>
  <img src="https://img.shields.io/badge/Owner-RickSolu%C3%A7%C3%B5es-1F6FEB?style=flat-square" alt="RickSoluções">
  <img src="https://img.shields.io/badge/Platform-Windows-0078D4?style=flat-square&logo=windows&logoColor=white" alt="Windows">
</p>

🌐 [English](README.md) | **Português (Brasil)**

## 📖 Visão geral

**Rick WinService** é um framework Delphi para executar o mesmo binário em modo **Desktop**, utilizando **VCL** ou **FireMonkey**, ou diretamente como um **Windows Service**.

O framework fornece uma fachada de alto nível para:

- instalar e remover serviços;
- iniciar, parar e reiniciar serviços;
- consultar o estado do serviço;
- identificar se o serviço está instalado;
- validar privilégios administrativos;
- interpretar comandos administrativos;
- executar a aplicação como Desktop ou Windows Service.

A aplicação consumidora não precisa manipular diretamente o **Windows Service Control Manager — SCM**.



## ✨ Recursos

- 🖥️ Execução do mesmo binário em modo **Desktop** ou **Windows Service**.
- 🔷 Suporte Desktop para **VCL**.
- 🔶 Suporte Desktop para **FireMonkey / FMX**.
- 🔀 Seleção do framework Desktop através de `PROJECT_FMX`.
- 🪟 Integração nativa com o **Windows Service Control Manager — SCM**.
- 📦 Instalação e desinstalação do serviço diretamente pelo SCM.
- ▶️ Operações `Start`, `Stop` e `Restart`.
- 🔄 Acompanhamento das transições de estado reportadas pelo SCM.
- 🔎 Consulta de instalação, estado e execução do serviço.
- 🛡️ Validação de privilégios administrativos.
- ⚠️ Hierarquia de exceções tipadas.
- 🧩 Informações de contexto da operação e erros nativos do Windows.
- ⌨️ Suporte aos comandos `/Install`, `/UnInstall`, `-RunService` e `/Silent`.
- 🚦 Códigos de saída específicos para operações administrativas.
- 🧱 Fachada pública simplificada através da unit `Rick.WinService`.


## ⚙️ Instalação

* Opcional 
  > Para facilitar, recomendo utilizar o [**Boss**](https://github.com/HashLoad/boss) (Gerenciador de Dependências para Delphi) para a instalação, bastando executar o comando abaixo em um terminal (como o Windows PowerShell, por exemplo):

  ```sh
  boss install github.com/ricksolucoes/RickWinService
  ```

## 🎫Instalação manual para Delphi
Caso opte pela instalação manual, basta adicionar as seguintes pastas ao seu projeto, em *Project > Options > Building > Delphi Compiler > Search path*:
```
../RickWinService/src
```

## 🚀 Quick Start

### Configure o serviço

Para utilizar o framework, adicione as configurações abaixo diretamente no arquivo .dpr do seu projeto.

1. Importe a fachada principal:

```delphi
uses
  Rick.WinService;
```

2. **Configure o ciclo de vida do serviço:**  

Defina os parâmetros do serviço antes de determinar se o processo será executado como **Windows Service** ou como uma aplicação **Desktop**:

```delphi
begin
  WinServiceSetup
    .ServiceName('MeuServico')
    .ServiceTitle('Meu Serviço')
    .ServiceDetail('Descrição do serviço')
    .OnStart(OnStartService)
    .OnStop(OnStopService)
    .OnShutdown(OnShutdownService);

  if not WinServiceSetup.RunAsService then
    WinServiceSetup.CreateForm(TfrmMain, frmMain);
end.
```
#### 💥Importante

> **Regra de Negócio:** O processamento principal da sua aplicação deve ser iniciado no evento `OnStart` e finalizado em `OnStop` ou `OnShutdown`.

> **Comportamento Interno:** O evento nativo `TService.OnExecute` é gerenciado internamente pela classe `TRickWinService.ServiceExecute` para processar as solicitações enviadas pelo **SCM**. Evite sobrescrevê-lo manualmente.


## 🔥 FireMonkey

Para utilizar **FireMonkey** no modo Desktop, defina:

```text
PROJECT_FMX
```

em:

```text
Project Options
└── Delphi Compiler
    └── Conditional defines
```

Com `PROJECT_FMX` definido, o framework utiliza:

```delphi
FMX.Forms
```

Sem essa diretiva, o modo Desktop utiliza **VCL**.

💥 Importante

  > O runtime responsável pela execução como Windows Service continua baseado em `Vcl.SvcMgr`, independentemente do framework Desktop utilizado pela aplicação.


## 🧩 API principal

A unit:

```delphi
Rick.WinService
```

expõe a fachada pública do framework.

### Configuração

```text
WinServiceSetup
```

### Ambiente da aplicação

```text
ApplicationFramework
ApplicationFrameworkName
IsVCLApplication
IsFMXApplication
```

### Consulta do serviço

```text
IsInstalled
ServiceState
IsRunning
IsRunningAsAdministrator
```

### Administração

```text
InstallService
UninstallService
StartService
StopService
RestartService
```

## 🔎 Consultando o estado do serviço

```delphi
uses
  Rick.WinService,
  Rick.WinService.Types;

var
  LState: TRickWinServiceState;
begin
  if IsInstalled then
  begin
    LState := ServiceState;

    if LState = TRickWinServiceState.Running then
    begin
      // Serviço em execução.
    end;
  end;
end;
```

## 🛡️ Privilégios administrativos

As operações que modificam o estado do serviço exigem que o processo já esteja sendo executado com privilégios administrativos:

```text
InstallService
UninstallService
StartService
StopService
RestartService
```

O framework **não tenta elevar automaticamente o processo**.

Exemplo:

```delphi
if not IsRunningAsAdministrator then
  Exit;

StartService;
```

### 📛 Atenção
> A aplicação consumidora é responsável por decidir como solicitar ou orientar o usuário sobre a necessidade de privilégios administrativos.


## 🛠️ Administração do serviço

As principais operações administrativas são:

```delphi
InstallService;

StartService;

StopService;

RestartService;

UninstallService;
```

### 📦 Instalação

Durante a instalação, o serviço é registrado no SCM com o `ImagePath`:

```text
"<caminho completo do executável>" -RunService
```

Quando `ServiceDetail` não está vazio, o instalador solicita ao SCM a configuração da descrição do serviço.

O instalador também tenta configurar uma origem no **Windows Event Log**.

### 🗑️ Desinstalação

Durante a desinstalação:

1. o serviço é removido do SCM;
2. o framework tenta remover a origem correspondente do Windows Event Log.



## 🔄 Controle de estado

As operações:

```text
StartService
StopService
```

aguardam as transições de estado reportadas pelo SCM.

Internamente, o `Manager` utiliza:

```text
QueryServiceStatusEx
dwCheckPoint
dwWaitHint
```

O timeout interno padrão é de:

```text
30 segundos
```

## 💻 Linha de comando

O framework reconhece os seguintes comandos:

| Comando | Descrição |
|---|---|
| `/Install` | Instala o serviço |
| `/UnInstall` | Remove o serviço |
| `-RunService` | Executa o processo como Windows Service |
| `/Silent` | Indica execução administrativa silenciosa |

A comparação dos comandos é **case-insensitive**.

São aceitos os prefixos:

```text
/
-
```

### Precedência

Quando mais de um modo especial é informado, a implementação avalia os comandos nesta ordem:

```text
1. Install
2. Uninstall
3. RunService
```



## 🧪 Exemplos de linha de comando

### Instalar

```console
Aplicacao.exe /Install /Silent
```

### Desinstalar

```console
Aplicacao.exe /UnInstall /Silent
```

### Executar como serviço

```console
Aplicacao.exe -RunService
```



## 🚦 Exit Codes

Durante `/Install` e `/UnInstall`, `RunAsService` captura as exceções e converte o resultado em `System.ExitCode`.

| ExitCode | Significado |
|:---|---|
| `0` | ✅ Operação concluída sem exceção |
| `10` | 🛡️ Privilégio administrativo necessário |
| `20` | ⚠️ Exceção controlada derivada de `ERickWinServiceException` |
| `99` | ❌ Exceção não classificada pelo framework |

#### 💥Importante

> `/Silent` é reconhecido por `TRickWinServiceCommandLine.IsSilent`, porém o framework não apresenta UI própria durante os comandos administrativos, independentemente desse switch.

📚 Mais detalhes em [`docs/CLI.pt-BR.md`](docs/CLI.pt-BR.md).

## ⚠️ Exceções

A hierarquia pública de exceções está disponível em:

```delphi
Rick.WinService.Exceptions
```

### Hierarquia

```text
ERickWinServiceException
│
├── ERickWinServiceSecurityException
│   └── ERickWinServiceAdministratorRequired
│
└── ERickWinServiceOperationException
    ├── ERickWinServiceScmException
    │
    └── ERickWinServiceStateException
        └── ERickWinServiceTimeoutException
```

### Tratamento estruturado

```delphi
uses
  Rick.WinService,
  Rick.WinService.Exceptions;

begin
  try
    StartService;
  except
    on E: ERickWinServiceAdministratorRequired do
    begin
      // O consumidor decide como orientar o usuário.
    end;

    on E: ERickWinServiceException do
    begin
      // Falha controlada pelo framework.
    end;
  end;
end;
```

📚 Mais detalhes em [`docs/API.pt-BR.md`](docs/API.pt-BR.md).



## 🏗️ Arquitetura

A implementação separa as responsabilidades relacionadas a:

- fachada pública;
- configuração;
- runtime;
- interpretação da linha de comando;
- gerenciamento do SCM;
- instalação;
- segurança;
- contratos;
- tipos;
- exceções.

### Visão simplificada

```text
Rick.WinService
│
├── Setup
│   ├── CommandLine
│   └── Service
│
├── Model
│   └── Manager
│
├── Installer
│   └── Manager
│
└── Security
```

A descrição completa das **11 units `.pas`**, do arquivo **DFM** e das dependências internas está disponível em:

📚 [`docs/ARCHITECTURE.pt-BR.md`](docs/ARCHITECTURE.pt-BR.md)



## 📚 Documentação

| Documento | Descrição |
|---|---|
| 📘 [`docs/API.pt-BR.md`](docs/API.pt-BR.md) | Fachada, contratos, tipos, callbacks e exceções |
| 💻 [`docs/CLI.pt-BR.md`](docs/CLI.pt-BR.md) | Switches, precedência e códigos de saída |
| 🏗️ [`docs/ARCHITECTURE.pt-BR.md`](docs/ARCHITECTURE.pt-BR.md) | Responsabilidades, dependências e fluxos internos |
| 🔄 [`docs/MIGRATION.pt-BR.md`](docs/MIGRATION.pt-BR.md) | Histórico comprovável e auditoria da documentação anterior |
| 📝 [`CHANGELOG.pt-BR.md`](CHANGELOG.pt-BR.md) | Alterações ainda não associadas a uma release comprovada |



## 📂 Estrutura da documentação

```text
.
├── src/
│   └── ...
│
├── docs/
│   ├── API.md
│   ├── ARCHITECTURE.md
│   ├── CLI.md
│   ├── MIGRATION.md
│   ├── API.pt-BR.md
│   ├── ARCHITECTURE.pt-BR.md
│   ├── CLI.pt-BR.md
│   └── MIGRATION.pt-BR.md
│
├── CHANGELOG.md
├── LICENSE
├── README.md
├── CHANGELOG.pt-BR.md
├── LICENSE.pt-BR
└── README.pt-BR.md
```

## 📜 Licença

Este projeto é distribuído sob uma licença revogável (**Revocable Software License**). 

Antes de utilizar o software, consulte o arquivo [`LICENSE-pt-BR`](LICENSE-pt-BR) para conhecer todos os termos, restrições de uso e permissões.

<div align="center">

## ⚙️ RickWinService

**Windows Service simplificado para aplicações Delphi.**

Desenvolvido pela **RickSoluções**

<br>

[🇺🇸 Read the Official English Version](./README.md)

