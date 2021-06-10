object FrmMQTTConfig: TFrmMQTTConfig
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'MQTT'#37197#32622
  ClientHeight = 263
  ClientWidth = 446
  Color = clBtnFace
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -17
  Font.Name = #23435#20307
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 17
  object pnl2: TPanel
    Left = 0
    Top = 201
    Width = 446
    Height = 62
    Align = alClient
    TabOrder = 0
    object BtnCSLJ: TBitBtn
      Left = 15
      Top = 6
      Width = 75
      Height = 25
      Caption = 'MQ'#27979#35797
      ParentDoubleBuffered = True
      TabOrder = 0
      OnClick = BtnCSLJClick
    end
    object BtnMod: TBitBtn
      Left = 96
      Top = 6
      Width = 75
      Height = 25
      Caption = #20462#25913
      ParentDoubleBuffered = True
      TabOrder = 1
      OnClick = BtnModClick
    end
    object BtnSave: TBitBtn
      Left = 177
      Top = 6
      Width = 75
      Height = 25
      Caption = #23384#30424
      ParentDoubleBuffered = True
      TabOrder = 2
      OnClick = BtnSaveClick
    end
    object BtnCancel: TBitBtn
      Left = 258
      Top = 6
      Width = 75
      Height = 25
      Caption = #25918#24323
      ParentDoubleBuffered = True
      TabOrder = 3
      OnClick = BtnCancelClick
    end
    object stat1: TStatusBar
      Left = 1
      Top = 42
      Width = 444
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
    object ckMQTT: TCheckBox
      Left = 339
      Top = 6
      Width = 92
      Height = 25
      Caption = #21551#29992'MQTT'
      TabOrder = 5
      OnClick = ckMQTTClick
    end
  end
  object pnl1: TPanel
    Left = 0
    Top = 0
    Width = 446
    Height = 201
    Align = alTop
    TabOrder = 1
    object lbl1: TLabel
      Left = 12
      Top = 12
      Width = 85
      Height = 17
      Caption = #26381#21153#22120#22320#22336
    end
    object lbl2: TLabel
      Left = 12
      Top = 38
      Width = 69
      Height = 17
      Caption = #23458#25143#31471'ID'
    end
    object lbl3: TLabel
      Left = 12
      Top = 68
      Width = 69
      Height = 17
      Caption = #29992' '#25143' '#21517
    end
    object lbl5: TLabel
      Left = 12
      Top = 99
      Width = 70
      Height = 17
      Caption = #23494'    '#30721
    end
    object lbl4: TLabel
      Left = 12
      Top = 129
      Width = 68
      Height = 17
      Caption = #35746#38405#20027#39064
    end
    object lbl6: TLabel
      Left = 12
      Top = 159
      Width = 68
      Height = 17
      Caption = #21457#36865#28040#24687
    end
    object EdtServer: TEdit
      Left = 103
      Top = 5
      Width = 177
      Height = 25
      Hint = #25968#25454#24211#30340#26381#21153#22120#22320#22336
      ImeMode = imDisable
      ParentShowHint = False
      ShowHint = True
      TabOrder = 0
      Text = '127.0.0.1:8080'
    end
    object EdtClientID: TEdit
      Left = 103
      Top = 35
      Width = 177
      Height = 25
      Hint = #21457#36865#28040#24687#30340#23458#25143#31471'ID'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 1
      Text = 'YxCisSvr'
    end
    object EdtUserName: TEdit
      Left = 103
      Top = 65
      Width = 177
      Height = 25
      ParentShowHint = False
      ShowHint = True
      TabOrder = 2
      Text = 'admin'
    end
    object EdtPass: TEdit
      Left = 103
      Top = 96
      Width = 177
      Height = 25
      ParentShowHint = False
      PasswordChar = '*'
      ShowHint = True
      TabOrder = 3
      Text = 'password'
    end
    object ckReConnect: TCheckBox
      Left = 286
      Top = 5
      Width = 97
      Height = 17
      Caption = #33258#21160#37325#36830
      TabOrder = 4
    end
    object EdtSub: TEdit
      Left = 103
      Top = 126
      Width = 121
      Height = 25
      TabOrder = 5
      Text = 'YxCisSvr'
    end
    object ckSub: TCheckBox
      Left = 230
      Top = 129
      Width = 54
      Height = 17
      Caption = #35746#38405
      TabOrder = 6
    end
    object EdtPub: TEdit
      Left = 103
      Top = 156
      Width = 121
      Height = 25
      TabOrder = 7
      Text = 'YxCisSvrRet'
    end
    object cbbSubQos: TComboBox
      Left = 286
      Top = 99
      Width = 145
      Height = 25
      Style = csDropDownList
      ImeName = #20013#25991'('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
      ItemIndex = 0
      TabOrder = 8
      Text = 'Qos0('#33267#22810#19968#27425')'
      Items.Strings = (
        'Qos0('#33267#22810#19968#27425')'
        'Qos1('#33267#23569#19968#27425')'
        'Qos2('#21482#26377#19968#27425')')
    end
    object ckAutoPing: TCheckBox
      Left = 286
      Top = 65
      Width = 145
      Height = 17
      Caption = #33258#21160#21457#36865#24515#36339#21253
      TabOrder = 9
    end
    object ckRetain: TCheckBox
      Left = 230
      Top = 159
      Width = 54
      Height = 17
      Caption = #20445#30041
      TabOrder = 10
    end
    object ckclearsession: TCheckBox
      Left = 286
      Top = 35
      Width = 129
      Height = 17
      Caption = #20851#38381#20250#35805#37325#29992
      TabOrder = 11
    end
  end
end
