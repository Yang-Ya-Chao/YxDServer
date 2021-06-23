object FrmSvrConfig: TFrmSvrConfig
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = #25509#21475#37197#32622
  ClientHeight = 199
  ClientWidth = 344
  Color = clBtnFace
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -17
  Font.Name = #23435#20307
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Position = poScreenCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 17
  object pnl2: TPanel
    Left = 0
    Top = 165
    Width = 344
    Height = 34
    Align = alClient
    TabOrder = 0
    ExplicitTop = 151
    ExplicitHeight = 40
    object BtnSQL: TBitBtn
      Left = 193
      Top = 6
      Width = 75
      Height = 25
      Caption = #25968#25454#24211
      ParentDoubleBuffered = True
      TabOrder = 0
      OnClick = BtnSQLClick
    end
    object BtnCancel: TBitBtn
      Left = 128
      Top = 6
      Width = 49
      Height = 25
      Caption = #25918#24323
      ParentDoubleBuffered = True
      TabOrder = 1
      OnClick = BtnCancelClick
    end
    object BtnSave: TBitBtn
      Left = 64
      Top = 3
      Width = 49
      Height = 25
      Caption = #23384#30424
      ParentDoubleBuffered = True
      TabOrder = 2
      OnClick = BtnSaveClick
    end
    object BtnMod: TBitBtn
      Left = 0
      Top = 3
      Width = 49
      Height = 25
      Caption = #20462#25913
      ParentDoubleBuffered = True
      TabOrder = 3
      OnClick = BtnModClick
    end
    object BitBtn1: TBitBtn
      Left = 283
      Top = 3
      Width = 55
      Height = 25
      Caption = 'MQTT'
      TabOrder = 4
      OnClick = BitBtn1Click
    end
  end
  object pnl1: TPanel
    Left = 0
    Top = 0
    Width = 344
    Height = 165
    Align = alTop
    TabOrder = 1
    object lbl1: TLabel
      Left = 15
      Top = 140
      Width = 102
      Height = 17
      Caption = #24037#20316#32447#31243#24635#25968
    end
    object lbl2: TLabel
      Left = 140
      Top = 9
      Width = 34
      Height = 17
      Caption = #31471#21475
    end
    object lbl3: TLabel
      Left = 15
      Top = 95
      Width = 145
      Height = 17
      Caption = #26085#24535#20998#39029#22823#23567#65288'M'#65289
    end
    object EdtWorkcount: TEdit
      Left = 140
      Top = 137
      Width = 141
      Height = 25
      NumbersOnly = True
      TabOrder = 0
      OnExit = EdtWorkcountExit
      OnKeyPress = EdtWorkcountKeyPress
    end
    object rbWEB: TRadioButton
      Left = 15
      Top = 117
      Width = 113
      Height = 17
      Caption = 'WEBSERVICE'
      Checked = True
      TabOrder = 1
      TabStop = True
    end
    object ckDEBUG: TCheckBox
      Left = 15
      Top = 71
      Width = 126
      Height = 17
      Caption = #35760#24405#25509#21475#26085#24535
      TabOrder = 2
    end
    object ckReBoot: TCheckBox
      Left = 15
      Top = 50
      Width = 126
      Height = 17
      Caption = #25509#21475#23450#26102#37325#21551
      TabOrder = 3
      OnClick = ckReBootClick
    end
    object rbHTTP: TRadioButton
      Left = 140
      Top = 117
      Width = 57
      Height = 17
      Caption = 'HTTP'
      TabOrder = 4
    end
    object EdtReBootT: TEdit
      Left = 140
      Top = 45
      Width = 141
      Height = 25
      Hint = #37325#21551#38388#38548#26102#38388'('#22825')'
      NumbersOnly = True
      ParentShowHint = False
      ShowHint = True
      TabOrder = 5
      TextHint = #37325#21551#38388#38548#26102#38388'('#22825')'
      Visible = False
      OnExit = EdtReBootTExit
      OnKeyPress = EdtWorkcountKeyPress
    end
    object ckAutoRun: TCheckBox
      Left = 15
      Top = 29
      Width = 126
      Height = 17
      Caption = #24320#26426#33258#21160#21551#21160
      TabOrder = 6
    end
    object ckRun: TCheckBox
      Left = 15
      Top = 8
      Width = 126
      Height = 17
      Caption = #33258#21160#24320#22987#26381#21153
      Checked = True
      State = cbChecked
      TabOrder = 7
    end
    object EdtPort: TEdit
      Left = 179
      Top = 6
      Width = 102
      Height = 25
      NumbersOnly = True
      TabOrder = 8
    end
    object BtnCheckPort: TBitBtn
      Left = 288
      Top = 6
      Width = 42
      Height = 25
      Caption = #26816#27979
      TabOrder = 9
      OnClick = BtnCheckPortClick
    end
    object EdtSize: TEdit
      Left = 163
      Top = 93
      Width = 42
      Height = 25
      NumbersOnly = True
      TabOrder = 10
      Text = '10'
      OnExit = EdtSizeExit
      OnKeyPress = EdtSizeKeyPress
    end
    object ckHTTPS: TCheckBox
      Left = 216
      Top = 117
      Width = 65
      Height = 17
      Caption = 'HTTPS'
      TabOrder = 11
    end
    object ckSQLDEBUG: TCheckBox
      Left = 140
      Top = 71
      Width = 126
      Height = 17
      Caption = #35760#24405'SQL'#26085#24535
      TabOrder = 12
    end
  end
end
