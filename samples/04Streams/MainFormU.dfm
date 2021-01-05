object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'REDIS Streams Sample'
  ClientHeight = 367
  ClientWidth = 724
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 0
    Top = 65
    Width = 724
    Height = 5
    Cursor = crVSplit
    Align = alTop
    ExplicitTop = 85
  end
  object Memo1: TMemo
    Left = 0
    Top = 70
    Width = 724
    Height = 297
    Align = alClient
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    WordWrap = False
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 724
    Height = 65
    Align = alTop
    TabOrder = 1
    object btnConn: TButton
      AlignWithMargins = True
      Left = 4
      Top = 4
      Width = 105
      Height = 57
      Align = alLeft
      Caption = 'Button1'
      TabOrder = 0
      OnClick = btnConnClick
    end
    object pnlToolbar: TPanel
      Left = 112
      Top = 1
      Width = 611
      Height = 63
      Align = alClient
      BevelOuter = bvLowered
      Caption = 'pnlToolbar'
      TabOrder = 1
      object btnSubscription: TButton
        AlignWithMargins = True
        Left = 4
        Top = 4
        Width = 161
        Height = 55
        Align = alLeft
        Caption = 'Subscribe'
        TabOrder = 0
        WordWrap = True
        OnClick = btnSubscriptionClick
      end
      object btnXADD: TButton
        AlignWithMargins = True
        Left = 260
        Top = 4
        Width = 83
        Height = 55
        Align = alLeft
        Caption = 'XADD'
        TabOrder = 1
        OnClick = btnXADDClick
      end
      object btnXRANGE: TButton
        AlignWithMargins = True
        Left = 349
        Top = 4
        Width = 83
        Height = 55
        Align = alLeft
        Caption = 'XRANGE (get all)'
        TabOrder = 2
        WordWrap = True
        OnClick = btnXRANGEClick
      end
      object btnAnotherMe: TButton
        Left = 551
        Top = 1
        Width = 59
        Height = 61
        Align = alRight
        Caption = 'New Instance'
        TabOrder = 3
        WordWrap = True
        OnClick = btnAnotherMeClick
      end
      object btnXREAD: TButton
        AlignWithMargins = True
        Left = 438
        Top = 4
        Width = 83
        Height = 55
        Align = alLeft
        Caption = 'XREAD (get new)'
        TabOrder = 4
        WordWrap = True
        OnClick = btnXREADClick
      end
      object btnBulkXADD: TButton
        AlignWithMargins = True
        Left = 171
        Top = 4
        Width = 83
        Height = 55
        Align = alLeft
        Caption = 'XADD (bulk)'
        TabOrder = 5
        OnClick = btnBulkXADDClick
      end
    end
  end
  object ApplicationEvents1: TApplicationEvents
    OnIdle = ApplicationEvents1Idle
    Left = 360
    Top = 192
  end
end
