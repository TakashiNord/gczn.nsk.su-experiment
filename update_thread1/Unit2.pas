unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP,
  StdCtrls, OleCtrls, RegExpr, NativeXml,SyncObjs;

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
	ThreadRefCount: integer;
    procedure HandleTerminate(Sender: TObject);
  end;

TElement = TStringList;
  TNodePointer = ^TNode;
  TNode = record
    value: TElement;
    next: TNodePointer;
  end;

  TMyStack = class(TObject)
  private
    fHead: TNodePointer;
  public
    constructor Create;
    destructor Destroy;
    procedure Add(item: TElement);
    function Take: TElement;
    function isEmpty: boolean;
  end;

  TGetThread = class(TThread)
    HTTP: TIdHTTP;
    procedure Execute; override;
    public
     ls:TStringList ;
     url:string;
     index:integer;
	 ThreadRefCount: integer;
     procedure Sync ;
  end;

var
  Form2: TForm2;
  CriticalSection: TCriticalSection;
  mySt:TMyStack;
  Lock : TMultiReadExclusiveWriteSynchronizer;
  List : TStringList;

implementation

{$R *.dfm}


constructor TMyStack.Create;
  begin
    fHead:= nil;
  end;

  destructor TMyStack.Destroy;
  begin
    while not isEmpty do
      Take;
    fHead:= nil;
  end;

procedure TMyStack.Add(item: TElement);
  var
    temp: TNodePointer;
  begin
    New(temp);
    temp^.value:= item;
    temp^.next:= nil;
    if (isEmpty) then
      fHead:= temp
    else
      temp^.next:= fHead;
      fHead:= temp;
  end;

function TMyStack.Take: TElement;
  var
    temp: TNodePointer;
  begin
    if not isEmpty then
    begin
      temp:= fHead;
      fHead:= fHead^.next;
      result:= temp^.value;
      Dispose(temp);
    end
    else
      result:= nil;
  end;

  function TMyStack.isEmpty: boolean;
  begin
    result:= fHead = nil;
  end;


procedure TForm2.ButtonUpdateClick(Sender: TObject);
const
  kMax=50;
var
  GetThread: array[0..kMax] of TGetThread;
  GetHandle: array[0..kMax] of THandle;
  url : string ;
  i, k , j: Integer ;
  eRec : integer ;
  pN, sm: integer;
  lsNode:TStringList ;
  XMLDoc: TNativeXml;
  Node,Sub : TXmlNode;
//  lsNode:TStringList ;
  Ret : DWORD;

begin

  pN:=StrToInt(Edit1.Text);

  url := 'http://www.gczn.nsk.su//?option=com_helloworld&template=gczn_vac&vacancy=';

  mySt:=TMyStack.Create;

  eRec:=0 ; // конец обработки записей
  i:=1;
 while (TRUE) do begin

  for k := 0 to (kMax-1) do begin

   GetThread[k]:=TGetThread.Create(true);
   GetThread[k].FreeOnTerminate:=true;
   GetThread[k].url:= url + IntToStr(i+k) ;
   GetThread[k].index:= i+k ;
   GetThread[k].Priority:=tpLower;
   GetThread[k].ThreadRefCount:=1;
   GetThread[k].OnTerminate := HandleTerminate;

   GetHandle[k]:=GetThread[k].Handle;

   //GetThread[k].Resume;
   GetThread[k].Start ;

  end;

  i:=i+kMax-1;
  Label1.Caption:=IntToStr(i); Label1.Refresh;
  if (pN>0) then if (i>=pN) then break ;
  i:=i+1;

  //while (ThreadRefCount>5) do begin
   sleep(1000);
   Application.ProcessMessages();
  //end;

end;

Application.ProcessMessages();
sleep(15000);
Application.ProcessMessages();

{  Lock.BeginRead;
  try
    //do reading stuff on List here
    if List.Count > 0 then
      Form2.Memo1.Lines.AddStrings(List);;
  finally
    Lock.EndRead;
  end;
}
{
while ( not mySt.isEmpty) do begin
   lsNode:= mySt.Take ;
   Form2.Memo1.Lines.AddStrings(lsNode);
   Form2.Memo1.Lines.Append('-------');
    j:=j+2;
  end;
 }
   // CriticalSection.Leave;

  XMLDoc:=TNativeXml.Create(nil);//создали документ
  XMLDoc.CreateName('Vacancies');//создали корневой узел
     //создаем дочерний узел
  Node := XMLDoc.Root.NodeNew('Vacancy');
  j:=0;
  while (j<List.Count) do begin
    if (0=CompareStr(List.Strings[j],'END')) then begin
	    j:=j+1;
	    Node := XMLDoc.Root.NodeNew('Vacancy');
    end ;
    Sub := Node.NodeNew(UTF8String(List.Strings[j]));
    Sub.ValueUnicode := List.Strings[j+1];
    j:=j+2;
  end;

  //задаем параметры документа
  //XMLDoc.WriteOnDefault:=false;
  XMLDoc.CommentString:='Вакансии www.gczn.nsk.su';
  //XMLDoc.ExternalEncoding := seUTF8;
  //XMLDoc.Charset := 'utf-8';
  XMLDoc.VersionString:='1.0';
  //XMLDoc.EolStyle:=esCRLF;
  XMLDoc.XmlFormat:= xfReadable;
  XMLDoc.SaveToFile('MyXML.xml');
  
  lsNode.Free;

end;

procedure TForm2.FormCreate(Sender: TObject);
begin
  Memo1.Text:='';
  Label1.Caption:='0';
  Edit1.Text:='0';
  CriticalSection:=TCriticalSection.Create;
  Lock := TMultiReadExclusiveWriteSynchronizer.Create;
  List := TStringList.Create;
  ThreadRefCount := 0;
end;

procedure TForm2.HandleTerminate(Sender: TObject);
begin
  Dec(ThreadRefCount);
end;

{ TGetThread }
procedure TGetThread.Sync;
var
 j:integer;
   Node,Sub : TXmlNode;
begin
  Form2.Memo1.Lines.AddStrings(ls);
  Form2.Memo1.Lines.Append('END');
  Application.ProcessMessages();

{  CriticalSection.Enter;

  lsNode.AddStrings(ls);

  Node := XML.Root.NodeNew('Vacancy');
  j:=0;
  while (j<ls.Count) do begin
    Sub := Node.NodeNew(UTF8String(ls.Strings[j]));
    Sub.ValueUnicode := ls.Strings[j+1];
    j:=j+2;
  end;

  CriticalSection.Leave;   }

end;

{ TGetThread }
procedure TGetThread.Execute;
var
  strGet , strDiv : string ;
  sS, sS0, sS1, sS2 : String ;
  r , r2 : TRegExpr;
   j:integer;
   Node,Sub : TXmlNode;
begin
  HTTP := TidHTTP.Create(nil);
  //HTTP.HandleRedirects := True;
  try
    strGet :=HTTP.Get(url);
  except on e : EIDHttpProtocolException do
     Begin if e.ErrorCode = 302 then
      begin
       try
        // получаем новый адрес - адрес перенаправления
       strGet :=HTTP.Get(HTTP.Response.Location);
       except on e:Exception do
        //ShowMessage(' Ошибка при получении нового адреса .'+e.Message);
		   //exit();
       end;
      end
     else {http 404, 501 и так далее}
       //ShowMessage(' Ошибка :'+e.Message);
     //exit();
  end;
   on e:Exception do
     //ShowMessage('Ошибка: ' + e.Message);
	 //exit();
   end;

  HTTP.Free;

  ls := TStringList.Create;

  ls.Add('ID');
  ls.Add(IntToStr(index));

  r := TRegExpr.Create;
  try
   // удаляем все комментарии
   r.Expression := '<!--div.*div-->|<b>|</b>|<small>|</small>|&nbsp;|class=|\"clear\"|\"full_vac\"|\"vac_general\"|\"vac_header\"|\"vac_trebovanie|vac_after_header\"|\"vac_podrobnee|vac_after_header\"|\"vac_predpriyatie|style=\"display:block;\"';
   r.ModifierI:=TRUE;  r.ModifierS:=TRUE;  r.ModifierG:=FALSE;
   strDiv:=r.Replace(strGet,'',FALSE);
   strGet:=strDiv;

   // обход по всем div
   strDiv:='';
   r.Expression := '<div.*/div>';
   if r.Exec(strGet) then
   REPEAT
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

     //Дата регистрации
     if (0 <> Pos('Дата регистрации', sS2)) then begin
      sS:=StringReplace(sS2, 'Дата регистрации', '',[rfReplaceAll, rfIgnoreCase]);
      ls.Add('Дата регистрации');
      ls.Add(Trim(sS));
      // (0 <> Pos('1970', sS)) then eRec :=1;
     end ;

     //№
     if (0 <> Pos('№', sS2)) then begin
      sS:=StringReplace(sS2, '№', '',[rfReplaceAll, rfIgnoreCase]);
      ls.Add('№');
      ls.Add(Trim(sS));
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
     if sS2<>'' then ls.Add(Trim(sS2));

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
     ls.Add(sS2);
    end ; // vac_param

   UNTIL not r.ExecNext;
  finally r.Free;
  end;

  CriticalSection.Enter;
  try
   //mySt.Add(ls);
   List.AddStrings(ls);
  finally
  CriticalSection.Leave;
  end;

{
  Lock.BeginWrite;
  try
    List.AddStrings(ls);
  finally
    Lock.EndWrite;
  end;
}
  //Synchronize(Sync);

  ls.Free;


end;


end.
