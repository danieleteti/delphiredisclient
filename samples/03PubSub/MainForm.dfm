object Form2: TForm2
  Left = 0
  Top = 0
  Caption = 'Redis Chat'
  ClientHeight = 461
  ClientWidth = 306
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -16
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  DesignSize = (
    306
    461)
  PixelsPerInch = 96
  TextHeight = 19
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 46
    Height = 19
    Caption = 'Label1'
  end
  object Memo1: TMemo
    Left = 8
    Top = 56
    Width = 290
    Height = 369
    Anchors = [akLeft, akTop, akRight, akBottom]
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Consolas'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    TabOrder = 0
  end
  object Edit2: TEdit
    Left = 8
    Top = 429
    Width = 290
    Height = 27
    Margins.Left = 10
    Margins.Right = 10
    Margins.Bottom = 5
    Anchors = [akLeft, akRight, akBottom]
    TabOrder = 1
    TextHint = 'Write your message here...'
    OnKeyUp = Edit2KeyUp
  end
  object Button1: TButton
    Left = 200
    Top = 8
    Width = 98
    Height = 42
    Caption = 'Launch Another Instance'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 2
    WordWrap = True
    OnClick = Button1Click
  end
end
