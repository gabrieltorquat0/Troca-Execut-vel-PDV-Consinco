program TrocaExecutavelPDV;

uses
  Vcl.Forms,
  Vcl.Themes,
  Vcl.Styles,
  Login in 'Login.pas' {FrmLogin},
  ModuloOracle in 'ModuloOracle.pas' {Dm: TDataModule},
  DeployManager in 'Deploy\DeployManager.pas',
  uTrocaExecutavelPDV in 'Form\uTrocaExecutavelPDV.pas' {frmTrocaExecutavel};

{$R *.res}

begin
  Application.Initialize;
  Application.ShowMainForm := False;
  TStyleManager.TrySetStyle('Windows10');
  Application.CreateForm(TFrmLogin, FrmLogin);
  FrmLogin.Show;

  Application.Run;
end.
