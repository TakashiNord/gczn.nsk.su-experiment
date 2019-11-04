unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP,
  StdCtrls, OleCtrls;

type
  TForm2 = class(TForm)
    IdHTTPsocket: TIdHTTP;
    ButtonUpdate: TButton;
    Memo1: TMemo;
    Label1: TLabel;
    Edit1: TEdit;
    Label2: TLabel;
    procedure ButtonUpdateClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

implementation

uses RegExpr, NativeXml;

{$R *.dfm}

procedure TForm2.ButtonUpdateClick(Sender: TObject);
const
  DestPath = 'dest.xml';
  SrcPath = DestPath;
var
  strGet : string ;
  url , urlcurr : string ;
  i : Integer ;

  XMLDoc: TNativeXml;
  Node,Sub: TXmlNode;

  eRec : integer ;
  pN : integer;
  sS, sS0, sS1, sS2 : String ;
 
  strDiv : string ;
  r , r2 : TRegExpr;

  strFile : string ;

begin

  pN:=StrToInt(Edit1.Text);
  ButtonUpdate.Enabled:=FALSE;

  url := 'http://www.gczn.nsk.su//?option=com_helloworld&template=gczn_vac&vacancy=';

  XMLDoc:=TNativeXml.Create(nil);//������� ��������

  XMLDoc.CreateName('Vacancies');//������� �������� ����

  eRec := 0 ; // ����� ��������� �������
  i:=1;
while (eRec<=20) do begin

  urlcurr:=url + IntToStr(i) ;
  try
    strGet :=IdHTTPsocket.Get(urlcurr);
  except on e : EIDHttpProtocolException do
     Begin if e.ErrorCode = 302 then
      begin
       try
        // �������� ����� ����� - ����� ���������������
       strGet :=IdHTTPsocket.Get(IdHTTPsocket.Response.Location);
       except on e:Exception do
             // ���������������, ��� ���������� ����� ���������� � ���
        ShowMessage(' ������ ��� ��������� ������ ������ .'+e.Message);
       end;
      end
     else
         //http 404, 501 � ��� �����
       ShowMessage(' ������ :'+e.Message);
  end;
   on e:Exception do
     ShowMessage('������: ' + e.Message);
   end;

  //Memo1.Text:=strGet ;
  strDiv:='';

  Label1.Caption:=  IntToStr(i) ;
  Label1.Repaint;
  Label1.Refresh ;

  Application.ProcessMessages;

  //������� �������� ����
  Node := XMLDoc.Root.NodeNew('Vacancy');
  //Node.AttributeAdd('number',IntToStr(i));//��������� ������� integer
  //Node.WriteAttributeDateTime('date',Now,Now);//������ ������. ���������� ����
  Sub := Node.NodeNew('ID');
  Sub.ValueUnicode := IntToStr(i); 
  //XMLDoc.Root.NodeAdd(Node);

  r := TRegExpr.Create;
  try
     
     // ������� ��� �����������
     r.Expression := '<!--div.*div-->|<b>|</b>|<small>|</small>|&nbsp;|class=|\"clear\"|\"full_vac\"|\"vac_general\"|\"vac_header\"|\"vac_trebovanie|vac_after_header\"|\"vac_podrobnee|vac_after_header\"|\"vac_predpriyatie|style=\"display:block;\"';
     r.ModifierI:=TRUE;  r.ModifierS:=TRUE;  r.ModifierG:=FALSE;
     strDiv:=r.Replace(strGet,'',FALSE);
     strGet:=strDiv;
     
     // ����� �� ���� div
     strDiv:='';
     r.Expression := '<div.*/div>';
     if r.Exec(strGet) then
      REPEAT
       //strDiv := strDiv + r.Match [0] + '';
 
       sS0:= r.Match[0]; // vac_num_vac.*>.*<

       if (0<>Pos('vac_num_vac', sS0)) then begin

        sS1:=''; sS2:='';
        r2 := TRegExpr.Create;
        try
          r2.Expression := '>.*<';
          r2.ModifierI:=TRUE;   r2.ModifierS:=TRUE;   r2.ModifierG:=FALSE;
          if r2.Exec(sS0) then
            REPEAT
             sS1  := StringReplace(r2.Match [0], '>', '',[rfReplaceAll, rfIgnoreCase]);
             sS2  := StringReplace(sS1, '<', '',[rfReplaceAll, rfIgnoreCase]);
            UNTIL not r2.ExecNext;
        finally r2.Free; end ;

        //���� �����������
        if (0 <> Pos('���� �����������', sS2)) then begin
          sS:=StringReplace(sS2, '���� �����������', '',[rfReplaceAll, rfIgnoreCase]);
          sS:=Trim(sS);
          Sub := Node.NodeNew('���� �����������');
          Sub.ValueUnicode := sS;
          if (0 <> Pos('1970', sS)) then eRec :=eRec+1;
        end ;
         
        //�
        if (0 <> Pos('�', sS2)) then begin
          sS:=StringReplace(sS2, '�', '',[rfReplaceAll, rfIgnoreCase]);
          sS:=Trim(sS);
          Sub := Node.NodeNew('N');
          Sub.ValueUnicode := sS;
        end ;

       end ; // vac_num_vac      

       if (0<>Pos('vac_param_name', sS0)) then begin
          r2 := TRegExpr.Create;
          try
            r2.Expression := '>.*<';
            r2.ModifierI:=TRUE;   r2.ModifierS:=TRUE;   r2.ModifierG:=FALSE;
            if r2.Exec(sS0) then
              REPEAT
                sS1  := StringReplace(r2.Match [0], '>', '',[rfReplaceAll, rfIgnoreCase]);
                sS2  := StringReplace(sS1, '<', '',[rfReplaceAll, rfIgnoreCase]);
                sS2  := Trim(sS2);
              UNTIL not r2.ExecNext;
          finally r2.Free; end ;          
          if sS2<>'' then Sub := Node.NodeNew(Utf8String(sS2));
       end ; // vac_param_name

       if (0<>Pos('"vac_param"', sS0)) then begin
          r2 := TRegExpr.Create;
          try
            r2.Expression := '>.*<';
            r2.ModifierI:=TRUE;   r2.ModifierS:=TRUE;   r2.ModifierG:=FALSE;
            if r2.Exec(sS0) then
              REPEAT
                sS1  := StringReplace(r2.Match [0], '>', '',[rfReplaceAll, rfIgnoreCase]);
                sS2  := StringReplace(sS1, '<', '',[rfReplaceAll, rfIgnoreCase]);
                sS2  := Trim(sS2);
              UNTIL not r2.ExecNext;
          finally r2.Free; end ;
          if sS2='' then sS2 := ' ';
          Sub.ValueUnicode := sS2;
       end ; // vac_param      
       

      UNTIL not r.ExecNext;
    finally r.Free;
   end;

   Application.ProcessMessages;

   if (pN>0) then if (i>=pN) then eRec:=Abs(pN)+20; //break ;

   //if (eRec>20) then break ;

   i:=i+1;
end;

  //������ ��������� ���������
  //XMLDoc.WriteOnDefault:=false;
  XMLDoc.CommentString:='�������� www.gczn.nsk.su';
  //XMLDoc.ExternalEncoding := seUTF8;
  //XMLDoc.Charset := 'utf-8';
  XMLDoc.VersionString:='1.0';
  XMLDoc.XmlFormat:= xfReadable;
  //XMLDoc.EolStyle:=esCRLF;

  strFile:='gczn.nsk.su-'+IntToStr(i-1)+'.xml';

  XMLDoc.SaveToFile(strFile);

  ButtonUpdate.Enabled:=True;

end;

procedure TForm2.FormCreate(Sender: TObject);
begin
  Memo1.Text:='';
  Label1.Caption:='0';
  Edit1.Text:='0';
end;

end.
