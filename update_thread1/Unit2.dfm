object Form2: TForm2
  Left = 0
  Top = 0
  Caption = 'Form2'
  ClientHeight = 305
  ClientWidth = 386
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
  object Label1: TLabel
    Left = 281
    Top = 25
    Width = 31
    Height = 13
    Caption = 'Label1'
  end
  object Label2: TLabel
    Left = 168
    Top = 25
    Width = 107
    Height = 13
    Caption = #1055#1086#1083#1091#1095#1077#1085#1086' '#1079#1072#1087#1080#1089#1077#1081' :='
  end
  object ButtonUpdate: TButton
    Left = 88
    Top = 8
    Width = 74
    Height = 49
    Caption = 'Update'
    TabOrder = 0
    OnClick = ButtonUpdateClick
  end
  object Memo1: TMemo
    Left = 8
    Top = 63
    Width = 370
    Height = 234
    Lines.Strings = (
      'Memo1')
    ScrollBars = ssBoth
    TabOrder = 1
  end
  object Edit1: TEdit
    Left = 8
    Top = 22
    Width = 74
    Height = 21
    TabOrder = 2
    Text = 'Edit1'
  end
  object IdHTTPsocket: TIdHTTP
    AllowCookies = True
    ProxyParams.BasicAuthentication = False
    ProxyParams.ProxyPort = 0
    Request.ContentLength = -1
    Request.Accept = 'text/html, */*'
    Request.BasicAuthentication = False
    Request.UserAgent = 'Mozilla/3.0 (compatible; Indy Library)'
    HTTPOptions = [hoForceEncodeParams]
    Left = 72
    Top = 80
  end
end
