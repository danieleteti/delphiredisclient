object Form2: TForm2
  Left = 0
  Top = 0
  Caption = 'REDIS Distributed Cache Sample'
  ClientHeight = 477
  ClientWidth = 853
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object DBGrid1: TDBGrid
    Left = 0
    Top = 56
    Width = 853
    Height = 380
    Align = alClient
    DataSource = DataSource1
    TabOrder = 0
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'Tahoma'
    TitleFont.Style = []
    Columns = <
      item
        Expanded = False
        FieldName = 'CUST_NO'
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CUSTOMER'
        Width = 192
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CONTACT_FIRST'
        Width = 112
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CONTACT_LAST'
        Width = 119
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'PHONE_NO'
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'ADDRESS_LINE1'
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'ADDRESS_LINE2'
        Width = 126
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CITY'
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'STATE_PROVINCE'
        Width = 106
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'COUNTRY'
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'POSTAL_CODE'
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'ON_HOLD'
        Visible = True
      end>
  end
  object Panel1: TPanel
    Left = 0
    Top = 436
    Width = 853
    Height = 41
    Align = alBottom
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    object Label1: TLabel
      AlignWithMargins = True
      Left = 4
      Top = 4
      Width = 127
      Height = 33
      Align = alLeft
      Caption = 'Ready to search...'
      Layout = tlCenter
      ExplicitHeight = 19
    end
    object Button2: TButton
      AlignWithMargins = True
      Left = 739
      Top = 4
      Width = 110
      Height = 33
      Align = alRight
      Caption = 'New Instance'
      TabOrder = 0
      OnClick = Button2Click
    end
  end
  object Panel3: TPanel
    Left = 0
    Top = 0
    Width = 853
    Height = 56
    Align = alTop
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 2
    DesignSize = (
      853
      56)
    object Button1: TButton
      AlignWithMargins = True
      Left = 635
      Top = 4
      Width = 214
      Height = 48
      Align = alRight
      Caption = '&Search'
      Default = True
      TabOrder = 0
      OnClick = Button1Click
    end
    object Edit1: TEdit
      Left = 16
      Top = 14
      Width = 613
      Height = 27
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 1
      TextHint = 'Search...'
    end
  end
  object DataSource1: TDataSource
    DataSet = FDQuery1
    Left = 208
    Top = 216
  end
  object FDConnection1: TFDConnection
    Params.Strings = (
      'Database=employee'
      'User_Name=sysdba'
      'Password=masterkey'
      'Protocol=TCPIP'
      'Server=localhost'
      'CharacterSet=UTF8'
      'DriverID=FB')
    LoginPrompt = False
    Left = 288
    Top = 288
  end
  object FDQuery1: TFDQuery
    Connection = FDConnection1
    SQL.Strings = (
      'select * from customer')
    Left = 288
    Top = 216
  end
  object FDStanStorageJSONLink1: TFDStanStorageJSONLink
    Left = 288
    Top = 368
  end
end
