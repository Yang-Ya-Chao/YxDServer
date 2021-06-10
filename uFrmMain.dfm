object MainForm: TMainForm
  Left = 207
  Top = 87
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'YxDSvr'#24212#29992#26381#21153#22120
  ClientHeight = 92
  ClientWidth = 237
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  FormStyle = fsStayOnTop
  GlassFrame.Enabled = True
  GlassFrame.SheetOfGlass = True
  OldCreateOrder = True
  Position = poScreenCenter
  OnActivate = FormActivate
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object lbl1: TLabel
    Left = 2
    Top = 40
    Width = 39
    Height = 13
    Hint = #21344#29992'CPU'#65307#21344#29992#20869#23384#65307#32447#31243#25968
    Caption = #29366#24577#65306
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
    ParentShowHint = False
    ShowHint = True
  end
  object lbl2: TLabel
    Left = 47
    Top = 39
    Width = 3
    Height = 13
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlue
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object lbl3: TLabel
    Left = 47
    Top = 58
    Width = 3
    Height = 13
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlue
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object lbl4: TLabel
    Left = 2
    Top = 58
    Width = 39
    Height = 13
    Hint = #24037#20316#22312#29992#32447#31243#25968'/'#24037#20316#24635#32447#31243#25968#65307#36816#34892#26102#38388
    Caption = #36816#34892#65306
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
    ParentShowHint = False
    ShowHint = True
  end
  object lbl5: TLabel
    Left = 2
    Top = 76
    Width = 39
    Height = 13
    Hint = 'T:'#35831#27714#24635#25968#65307'N:'#35831#27714#22833#36133#25968
    Caption = #35831#27714#65306
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
    ParentShowHint = False
    ShowHint = True
  end
  object lbl6: TLabel
    Left = 47
    Top = 75
    Width = 3
    Height = 13
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlue
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object btnStart: TBitBtn
    Left = 28
    Top = 8
    Width = 75
    Height = 25
    Caption = #24320#22987#26381#21153
    TabOrder = 0
    TabStop = False
    OnClick = btnStartClick
  end
  object btnStop: TBitBtn
    Left = 131
    Top = 8
    Width = 75
    Height = 25
    Caption = #20572#27490#26381#21153
    TabOrder = 1
    TabStop = False
    OnClick = btnStopClick
  end
  object pm1: TPopupMenu
    Left = 208
    Top = 38
    object N1: TMenuItem
      Caption = #24320#22987#26381#21153
      OnClick = N1Click
    end
    object N2: TMenuItem
      Caption = #20572#27490#26381#21153
      OnClick = N2Click
    end
    object N3: TMenuItem
      Caption = #36824#21407
      OnClick = N3Click
    end
    object N4: TMenuItem
      Caption = #36864#20986
      OnClick = N4Click
    end
  end
  object tmr1: TTimer
    OnTimer = tmr1Timer
    Left = 154
    Top = 64
  end
  object tmr2: TTimer
    Enabled = False
    OnTimer = tmr2Timer
    Left = 181
    Top = 64
  end
end
