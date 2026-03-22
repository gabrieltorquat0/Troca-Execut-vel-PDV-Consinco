object frmTrocaExecutavel: TfrmTrocaExecutavel
  Left = 0
  Top = 0
  Caption = 'Troca Execut'#225'vel PDV Consinco'
  ClientHeight = 600
  ClientWidth = 1000
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 15
  object Splitter1: TSplitter
    Left = 460
    Top = 46
    Width = 4
    Height = 530
  end
  object pnlTopo: TPanel
    Left = 0
    Top = 0
    Width = 1000
    Height = 46
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblExecSelecionado: TLabel
      Left = 296
      Top = 15
      Width = 420
      Height = 16
      AutoSize = False
      Caption = 'Nenhum execut'#225'vel selecionado'
      EllipsisPosition = epEndEllipsis
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGrayText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object btnCarregarPDVs: TButton
      Left = 8
      Top = 8
      Width = 110
      Height = 30
      Caption = 'Carregar PDVs'
      TabOrder = 0
      OnClick = btnCarregarPDVsClick
    end
    object btnSelecionarExec: TButton
      Left = 126
      Top = 8
      Width = 160
      Height = 30
      Caption = 'Selecionar execut'#225'vel...'
      TabOrder = 1
      OnClick = btnSelecionarExecClick
    end
    object btnExecutar: TButton
      Left = 862
      Top = 8
      Width = 130
      Height = 30
      Caption = 'Executar deploy'
      Enabled = False
      TabOrder = 2
      OnClick = btnExecutarClick
    end
  end
  object pnlRodape: TPanel
    Left = 0
    Top = 576
    Width = 1000
    Height = 24
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
  end
  object pnlEsquerda: TPanel
    Left = 0
    Top = 46
    Width = 460
    Height = 530
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 2
    object lblTituloPDVs: TLabel
      Left = 0
      Top = 0
      Width = 460
      Height = 13
      Align = alTop
      Alignment = taCenter
      Caption = 'PDVs dispon'#237'veis'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      Layout = tlCenter
      ExplicitWidth = 89
    end
    object lvPDVs: TListView
      Left = 0
      Top = 13
      Width = 460
      Height = 517
      Align = alClient
      Checkboxes = True
      Columns = <
        item
          Caption = 'PDV'
          Width = 80
        end
        item
          Caption = 'SO'
          Width = 35
        end
        item
          Caption = 'Vers'#227'o'
          Width = 90
        end
        item
          Caption = 'IP'
          Width = 110
        end
        item
          Caption = 'Rede'
          Width = 44
        end
        item
          Caption = 'Status'
          Width = 60
        end>
      GridLines = True
      HideSelection = False
      GroupView = True
      RowSelect = True
      TabOrder = 0
      ViewStyle = vsReport
      OnClick = lvPDVsClick
    end
  end
  object pnlDireita: TPanel
    Left = 464
    Top = 46
    Width = 536
    Height = 530
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 3
    object pnlProgresso: TPanel
      Left = 0
      Top = 0
      Width = 536
      Height = 58
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 0
      DesignSize = (
        536
        58)
      object lblProgresso: TLabel
        Left = 12
        Top = 8
        Width = 480
        Height = 16
        AutoSize = False
        Caption = 'Aguardando execu'#231#227'o'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object lblPorcentagem: TLabel
        Left = 498
        Top = 34
        Width = 30
        Height = 16
        Alignment = taRightJustify
        Anchors = [akTop, akRight]
        AutoSize = False
        Caption = '0%'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object pbDeploy: TProgressBar
        Left = 12
        Top = 32
        Width = 480
        Height = 14
        TabOrder = 0
      end
    end
    object pnlResumo: TPanel
      Left = 0
      Top = 58
      Width = 536
      Height = 28
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 1
      Visible = False
      object lblResumoOK: TLabel
        Left = 12
        Top = 7
        Width = 27
        Height = 15
        Caption = '0 OK'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGreen
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblResumoErro: TLabel
        Left = 70
        Top = 7
        Width = 61
        Height = 15
        Caption = '0 com erro'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clRed
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblResumoIgnorado: TLabel
        Left = 170
        Top = 7
        Width = 91
        Height = 15
        Caption = '0 n'#227'o executados'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGrayText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
    end
    object memoLog: TMemo
      Left = 0
      Top = 86
      Width = 536
      Height = 416
      Align = alClient
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Consolas'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 2
      WantReturns = False
    end
    object btnSalvarLog: TButton
      Left = 0
      Top = 502
      Width = 536
      Height = 28
      Align = alBottom
      Caption = 'Salvar log...'
      TabOrder = 3
      Visible = False
      OnClick = btnSalvarLogClick
    end
  end
  object dlgAbrirExec: TOpenDialog
    Filter = 'Execut'#225'vel (*.exe)|*.exe'
    Title = 'Selecionar execut'#225'vel PDV'
    Left = 920
    Top = 60
  end
end
