object FrmSQLConnect: TFrmSQLConnect
  Left = 859
  Top = 337
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = #25968#25454#24211#37197#32622
  ClientHeight = 262
  ClientWidth = 394
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -17
  Font.Name = #23435#20307
  Font.Style = []
  FormStyle = fsStayOnTop
  GlassFrame.Enabled = True
  GlassFrame.SheetOfGlass = True
  OldCreateOrder = True
  Position = poScreenCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 17
  object lbl1: TLabel
    Left = 40
    Top = 16
    Width = 85
    Height = 17
    Caption = #26381#21153#22120#22320#22336
  end
  object lbl2: TLabel
    Left = 40
    Top = 59
    Width = 85
    Height = 17
    Caption = #25968#25454#24211#21517#31216
  end
  object lbl3: TLabel
    Left = 40
    Top = 97
    Width = 69
    Height = 17
    Caption = #29992' '#25143' '#21517
  end
  object lbl4: TLabel
    Left = 40
    Top = 168
    Width = 34
    Height = 17
    Caption = #31471#21475
    Visible = False
  end
  object lbl5: TLabel
    Left = 40
    Top = 136
    Width = 70
    Height = 17
    Caption = #23494'    '#30721
  end
  object EdtServer: TEdit
    Left = 160
    Top = 13
    Width = 177
    Height = 25
    Hint = #25968#25454#24211#30340#26381#21153#22120#22320#22336
    Enabled = False
    ParentShowHint = False
    ShowHint = True
    TabOrder = 0
  end
  object EdtDBName: TEdit
    Left = 160
    Top = 55
    Width = 177
    Height = 25
    Hint = #40664#35748#30331#24405#36830#25509#30340#25968#25454#24211#21517#31216'(YXHIS)'
    Enabled = False
    ParentShowHint = False
    ShowHint = True
    TabOrder = 1
    Text = 'YXHIS'
  end
  object EdtUserName: TEdit
    Left = 160
    Top = 92
    Width = 177
    Height = 25
    Hint = #25968#25454#24211#30331#24405#21517
    Enabled = False
    ParentShowHint = False
    ShowHint = True
    TabOrder = 2
    Text = 'sa'
  end
  object EdtPass: TEdit
    Left = 160
    Top = 130
    Width = 177
    Height = 25
    Hint = #25968#25454#24211#23494#30721
    Enabled = False
    ParentShowHint = False
    PasswordChar = '*'
    ShowHint = True
    TabOrder = 3
    Text = '123qwe,.'
  end
  object EdtPort: TEdit
    Left = 160
    Top = 165
    Width = 177
    Height = 25
    Enabled = False
    TabOrder = 4
    Text = '1433'
    Visible = False
  end
  object BtnCSLJ: TBitBtn
    Left = 31
    Top = 207
    Width = 75
    Height = 25
    Caption = #27979#35797#38142#25509
    ParentDoubleBuffered = True
    TabOrder = 5
    OnClick = BtnCSLJClick
  end
  object BtnMod: TBitBtn
    Left = 112
    Top = 207
    Width = 75
    Height = 25
    Caption = #20462#25913
    ParentDoubleBuffered = True
    TabOrder = 6
    OnClick = BtnModClick
  end
  object BtnSave: TBitBtn
    Left = 193
    Top = 207
    Width = 75
    Height = 25
    Caption = #23384#30424
    ParentDoubleBuffered = True
    TabOrder = 7
    OnClick = BtnSaveClick
  end
  object BtnCancel: TBitBtn
    Left = 274
    Top = 207
    Width = 75
    Height = 25
    Caption = #25918#24323
    ParentDoubleBuffered = True
    TabOrder = 8
    OnClick = BtnCancelClick
  end
  object ck1: TCheckBox
    Left = 343
    Top = 135
    Width = 13
    Height = 13
    Hint = #26174#31034#23494#30721
    ParentShowHint = False
    ShowHint = True
    TabOrder = 9
    OnClick = ck1Click
  end
end
