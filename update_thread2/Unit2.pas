unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP,
  StdCtrls, OleCtrls, RegExpr, NativeXml,SyncObjs,
  ExtCtrls,
    OtlCommon,
  OtlCollections,
  OtlParallel;

type
  TForm2 = class(TForm)
    ButtonUpdate: TButton;
    Memo1: TMemo;
    Label1: TLabel;
    Edit1: TEdit;
    Label2: TLabel;
    IdHTTP1: TIdHTTP;
    procedure ButtonUpdateClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;
  CriticalSection: TCriticalSection;

implementation

{$R *.dfm}


function HttpGet(url: string; var ls : TStringList): boolean;
  // retrieve page contents from the url; return False if page is not accessible
var
  HTTP: TIdHTTP;
  strGet , strDiv : string ;
  sS, sS0, sS1, sS2 : String ;
  r , r2 , r0 : TRegExpr;
  index , j :integer;
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
        Result:=FALSE ;
       end;
      end
     else Result:=FALSE ; {http 404, 501 и так далее}
  end;
   on e:Exception do
     Result:=FALSE ;
   end;

  HTTP.Free;

  if (Result=FALSE) then exit ;

  ls := TStringList.Create;

  index:=0;

  r0 := TRegExpr.Create;
  try
   r0.Expression := '[0-9]+';
   r0.ModifierI:=TRUE;   r0.ModifierS:=TRUE;   r0.ModifierG:=FALSE;
   if r0.Exec(url) then
    REPEAT
          index := StrToInt(r0.Match [0]);
    UNTIL not r2.ExecNext;
  finally r0.Free; end ;

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

  Result:=True;
end;

procedure Retriever(const input: TOmniValue; var output: TOmniValue);
var
  pageContents: TStringList;
begin
  if HttpGet(input.AsString, pageContents) then
    output := pageContents;
end;

procedure Inserter(const input, output: IOmniBlockingCollection);
var
  page   : TOmniValue;
  pageObj: TStringList;
  XMLDoc: TNativeXml;
  Node,Sub : TXmlNode;

begin
  // connect to database

  XMLDoc:=TNativeXml.Create(nil);//создали документ
  XMLDoc.CreateName('Vacancies');//создали корневой узел

  for page in input do begin
    pageObj := page;
    // insert pageObj into database
    FreeAndNil(pageObj);
  end;
  // close database connection

  //задаем параметры документа
  //XMLDoc.WriteOnDefault:=false;
  XMLDoc.CommentString:='Вакансии www.gczn.nsk.su';
  //XMLDoc.ExternalEncoding := seUTF8;
  //XMLDoc.Charset := 'utf-8';
  XMLDoc.VersionString:='1.0';
  //XMLDoc.EolStyle:=esCRLF;
  XMLDoc.XmlFormat:= xfReadable;
  XMLDoc.SaveToFile('MyXML.xml');

end;

procedure ParallelWebRetriever;
var
  pipeline: IOmniPipeline;
  s       : string;
  url     : string;
  i       : Integer;
begin
  // set up pipeline
  pipeline := Parallel.Pipeline
    .Stage(Retriever).NumTasks(Environment.Process.Affinity.Count * 2)
    .Stage(Inserter)
    .Run;
  // insert URLs to be retrieved
  url := 'http://www.gczn.nsk.su//?option=com_helloworld&template=gczn_vac&vacancy=';

  for i:=0 to 8000 do begin
    s:= url + IntToStr(i);
    pipeline.Input.Add(s);
  end;

  pipeline.Input.CompleteAdding;
  // wait for pipeline to complete
  pipeline.WaitFor(INFINITE);
end;


procedure TForm2.ButtonUpdateClick(Sender: TObject);
var
  i, k , j: Integer ;
  eRec : integer ;
  pN : integer;
  XMLDoc: TNativeXml;
  Node,Sub : TXmlNode;
begin

  pN:=StrToInt(Edit1.Text);

  ParallelWebRetriever;

  //создаем дочерний узел
  {Node := XMLDoc.Root.NodeNew('Vacancy');
  j:=0;
  while (j<lsNode.Count) do begin
    if (0=CompareStr(lsNode.Strings[j],'END')) then begin
	    j:=j+1;
	    Node := XMLDoc.Root.NodeNew('Vacancy');
    end ;
    Sub := Node.NodeNew(UTF8String(lsNode.Strings[j]));
    Sub.ValueUnicode := lsNode.Strings[j+1];
    j:=j+2;
  end; }


  
end;

procedure TForm2.FormCreate(Sender: TObject);
begin
  Memo1.Text:='';
  Label1.Caption:='0';
  Edit1.Text:='0';
  CriticalSection:=TCriticalSection.Create;
end;

end.
