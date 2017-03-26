object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Redis JobQueue Sample'
  ClientHeight = 367
  ClientWidth = 534
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -16
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  DesignSize = (
    534
    367)
  PixelsPerInch = 96
  TextHeight = 19
  object Edit1: TEdit
    Left = 8
    Top = 8
    Width = 417
    Height = 27
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 0
    Text = '3+2-4/2*5+10'
  end
  object Button1: TButton
    Left = 431
    Top = 8
    Width = 95
    Height = 27
    Anchors = [akTop, akRight]
    Caption = 'Get Result'
    TabOrder = 1
    OnClick = Button1Click
  end
  object Memo1: TMemo
    Left = 8
    Top = 41
    Width = 518
    Height = 321
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 2
  end
  object Timer1: TTimer
    Enabled = False
    OnTimer = Timer1Timer
    Left = 152
    Top = 88
  end
end
