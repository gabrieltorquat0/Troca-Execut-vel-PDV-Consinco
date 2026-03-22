unit uTrocaExecutavelPDV;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.WinSock,
  System.SysUtils, System.Classes, System.Threading,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls;

type
  TPDVStatus = (psAguardando, psOK, psErro, psExecutando);

  TPDVInfo = record
    NroEmpresa  : Integer;
    NroCheckout : Integer;
    IP          : string;
    SO          : string;
    Versao      : string;
    Online      : Boolean;
    Status      : TPDVStatus;
  end;

  // Dialog de credenciais Windows — criado 100% em codigo, sem DFM
  TfrmCredenciais = class(TForm)
  private
    pnlMain    : TPanel;
    lblTitulo  : TLabel;
    lblPDV     : TLabel;
    lblUsuario : TLabel;
    edtUsuario : TEdit;
    lblSenha   : TLabel;
    edtSenha   : TEdit;
    btnOK      : TButton;
    btnCancelar: TButton;
    procedure btnOKClick(Sender: TObject);
  public
    NomePDV : string;
    Usuario : string;
    Senha   : string;
    constructor Create(AOwner: TComponent; const ANomePDV: string); reintroduce;
  end;

  TfrmTrocaExecutavel = class(TForm)
    pnlTopo            : TPanel;
    pnlRodape          : TPanel;
    pnlEsquerda        : TPanel;
    pnlDireita         : TPanel;
    Splitter1          : TSplitter;
    lblExecSelecionado : TLabel;
    btnCarregarPDVs    : TButton;
    btnSelecionarExec  : TButton;
    btnExecutar        : TButton;
    lblTituloPDVs      : TLabel;
    lvPDVs             : TListView;
    pnlProgresso       : TPanel;
    lblProgresso       : TLabel;
    lblPorcentagem     : TLabel;
    pbDeploy           : TProgressBar;
    pnlResumo          : TPanel;
    lblResumoOK        : TLabel;
    lblResumoErro      : TLabel;
    lblResumoIgnorado  : TLabel;
    memoLog            : TMemo;
    btnSalvarLog       : TButton;
    dlgAbrirExec       : TOpenDialog;
    procedure FormCreate(Sender: TObject);
    procedure btnCarregarPDVsClick(Sender: TObject);
    procedure btnSelecionarExecClick(Sender: TObject);
    procedure btnExecutarClick(Sender: TObject);
    procedure btnSalvarLogClick(Sender: TObject);
    procedure lvPDVsClick(Sender: TObject);
  private
    FExecSelecionado : string;
    FDeployRodando   : Boolean;
    FPDVs            : array of TPDVInfo;
    function  PingHost(const AIP: string; ATimeoutMs: Integer = 800): Boolean;
    procedure PopularListView;
    procedure AtualizarColunaRede(AIndex: Integer; AOnline: Boolean);
    procedure AtualizarStatusItem(AIndex: Integer; AStatus: TPDVStatus);
    procedure AdicionarLog(const AMensagem: string);
    procedure AtualizarBotoes;
    procedure AtualizarResumo;
    function  ContarStatus(AStatus: TPDVStatus): Integer;
    function  ColetarCredenciaisWindows(
                const NomePDV: string;
                out Usuario, Senha: string): Boolean;
  end;

var
  frmTrocaExecutavel: TfrmTrocaExecutavel;

implementation

{$R *.dfm}

uses
  ModuloOracle,
  DeployManager;

const
  SSH_USUARIO = 'root';
  SSH_SENHA   = 'consinco';
constructor TfrmCredenciais.Create(AOwner: TComponent; const ANomePDV: string);
begin
  // Chama o construtor base sem tentar carregar DFM
  inherited CreateNew(AOwner);

  NomePDV := ANomePDV;

  Caption      := 'Credenciais de rede';
  Width        := 340;
  Height       := 230;
  BorderStyle  := bsDialog;
  Position     := poScreenCenter;
  Font.Name    := 'Segoe UI';
  Font.Size    := 9;

  pnlMain := TPanel.Create(Self);
  pnlMain.Parent     := Self;
  pnlMain.Align      := alClient;
  pnlMain.BevelOuter := bvNone;

  lblTitulo := TLabel.Create(Self);
  lblTitulo.Parent   := pnlMain;
  lblTitulo.Caption  := 'Informe as credenciais de rede';
  lblTitulo.Font.Style := [fsBold];
  lblTitulo.Left     := 16;
  lblTitulo.Top      := 12;

  lblPDV := TLabel.Create(Self);
  lblPDV.Parent  := pnlMain;
  lblPDV.Caption := 'PDV: ' + ANomePDV;
  lblPDV.Left    := 16;
  lblPDV.Top     := 32;

  lblUsuario := TLabel.Create(Self);
  lblUsuario.Parent  := pnlMain;
  lblUsuario.Caption := 'Usu'#225'rio Windows:';
  lblUsuario.Left    := 16;
  lblUsuario.Top     := 60;

  edtUsuario := TEdit.Create(Self);
  edtUsuario.Parent := pnlMain;
  edtUsuario.Left   := 16;
  edtUsuario.Top    := 78;
  edtUsuario.Width  := 290;
  edtUsuario.Text   := 'administrator';

  lblSenha := TLabel.Create(Self);
  lblSenha.Parent  := pnlMain;
  lblSenha.Caption := 'Senha:';
  lblSenha.Left    := 16;
  lblSenha.Top     := 112;

  edtSenha := TEdit.Create(Self);
  edtSenha.Parent       := pnlMain;
  edtSenha.Left         := 16;
  edtSenha.Top          := 130;
  edtSenha.Width        := 290;
  edtSenha.PasswordChar := '*';
  edtSenha.Text         := '';

  btnOK := TButton.Create(Self);
  btnOK.Parent  := pnlMain;
  btnOK.Caption := 'OK';
  btnOK.Left    := 136;
  btnOK.Top     := 165;
  btnOK.Width   := 80;
  btnOK.Default := True;
  btnOK.OnClick := btnOKClick;

  btnCancelar := TButton.Create(Self);
  btnCancelar.Parent      := pnlMain;
  btnCancelar.Caption     := 'Cancelar';
  btnCancelar.Left        := 226;
  btnCancelar.Top         := 165;
  btnCancelar.Width       := 80;
  btnCancelar.ModalResult := mrCancel;
  btnCancelar.Cancel      := True;
end;

procedure TfrmCredenciais.btnOKClick(Sender: TObject);
begin
  if Trim(edtUsuario.Text) = '' then
  begin
    ShowMessage('Informe o usu'#225'rio.');
    edtUsuario.SetFocus;
    Exit;
  end;
  Usuario     := Trim(edtUsuario.Text);
  Senha       := edtSenha.Text;
  ModalResult := mrOk;
end;

type
  TIcmpEchoRequest = packed record
    IcmpType : Byte;
    Code     : Byte;
    Checksum : Word;
    ID       : Word;
    SeqNum   : Word;
    Data     : array[0..31] of Byte;
  end;

function IcmpChecksum(var Buf; Len: Integer): Word;
var
  Sum : Cardinal;
  P   : PWord;
  i   : Integer;
begin
  Sum := 0;
  P   := @Buf;
  for i := 1 to Len div 2 do
  begin
    Inc(Sum, P^);
    Inc(P);
  end;
  if Len mod 2 = 1 then
    Inc(Sum, PByte(P)^);
  while Sum shr 16 <> 0 do
    Sum := (Sum and $FFFF) + (Sum shr 16);
  Result := not Word(Sum);
end;

function TfrmTrocaExecutavel.PingHost(const AIP: string; ATimeoutMs: Integer): Boolean;
var
  WSAData : TWSAData;
  Sock    : TSocket;
  Dest    : TSockAddrIn;
  Req     : TIcmpEchoRequest;
  Buf     : array[0..255] of Byte;
  TV      : timeval;
  FDSet   : TFDSet;
  Sent    : Integer;
  AddrLen : Integer;
begin
  Result := False;
  if AIP = '' then Exit;
  if WSAStartup($0202, WSAData) <> 0 then Exit;
  try
    Sock := socket(AF_INET, SOCK_RAW, IPPROTO_ICMP);
    if Sock = INVALID_SOCKET then Exit;
    try
      TV.tv_sec  := ATimeoutMs div 1000;
      TV.tv_usec := (ATimeoutMs mod 1000) * 1000;
      setsockopt(Sock, SOL_SOCKET, SO_RCVTIMEO, @TV, SizeOf(TV));
      FillChar(Req, SizeOf(Req), 0);
      Req.IcmpType := 8;
      Req.ID       := GetCurrentProcessId and $FFFF;
      Req.SeqNum   := 1;
      Req.Checksum := IcmpChecksum(Req, SizeOf(Req));
      FillChar(Dest, SizeOf(Dest), 0);
      Dest.sin_family      := AF_INET;
      Dest.sin_addr.S_addr := inet_addr(PAnsiChar(AnsiString(AIP)));
      Sent := sendto(Sock, Req, SizeOf(Req), 0, TSockAddr(Dest), SizeOf(Dest));
      if Sent = SOCKET_ERROR then Exit;
      FD_ZERO(FDSet);
      FD_SET(Sock, FDSet);
      AddrLen := SizeOf(Dest);
      if select(0, @FDSet, nil, nil, @TV) > 0 then
        Result := recvfrom(Sock, Buf, SizeOf(Buf), 0,
                           TSockAddr(Dest), AddrLen) > 0;
    finally
      closesocket(Sock);
    end;
  finally
    WSACleanup;
  end;
end;

procedure TfrmTrocaExecutavel.FormCreate(Sender: TObject);
begin
  FDeployRodando   := False;
  FExecSelecionado := '';
  pnlResumo.Visible    := False;
  btnSalvarLog.Visible := False;
  pbDeploy.Position    := 0;
  lvPDVs.GroupView     := True;
  memoLog.Lines.Clear;
  memoLog.Lines.Add('// Clique em Carregar PDVs para iniciar.');
  AtualizarBotoes;
end;

function TfrmTrocaExecutavel.ColetarCredenciaisWindows(
  const NomePDV: string;
  out Usuario, Senha: string): Boolean;
var
  Dlg: TfrmCredenciais;
begin
  Result  := False;
  Usuario := '';
  Senha   := '';
  Dlg := TfrmCredenciais.Create(Self, NomePDV);
  try
    if Dlg.ShowModal = mrOk then
    begin
      Usuario := Dlg.Usuario;
      Senha   := Dlg.Senha;
      Result  := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ ============================================================
  LISTVIEW
  ============================================================ }
procedure TfrmTrocaExecutavel.PopularListView;
var
  i         : Integer;
  GrpID     : Integer;
  Item      : TListItem;
  UltimaEmp : Integer;
  Grp       : TListGroup;
begin
  lvPDVs.Items.BeginUpdate;
  lvPDVs.Groups.Clear;
  lvPDVs.Items.Clear;
  try
    UltimaEmp := -1;
    GrpID     := 0;
    for i := 0 to High(FPDVs) do
    begin
      if FPDVs[i].NroEmpresa <> UltimaEmp then
      begin
        UltimaEmp   := FPDVs[i].NroEmpresa;
        Grp         := lvPDVs.Groups.Add;
        Grp.Header  := Format('Loja %d', [FPDVs[i].NroEmpresa]);
        Grp.GroupID := GrpID;
        Grp.State   := [lgsCollapsible];
        Inc(GrpID);
      end;
      Item := lvPDVs.Items.Add;
      Item.Caption := Format('PDV %d', [FPDVs[i].NroCheckout]);
      Item.SubItems.Add(FPDVs[i].SO);     // [0] SO
      Item.SubItems.Add(FPDVs[i].Versao); // [1] Versao
      Item.SubItems.Add(FPDVs[i].IP);     // [2] IP
      Item.SubItems.Add('...');           // [3] Rede
      Item.SubItems.Add('-');             // [4] Status deploy
      Item.GroupID := GrpID - 1;
      Item.Checked := False;
    end;
  finally
    lvPDVs.Items.EndUpdate;
  end;
end;

{ ============================================================
  CARREGAR PDVs
  ============================================================ }
procedure TfrmTrocaExecutavel.btnCarregarPDVsClick(Sender: TObject);
var
  i: Integer;
begin
  if FDeployRodando then Exit;
  btnCarregarPDVs.Enabled := False;
  lblProgresso.Caption    := 'Consultando banco de dados...';
  memoLog.Lines.Clear;
  Application.ProcessMessages;
  try
    Dm.CarregarPDVs;
    SetLength(FPDVs, Dm.QueryPDVs.RecordCount);
    i := 0;
    Dm.QueryPDVs.First;
    while not Dm.QueryPDVs.Eof do
    begin
      FPDVs[i].NroEmpresa  := Dm.QueryPDVs.FieldByName('nroempresa').AsInteger;
      FPDVs[i].NroCheckout := Dm.QueryPDVs.FieldByName('nrocheckout').AsInteger;
      FPDVs[i].IP          := Trim(Dm.QueryPDVs.FieldByName('ip').AsString);
      FPDVs[i].SO          := Trim(Dm.QueryPDVs.FieldByName('so').AsString);
      FPDVs[i].Versao      := Trim(Dm.QueryPDVs.FieldByName('versaoaplicacao').AsString);
      FPDVs[i].Online      := False;
      FPDVs[i].Status      := psAguardando;
      Inc(i);
      Dm.QueryPDVs.Next;
    end;

    PopularListView;
    lblProgresso.Caption := Format('%d PDVs carregados. Verificando rede...', [Length(FPDVs)]);
    AdicionarLog(Format('// %d PDVs carregados do banco.', [Length(FPDVs)]));
    AtualizarBotoes;

    TTask.Run(
      procedure
      var
        j, Total, on_, off_, k, Idx: Integer;
      begin
        Total := Length(FPDVs);
        for j := 0 to Total - 1 do
        begin
          Idx := j;
          FPDVs[Idx].Online := PingHost(FPDVs[Idx].IP, 800);
          TThread.Synchronize(nil,
            procedure
            begin
              AtualizarColunaRede(Idx, FPDVs[Idx].Online);
              lblProgresso.Caption :=
                Format('Verificando rede... %d/%d', [Idx + 1, Total]);
            end);
        end;
        on_ := 0; off_ := 0;
        for k := 0 to High(FPDVs) do
          if FPDVs[k].Online then Inc(on_) else Inc(off_);
        TThread.Synchronize(nil,
          procedure
          begin
            lblProgresso.Caption    := Format('Rede: %d ON  %d OFF', [on_, off_]);
            btnCarregarPDVs.Enabled := True;
            AdicionarLog(Format('// Rede: %d ON  %d OFF', [on_, off_]));
          end);
      end);

  except
    on E: Exception do
    begin
      ShowMessage('Erro ao carregar PDVs: ' + E.Message);
      btnCarregarPDVs.Enabled := True;
      lblProgresso.Caption    := 'Erro ao carregar.';
    end;
  end;
end;

procedure TfrmTrocaExecutavel.AtualizarColunaRede(AIndex: Integer; AOnline: Boolean);
begin
  if (AIndex < 0) or (AIndex >= lvPDVs.Items.Count) then Exit;
  if AOnline then
    lvPDVs.Items[AIndex].SubItems[3] := 'ON'
  else
    lvPDVs.Items[AIndex].SubItems[3] := 'OFF';
end;

procedure TfrmTrocaExecutavel.btnSelecionarExecClick(Sender: TObject);
begin
  if dlgAbrirExec.Execute then
  begin
    FExecSelecionado              := dlgAbrirExec.FileName;
    lblExecSelecionado.Caption    := ExtractFileName(FExecSelecionado);
    lblExecSelecionado.Font.Color := clWindowText;
    AdicionarLog('// Execut'#225'vel: ' + ExtractFileName(FExecSelecionado));
    AtualizarBotoes;
  end;
end;

{ ============================================================
  EXECUTAR DEPLOY
  ============================================================ }
procedure TfrmTrocaExecutavel.btnExecutarClick(Sender: TObject);
var
  PDVsSelecionados : TArray<Integer>;
  CredWinUser      : TArray<string>;
  CredWinSenha     : TArray<string>;
  i, Total         : Integer;
  Cancelado        : Boolean;
begin
  if FDeployRodando then Exit;

  if FExecSelecionado = '' then
  begin
    ShowMessage('Selecione um execut'#225'vel antes de prosseguir.');
    Exit;
  end;

  SetLength(PDVsSelecionados, 0);
  for i := 0 to lvPDVs.Items.Count - 1 do
    if lvPDVs.Items[i].Checked then
    begin
      SetLength(PDVsSelecionados, Length(PDVsSelecionados) + 1);
      PDVsSelecionados[High(PDVsSelecionados)] := i;
    end;

  if Length(PDVsSelecionados) = 0 then
  begin
    ShowMessage('Selecione ao menos um PDV para o deploy.');
    Exit;
  end;

  Total := Length(PDVsSelecionados);
  SetLength(CredWinUser,  Total);
  SetLength(CredWinSenha, Total);

  // Coleta credenciais Windows antes de iniciar (thread principal)
  Cancelado := False;
  for i := 0 to Total - 1 do
  begin
    if FPDVs[PDVsSelecionados[i]].SO = 'W' then
    begin
      var NomePDV := Format('PDV %d - Loja %d',
        [FPDVs[PDVsSelecionados[i]].NroCheckout,
         FPDVs[PDVsSelecionados[i]].NroEmpresa]);
      if not ColetarCredenciaisWindows(NomePDV,
               CredWinUser[i], CredWinSenha[i]) then
      begin
        Cancelado := True;
        Break;
      end;
    end;
  end;
  if Cancelado then Exit;

  FDeployRodando       := True;
  pnlResumo.Visible    := False;
  btnSalvarLog.Visible := False;
  pbDeploy.Position    := 0;
  memoLog.Lines.Clear;
  AtualizarBotoes;

  AdicionarLog(Format('[%s] Iniciando deploy: %s',
    [TimeToStr(Now), ExtractFileName(FExecSelecionado)]));
  AdicionarLog(Format('// %d PDV(s) selecionado(s)', [Total]));

  var ExecLocal := FExecSelecionado;

  TTask.Run(
    procedure
    var
      j, PIdx     : Integer;
      Resultado   : string;
      Sucesso     : Boolean;
      NomePDV     : string;
      IDAtual     : string;
      FeitosLocal : Integer;
    begin
      FeitosLocal := 0;

      for j := 0 to High(PDVsSelecionados) do
      begin
        PIdx    := PDVsSelecionados[j];
        NomePDV := Format('PDV %d (Loja %d) [%s]',
                     [FPDVs[PIdx].NroCheckout,
                      FPDVs[PIdx].NroEmpresa,
                      FPDVs[PIdx].SO]);
        IDAtual := Format('L%d-PDV%d',
                     [FPDVs[PIdx].NroEmpresa,
                      FPDVs[PIdx].NroCheckout]);

        TThread.Synchronize(nil,
          procedure
          begin
            AtualizarStatusItem(PIdx, psExecutando);
            lblProgresso.Caption := 'Deployando ' + NomePDV + '...';
          end);

        try
          Resultado := TDeployManager.Deploy(
            FPDVs[PIdx].SO,
            FPDVs[PIdx].IP,
            SSH_USUARIO,
            SSH_SENHA,
            CredWinUser[j],
            CredWinSenha[j],
            ExecLocal,
            IntToStr(FPDVs[PIdx].NroEmpresa),
            IntToStr(FPDVs[PIdx].NroCheckout),
            FPDVs[PIdx].Versao
          );
          Sucesso := Resultado = 'OK';
        except
          on E: Exception do
          begin
            Resultado := 'ERRO: ' + E.Message;
            Sucesso   := False;
          end;
        end;

        if Sucesso then
          FPDVs[PIdx].Status := psOK
        else
          FPDVs[PIdx].Status := psErro;

        Inc(FeitosLocal);

        var StatusCapture    := FPDVs[PIdx].Status;
        var ResultadoCapture := Resultado;
        var PIdxCapture      := PIdx;
        var IDCapture        := IDAtual;
        var FeitosCapture    := FeitosLocal;

        TThread.Synchronize(nil,
          procedure
          begin
            AtualizarStatusItem(PIdxCapture, StatusCapture);
            pbDeploy.Position      := Round((FeitosCapture / Total) * 100);
            lblPorcentagem.Caption := IntToStr(pbDeploy.Position) + '%';
            if StatusCapture = psOK then
              AdicionarLog(Format('[%s] OK  %s',
                [TimeToStr(Now), IDCapture]))
            else
              AdicionarLog(Format('[%s] ERR %s: %s',
                [TimeToStr(Now), IDCapture, ResultadoCapture]));
          end);
      end;

      TThread.Synchronize(nil,
        procedure
        begin
          FDeployRodando       := False;
          lblProgresso.Caption := 'Deploy conclu'#237'do.';
          AdicionarLog(Format('[%s] Processo finalizado.', [TimeToStr(Now)]));
          AtualizarBotoes;
          AtualizarResumo;
          btnSalvarLog.Visible := True;
        end);
    end);
end;

procedure TfrmTrocaExecutavel.AtualizarStatusItem(AIndex: Integer; AStatus: TPDVStatus);
const
  Textos: array[TPDVStatus] of string = ('-', '[OK]', '[ERRO]', '[...]');
begin
  if (AIndex < 0) or (AIndex >= lvPDVs.Items.Count) then Exit;
  if lvPDVs.Items[AIndex].SubItems.Count >= 5 then
    lvPDVs.Items[AIndex].SubItems[4] := Textos[AStatus];
end;

procedure TfrmTrocaExecutavel.AdicionarLog(const AMensagem: string);
begin
  memoLog.Lines.Add(AMensagem);
  SendMessage(memoLog.Handle, WM_VSCROLL, SB_BOTTOM, 0);
end;

procedure TfrmTrocaExecutavel.AtualizarBotoes;
var
  i             : Integer;
  TemSelecionado: Boolean;
begin
  TemSelecionado := False;
  for i := 0 to lvPDVs.Items.Count - 1 do
    if lvPDVs.Items[i].Checked then
    begin
      TemSelecionado := True;
      Break;
    end;
  btnCarregarPDVs.Enabled   := not FDeployRodando;
  btnSelecionarExec.Enabled := not FDeployRodando;
  btnExecutar.Enabled       := (not FDeployRodando)
                               and (FExecSelecionado <> '')
                               and TemSelecionado;
end;

procedure TfrmTrocaExecutavel.AtualizarResumo;
begin
  lblResumoOK.Caption       := IntToStr(ContarStatus(psOK))         + ' OK';
  lblResumoErro.Caption     := IntToStr(ContarStatus(psErro))       + ' com erro';
  lblResumoIgnorado.Caption := IntToStr(ContarStatus(psAguardando)) + ' n'#227'o executados';
  pnlResumo.Visible         := True;
end;

function TfrmTrocaExecutavel.ContarStatus(AStatus: TPDVStatus): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to High(FPDVs) do
    if FPDVs[i].Status = AStatus then Inc(Result);
end;

procedure TfrmTrocaExecutavel.lvPDVsClick(Sender: TObject);
begin
  AtualizarBotoes;
end;

procedure TfrmTrocaExecutavel.btnSalvarLogClick(Sender: TObject);
var
  dlg: TSaveDialog;
begin
  dlg := TSaveDialog.Create(Self);
  try
    dlg.Title      := 'Salvar log de deploy';
    dlg.Filter     := 'Arquivo de log (*.log)|*.log|Texto (*.txt)|*.txt';
    dlg.FileName   := 'deploy_' + FormatDateTime('YYYYMMDD_HHMMSS', Now) + '.log';
    dlg.DefaultExt := 'log';
    if dlg.Execute then
      memoLog.Lines.SaveToFile(dlg.FileName);
  finally
    dlg.Free;
  end;
end;

end.
