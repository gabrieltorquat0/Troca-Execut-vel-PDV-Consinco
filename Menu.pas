unit Menu;

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  System.Threading,
  System.Generics.Collections,
  Vcl.Forms,
  Vcl.Controls,
  Vcl.StdCtrls,
  Vcl.ComCtrls,
  Vcl.Dialogs,
  Vcl.ExtCtrls,
  Vcl.ImgList,
  Vcl.Graphics,
  ModuloOracle, System.ImageList;

type
  TFrmMenu = class(TForm)
    TreeView1: TTreeView;
    btnCarregar: TButton;
    btnSelecionarExe: TButton;
    btnExecutar: TButton;
    MemoLog: TMemo;
    ProgressBar1: TProgressBar;
    OpenDialog: TOpenDialog;
    lblArquivoSelecionado: TLabel;
    ImageListStatus: TImageList;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;

    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnSelecionarExeClick(Sender: TObject);
    procedure btnExecutarClick(Sender: TObject);
    procedure btnCarregarClick(Sender: TObject);

  private
    function PingPDV(const IP: string): Boolean;
    procedure Log(const Msg: string);
    function CriarCirculo(Cor: TColor): TBitmap;
  public
    procedure CarregarEmpresas;
  end;

var
  FrmMenu: TFrmMenu;

implementation

{$R *.dfm}

uses DeployManager;

function TFrmMenu.CriarCirculo(Cor: TColor): TBitmap;
begin
  Result := TBitmap.Create;
  Result.SetSize(16,16);

  Result.Canvas.Brush.Color := clWhite;
  Result.Canvas.FillRect(Rect(0,0,16,16));

  Result.Canvas.Brush.Color := Cor;
  Result.Canvas.Pen.Style := psClear;

  Result.Canvas.Ellipse(2,2,14,14);
end;

procedure TFrmMenu.FormCreate(Sender: TObject);
var
  bmp: TBitmap;
begin

  ImageListStatus.Width := 16;
  ImageListStatus.Height := 16;

  bmp := CriarCirculo(clLime);
  ImageListStatus.Add(bmp,nil);
  bmp.Free;

  bmp := CriarCirculo(clRed);
  ImageListStatus.Add(bmp,nil);
  bmp.Free;

  TreeView1.Images := ImageListStatus;

end;

procedure TFrmMenu.FormShow(Sender: TObject);
begin
  CarregarEmpresas;
end;

procedure TFrmMenu.btnSelecionarExeClick(Sender: TObject);
begin
  if OpenDialog.Execute then
    lblArquivoSelecionado.Caption := OpenDialog.FileName;
end;

procedure TFrmMenu.btnCarregarClick(Sender: TObject);
begin
  CarregarEmpresas;
end;

function TFrmMenu.PingPDV(const IP: string): Boolean;
var
  SI: TStartupInfo;
  PI: TProcessInformation;
  ExitCode: Cardinal;
  Cmd: string;
begin

  Result := False;

  ZeroMemory(@SI,SizeOf(SI));
  SI.cb := SizeOf(SI);

  Cmd := Format('cmd.exe /C ping -n 1 -w 500 %s > nul',[IP]);

  if CreateProcess(nil,PChar(Cmd),nil,nil,false,CREATE_NO_WINDOW,nil,nil,SI,PI) then
  begin
    WaitForSingleObject(PI.hProcess,INFINITE);
    GetExitCodeProcess(PI.hProcess,ExitCode);
    Result := ExitCode=0;

    CloseHandle(PI.hProcess);
    CloseHandle(PI.hThread);
  end;

end;

procedure TFrmMenu.CarregarEmpresas;
var
  NodeEmpresa,NodePDV: TTreeNode;
  EmpresaAtual: string;
  IP,SO,Versao,Checkout: string;
  NodeThread: TTreeNode;
begin

  TreeView1.Items.BeginUpdate;
  TreeView1.Items.Clear;

  Dm.CarregarPDVs;

  EmpresaAtual := '';

  while not Dm.QueryPDVs.Eof do
  begin

    if EmpresaAtual <> Dm.QueryPDVs.FieldByName('nroempresa').AsString then
    begin
      EmpresaAtual := Dm.QueryPDVs.FieldByName('nroempresa').AsString;
      NodeEmpresa := TreeView1.Items.Add(nil,'Empresa '+EmpresaAtual);
      NodeEmpresa.ImageIndex := -1;
    end;

    IP := Dm.QueryPDVs.FieldByName('ip').AsString;
    SO := Dm.QueryPDVs.FieldByName('so').AsString;
    Versao := Dm.QueryPDVs.FieldByName('versaoaplicacao').AsString;
    Checkout := Dm.QueryPDVs.FieldByName('nrocheckout').AsString;

    NodePDV :=
      TreeView1.Items.AddChild(
        NodeEmpresa,
        Format('PDV %s (%s) (%s) - (%s)',[Checkout,SO,Versao,IP])
      );

    NodePDV.Data :=
      Pointer(StrNew(PChar(IP+'|'+SO+'|'+Versao)));

    NodePDV.ImageIndex := -1;

    NodeThread := NodePDV;

    TThreadPool.Default.QueueWorkItem(
      procedure
      var
        Online:Boolean;
      begin

        Online := PingPDV(IP);

        TThread.Synchronize(nil,
        procedure
        begin

          if Online then
            NodeThread.Text :=
              NodeThread.Text+' ON'
          else
            NodeThread.Text :=
              NodeThread.Text+' OFF';

        end);

      end);

    Dm.QueryPDVs.Next;

  end;

  TreeView1.Items.EndUpdate;
  TreeView1.FullExpand;

end;

procedure TFrmMenu.btnExecutarClick(Sender: TObject);
var
  Nodes: TList<TTreeNode>;
  Node,NodeThread:TTreeNode;
  Dados,IP,SO,Versao:string;
begin

  Nodes := TList<TTreeNode>.Create;

  try

    for var I:=0 to TreeView1.Items.Count-1 do
      if (TreeView1.Items[I].Level=1) and TreeView1.Items[I].Checked then
        Nodes.Add(TreeView1.Items[I]);

    ProgressBar1.Max := Nodes.Count;
    ProgressBar1.Position := 0;

    for Node in Nodes do
    begin

      Dados := string(PChar(Node.Data));

      IP := Copy(Dados,1,Pos('|',Dados)-1);
      Delete(Dados,1,Pos('|',Dados));

      SO := Copy(Dados,1,Pos('|',Dados)-1);
      Delete(Dados,1,Pos('|',Dados));

      Versao := Dados;

      NodeThread := Node;

      TThreadPool.Default.QueueWorkItem(
        procedure
        var
          Res:string;
        begin

          try

            if SO='L' then
              Res := TDeployManager.DeployLinux(
                IP,
                'root',
                'consinco',
                lblArquivoSelecionado.Caption,
                '',
                '',
                Versao)
            else
              Res := 'ERRO';

            TThread.Synchronize(nil,
            procedure
            begin

              if Res='OK' then
                NodeThread.ImageIndex := 0
              else
                NodeThread.ImageIndex := 1;

              ProgressBar1.Position :=
                ProgressBar1.Position + 1;

            end);

          except
            on E:Exception do
            begin

              TThread.Synchronize(nil,
              procedure
              begin
                NodeThread.ImageIndex := 1;
                Log(IP+' -> '+E.Message);
              end);

            end;
          end;

        end);

    end;

  finally
    Nodes.Free;
  end;

end;

procedure TFrmMenu.Log(const Msg: string);
begin
  MemoLog.Lines.Add(
  FormatDateTime('hh:nn:ss',Now)+' - '+Msg);
end;

end.
