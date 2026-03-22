unit DeployManager;

interface

uses
  System.SysUtils,
  System.IOUtils,
  Winapi.Windows;

type
  TDeployManager = class
  private
    class function  ExecutarAguardar(const Cmd: string): Boolean;
    class procedure BackupLinux(const IP, Usuario, Senha, Empresa, PDV: string);
    class procedure BackupWindows(const IP, UsuarioWin, SenhaWin, Empresa, PDV: string);
    class function  ExtrairNumero(const Texto: string): string;
  public
    class function DeployLinux(
      const IP, Usuario, Senha,
      ArquivoLocal, Empresa, PDV, Versao: string): string;

    class function DeployWindows(
      const IP, UsuarioWin, SenhaWin,
      ArquivoLocal, Empresa, PDV: string): string;

    // Ponto de entrada unico: detecta SO e roteia
    class function Deploy(
      const SO, IP,
      UsuarioSSH, SenhaSSH,
      UsuarioWin, SenhaWin,
      ArquivoLocal, Empresa, PDV, Versao: string): string;
  end;

implementation

{ ------------------------------------------------------------
  UTILITARIOS
  ------------------------------------------------------------ }
class function TDeployManager.ExtrairNumero(const Texto: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(Texto) do
    if CharInSet(Texto[I], ['0'..'9']) then
      Result := Result + Texto[I];
end;

// Executa um comando e aguarda terminar; retorna True se ExitCode = 0
class function TDeployManager.ExecutarAguardar(const Cmd: string): Boolean;
var
  SI       : TStartupInfo;
  PI       : TProcessInformation;
  ExitCode : Cardinal;
begin
  Result := False;
  ZeroMemory(@SI, SizeOf(SI));
  SI.cb := SizeOf(SI);

  if not CreateProcess(nil, PChar(Cmd), nil, nil, False,
                       CREATE_NO_WINDOW, nil, nil, SI, PI) then
    Exit;

  WaitForSingleObject(PI.hProcess, INFINITE);
  GetExitCodeProcess(PI.hProcess, ExitCode);
  CloseHandle(PI.hProcess);
  CloseHandle(PI.hThread);

  // Robocopy retorna 0..7 como sucesso (bits de copia/extra/miss)
  // valores >= 8 indicam erro real
  Result := ExitCode <= 7;
end;

{ ------------------------------------------------------------
  BACKUP LINUX via WinSCP (download do exe atual antes de substituir)
  ------------------------------------------------------------ }
class procedure TDeployManager.BackupLinux(
  const IP, Usuario, Senha, Empresa, PDV: string);
var
  EmpresaNum  : string;
  PDVNum      : string;
  PastaBackup : string;
  ArqBackup   : string;
  WinSCPPath  : string;
  Cmd         : string;
begin
  EmpresaNum  := ExtrairNumero(Empresa);
  PDVNum      := ExtrairNumero(PDV);
  PastaBackup := ExtractFilePath(ParamStr(0)) +
                 'backup\loja' + EmpresaNum +
                 '\pdv' + PDVNum + '\';
  ForceDirectories(PastaBackup);

  ArqBackup  := PastaBackup + 'AcruxPDV_' +
                FormatDateTime('yyyymmdd_hhnnss', Now) + '.exe';
  WinSCPPath := ExtractFilePath(ParamStr(0)) + 'winscp.com';

  Cmd :=
    'cmd.exe /C "' + WinSCPPath +
    ' /log="' + ExtractFilePath(ParamStr(0)) + 'winscp.log"' +
    ' /command' +
    ' "open scp://' + Usuario + ':' + Senha + '@' + IP + '"' +
    ' "get /c5client/AcruxPDV/AcruxPDV.exe "' + ArqBackup + '""' +
    ' "exit""';

  ExecutarAguardar(Cmd); // falha no backup nao interrompe o deploy
end;

{ ------------------------------------------------------------
  DEPLOY LINUX via WinSCP (backup + substituicao)
  ------------------------------------------------------------ }
class function TDeployManager.DeployLinux(
  const IP, Usuario, Senha,
  ArquivoLocal, Empresa, PDV, Versao: string): string;
var
  WinSCPPath : string;
  Cmd        : string;
  Destino    : string;
begin
  BackupLinux(IP, Usuario, Senha, Empresa, PDV);

  Destino    := '/c5client/AcruxPDV/AcruxPDV.exe';
  WinSCPPath := ExtractFilePath(ParamStr(0)) + 'winscp.com';

  Cmd :=
    'cmd.exe /C "' + WinSCPPath +
    ' /log="' + ExtractFilePath(ParamStr(0)) + 'winscp.log"' +
    ' /command' +
    ' "open scp://' + Usuario + ':' + Senha + '@' + IP + '"' +
    ' "put "' + ArquivoLocal + '" "' + Destino + '""' +
    ' "exit""';

  if ExecutarAguardar(Cmd) then
    Result := 'OK'
  else
    Result := 'ERRO: falha no WinSCP (verifique winscp.log)';
end;

{ ------------------------------------------------------------
  BACKUP WINDOWS via copia direta UNC (net use ja montado)
  ------------------------------------------------------------ }
class procedure TDeployManager.BackupWindows(
  const IP, UsuarioWin, SenhaWin, Empresa, PDV: string);
var
  EmpresaNum  : string;
  PDVNum      : string;
  PastaBackup : string;
  Origem      : string;
  Destino     : string;
begin
  EmpresaNum  := ExtrairNumero(Empresa);
  PDVNum      := ExtrairNumero(PDV);
  PastaBackup := ExtractFilePath(ParamStr(0)) +
                 'backup\loja' + EmpresaNum +
                 '\pdv' + PDVNum + '\';
  ForceDirectories(PastaBackup);

  Origem  := Format('\\%s\c$\c5client\acruxpdv\acruxpdv.exe', [IP]);
  Destino := PastaBackup + 'AcruxPDV_' +
             FormatDateTime('yyyymmdd_hhnnss', Now) + '.exe';

  try
    if FileExists(Origem) then
      TFile.Copy(Origem, Destino, True);
  except
    // falha no backup nao interrompe o deploy
  end;
end;

{ ------------------------------------------------------------
  DEPLOY WINDOWS via net use + robocopy + net use /delete
  ------------------------------------------------------------ }
class function TDeployManager.DeployWindows(
  const IP, UsuarioWin, SenhaWin,
  ArquivoLocal, Empresa, PDV: string): string;
var
  RecursoUNC   : string;
  CmdNetUse    : string;
  CmdRobocopy  : string;
  CmdNetDelete : string;
  PastaDestino : string;
  ArquivoDest  : string;
begin
  RecursoUNC := Format('\\%s\c$', [IP]);

  // Monta a conexao autenticada
  CmdNetUse := Format('cmd.exe /C net use %s %s /user:%s',
    [RecursoUNC, SenhaWin, UsuarioWin]);

  if not ExecutarAguardar(CmdNetUse) then
  begin
    Result := 'ERRO: falha ao conectar em ' + RecursoUNC +
              ' (verifique usuario/senha de rede)';
    Exit;
  end;

  try
    // Backup antes de substituir
    BackupWindows(IP, UsuarioWin, SenhaWin, Empresa, PDV);

    // Deploy via robocopy (aguarda terminar, verifica ExitCode)
    PastaDestino := Format('\\%s\c$\c5client\acruxpdv\', [IP]);
    CmdRobocopy  :=
      'cmd.exe /C robocopy "' +
      ExtractFilePath(ArquivoLocal) + '" "' +
      PastaDestino + '" "' +
      ExtractFileName(ArquivoLocal) +
      '" /R:1 /W:1 /IS /IT /NFL /NDL /NJH /NJS';

    if ExecutarAguardar(CmdRobocopy) then
    begin
      // Confirma que o arquivo realmente chegou
      ArquivoDest := PastaDestino + ExtractFileName(ArquivoLocal);
      if FileExists(ArquivoDest) then
        Result := 'OK'
      else
        Result := 'ERRO: robocopy concluiu mas arquivo nao encontrado no destino';
    end
    else
      Result := 'ERRO: robocopy retornou codigo de erro';

  finally
    // Sempre desmonta a conexao, independente de sucesso ou falha
    CmdNetDelete := Format('cmd.exe /C net use %s /delete /yes', [RecursoUNC]);
    ExecutarAguardar(CmdNetDelete);
  end;
end;

{ ------------------------------------------------------------
  PONTO DE ENTRADA UNICO — roteia por SO
  SO = 'W' -> Windows via robocopy
  SO = 'L' -> Linux via WinSCP/SCP
  ------------------------------------------------------------ }
class function TDeployManager.Deploy(
  const SO, IP,
  UsuarioSSH, SenhaSSH,
  UsuarioWin, SenhaWin,
  ArquivoLocal, Empresa, PDV, Versao: string): string;
begin
  if SO = 'W' then
    Result := DeployWindows(IP, UsuarioWin, SenhaWin,
                            ArquivoLocal, Empresa, PDV)
  else if SO = 'L' then
    Result := DeployLinux(IP, UsuarioSSH, SenhaSSH,
                          ArquivoLocal, Empresa, PDV, Versao)
  else
    Result := 'ERRO: SO desconhecido (' + SO + ')';
end;

end.
