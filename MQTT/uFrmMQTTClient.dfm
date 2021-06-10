object FrmMQTTClient: TFrmMQTTClient
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'MQTT'#23458#25143#31471#27979#35797
  ClientHeight = 534
  ClientWidth = 857
  Color = clBtnFace
  Font.Charset = GB2312_CHARSET
  Font.Color = clWindowText
  Font.Height = -17
  Font.Name = #23435#20307
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 17
  object MMLog: TMemo
    Left = 0
    Top = 281
    Width = 857
    Height = 234
    Align = alClient
    Color = clBlack
    Font.Charset = GB2312_CHARSET
    Font.Color = clWhite
    Font.Height = -14
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    ImeName = #20013#25991'('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    Lines.Strings = (
      'mmLog')
    ParentFont = False
    ScrollBars = ssBoth
    TabOrder = 0
  end
  object pnl1: TPanel
    Left = 0
    Top = 0
    Width = 857
    Height = 281
    Align = alTop
    TabOrder = 1
    object lbl2: TLabel
      Left = 8
      Top = 102
      Width = 68
      Height = 17
      Caption = #21457#36865#28040#24687
    end
    object lbl1: TLabel
      Left = 8
      Top = 72
      Width = 68
      Height = 17
      Caption = #21457#36865#20027#39064
    end
    object lbl3: TLabel
      Left = 8
      Top = 41
      Width = 68
      Height = 17
      Caption = #35746#38405#20027#39064
    end
    object btnPublish: TButton
      Left = 455
      Top = 219
      Width = 67
      Height = 54
      Caption = #21457#36865
      TabOrder = 0
      OnClick = btnPublishClick
    end
    object EdtPubTopic: TEdit
      Left = 80
      Top = 68
      Width = 369
      Height = 25
      ImeName = #20013#25991'('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
      TabOrder = 1
      Text = 'YxCisSvrRet'
    end
    object btnPing: TButton
      Left = 8
      Top = 8
      Width = 75
      Height = 25
      Caption = 'PING'
      TabOrder = 2
    end
    object mmo1: TMemo
      Left = 80
      Top = 99
      Width = 369
      Height = 174
      Lines.Strings = (
        'Copy That'#65281)
      TabOrder = 3
    end
    object Connect: TBitBtn
      Left = 99
      Top = 8
      Width = 70
      Height = 25
      Caption = #38142#25509
      TabOrder = 4
      OnClick = ConnectClick
    end
    object DisConnect: TBitBtn
      Left = 175
      Top = 8
      Width = 72
      Height = 25
      Caption = #26029#24320
      TabOrder = 5
      OnClick = DisConnectClick
    end
    object EdtSubTopic: TEdit
      Left = 80
      Top = 37
      Width = 369
      Height = 25
      ImeName = #20013#25991'('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
      TabOrder = 6
      Text = 'YxCisSvr'
    end
    object btnSub: TButton
      Left = 455
      Top = 35
      Width = 67
      Height = 29
      Caption = #35746#38405
      TabOrder = 7
      OnClick = btnSubClick
    end
    object btnDisSub: TButton
      Left = 528
      Top = 35
      Width = 67
      Height = 29
      Caption = #21462#28040
      TabOrder = 8
      OnClick = btnDisSubClick
    end
  end
  object stat1: TStatusBar
    Left = 0
    Top = 515
    Width = 857
    Height = 19
    Panels = <
      item
        Width = 200
      end
      item
        Width = 80
      end
      item
        Width = 260
      end
      item
        Width = 50
      end>
  end
end
