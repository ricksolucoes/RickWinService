unit Rick.WinService.Security;
(*
  ============================================================================== 
  Unit: Rick.WinService.Security
  ============================================================================== 

  RESPONSABILIDADE

  Centraliza as verificações de segurança utilizadas pelo Rick WinService para
  determinar se o processo atual possui privilégios administrativos efetivos.

  Esta unit é independente de VCL e FMX e pode ser utilizada por qualquer tipo
  de aplicação Windows suportada pelo framework.

  ------------------------------------------------------------------------------

  VERIFICAÇÃO DE ELEVAÇÃO

  A implementação consulta o token efetivo do processo através da API
  CheckTokenMembership e verifica se o SID BUILTIN\\Administrators está
  habilitado.

  Essa abordagem é importante em ambientes com UAC. Um usuário pode pertencer
  ao grupo Administradores e, ainda assim, executar a aplicação com um token
  filtrado. Nesse cenário, a função retorna False até que o processo seja
  iniciado com privilégios administrativos efetivos.

  ------------------------------------------------------------------------------

  COMPATIBILIDADE DELPHI 10.2+

  Algumas declarações utilizadas pela WinAPI não são expostas de forma
  uniforme entre versões do Delphi. Para manter compatibilidade com Delphi
  10.2 Tokyo e versões posteriores:

  - SECURITY_NT_AUTHORITY é declarado localmente;
  - SECURITY_BUILTIN_DOMAIN_RID é declarado localmente;
  - DOMAIN_ALIAS_RID_ADMINS é declarado localmente;
  - CheckTokenMembership é importado diretamente de advapi32.dll.

  Nenhum recurso de linguagem posterior ao Delphi 10.2 é utilizado.

  ------------------------------------------------------------------------------

  POLÍTICA DO FRAMEWORK

  IsRunningAsAdministrator apenas consulta o estado atual.

  RequireAdministrator aplica a política defensiva do Rick WinService. Quando
  o processo não está elevado, o método lança
  ERickWinServiceAdministratorRequired e nenhuma operação administrativa deve
  prosseguir.

  O framework não mostra janelas e não tenta elevar automaticamente o processo.

  Exemplo:

    if TRickWinServiceSecurity.IsRunningAsAdministrator then
      ...;

    TRickWinServiceSecurity.RequireAdministrator('instalar o serviço');

  ============================================================================== 
*)

interface

type
  /// <summary>
  /// Serviço estático responsável pela validação de privilégios do processo.
  /// </summary>
  TRickWinServiceSecurity = class sealed
  strict private
    /// <summary>
    /// Executa a consulta do token efetivo contra o grupo Administradores.
    /// </summary>
    /// <returns>
    /// True quando o SID do grupo Administradores está habilitado no token
    /// efetivo; caso contrário, False.
    /// </returns>
    class function CheckAdministratorMembership: Boolean; static;
  public
    /// <summary>
    /// Informa se o processo atual está executando com privilégios
    /// administrativos efetivos.
    /// </summary>
    /// <returns>
    /// True quando o processo possui o grupo Administradores habilitado em seu
    /// token efetivo; caso contrário, False.
    /// </returns>
    /// <exception cref="ERickWinServiceSecurityException">
    /// Lançada quando o Windows não permite determinar o estado de segurança
    /// do processo.
    /// </exception>
    class function IsRunningAsAdministrator: Boolean; static;

    /// <summary>
    /// Garante que o processo atual possua privilégios administrativos antes
    /// de permitir a continuidade de uma operação sensível.
    /// </summary>
    /// <param name="AOperation">
    /// Descrição da operação que será incluída na exceção quando o processo não
    /// estiver elevado.
    /// </param>
    /// <exception cref="ERickWinServiceAdministratorRequired">
    /// Lançada quando o processo atual não possui privilégios administrativos.
    /// </exception>
    /// <exception cref="ERickWinServiceSecurityException">
    /// Lançada quando o Windows não permite determinar o estado de segurança.
    /// </exception>
    class procedure RequireAdministrator(
      const AOperation: string); static;
  end;

implementation

uses
  System.SysUtils,

  Winapi.Windows,

  Rick.WinService.Exceptions;

const
  // Autoridade NT utilizada na composição do SID BUILTIN\\Administrators.
  _SECURITY_NT_AUTHORITY: TSIDIdentifierAuthority =
    (Value: (0, 0, 0, 0, 0, 5));

  // Domínio BUILTIN do Windows.
  _SECURITY_BUILTIN_DOMAIN_RID = $00000020;

  // Grupo local Administrators dentro do domínio BUILTIN.
  _DOMAIN_ALIAS_RID_ADMINS = $00000220;

/// <summary>
/// Importação explícita de CheckTokenMembership para manter compatibilidade
/// com versões do Delphi que não expõem a função em Winapi.Windows.
/// </summary>
function CheckTokenMembership(
  TokenHandle: THandle;
  SidToCheck: PSID;
  var IsMember: BOOL
): BOOL; stdcall;
  external 'advapi32.dll' name 'CheckTokenMembership';

{ TRickWinServiceSecurity }

class function TRickWinServiceSecurity.CheckAdministratorMembership: Boolean;
var
  LAdministratorsGroup: PSID; // SID temporário de BUILTIN\\Administrators.
  LIsMember: BOOL;            // Resultado retornado pela WinAPI.
  LErrorCode: DWORD;          // Código de erro preservado para diagnóstico.
begin
  LAdministratorsGroup := nil;
  LIsMember := False;

  if not AllocateAndInitializeSid(
    _SECURITY_NT_AUTHORITY,
    2,
    _SECURITY_BUILTIN_DOMAIN_RID,
    _DOMAIN_ALIAS_RID_ADMINS,
    0,
    0,
    0,
    0,
    0,
    0,
    LAdministratorsGroup
  ) then
  begin
    LErrorCode := GetLastError;

    raise ERickWinServiceSecurityException.CreateFmt(
      'Não foi possível criar o identificador do grupo Administradores. ' +
      'Código do Windows: %d. %s',
      [LErrorCode, SysErrorMessage(LErrorCode)]
    );
  end;

  try
    if not CheckTokenMembership(
      0,
      LAdministratorsGroup,
      LIsMember
    ) then
    begin
      LErrorCode := GetLastError;

      raise ERickWinServiceSecurityException.CreateFmt(
        'Não foi possível verificar os privilégios administrativos do ' +
        'processo. Código do Windows: %d. %s',
        [LErrorCode, SysErrorMessage(LErrorCode)]
      );
    end;

    Result := LIsMember;
  finally
    if Assigned(LAdministratorsGroup) then
      FreeSid(LAdministratorsGroup);
  end;
end;

class function TRickWinServiceSecurity.IsRunningAsAdministrator: Boolean;
begin
  Result := CheckAdministratorMembership;
end;

class procedure TRickWinServiceSecurity.RequireAdministrator(
  const AOperation: string);
begin
  if IsRunningAsAdministrator then
    Exit;

  raise ERickWinServiceAdministratorRequired.Create(AOperation);
end;

end.
