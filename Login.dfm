object FrmLogin: TFrmLogin
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Troca Executavel PDV Consinco'
  ClientHeight = 281
  ClientWidth = 304
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  TextHeight = 15
  object PanelLogin: TPanel
    Left = 0
    Top = 0
    Width = 304
    Height = 281
    Align = alClient
    TabOrder = 0
    object EditUsuario: TEdit
      AlignWithMargins = True
      Left = 91
      Top = 114
      Width = 121
      Height = 23
      TabOrder = 1
    end
    object EditSenha: TEdit
      Left = 91
      Top = 85
      Width = 121
      Height = 23
      TabOrder = 0
    end
    object ComboBox1: TComboBox
      Left = 91
      Top = 143
      Width = 121
      Height = 23
      TabOrder = 2
    end
    object ButtonConectar: TButton
      Left = 115
      Top = 180
      Width = 75
      Height = 25
      Caption = 'Conectar'
      TabOrder = 3
      OnClick = ButtonConectarClick
    end
  end
end
