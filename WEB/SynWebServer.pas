{ *************************************************************************** }
{  SynWebReqRes.pas is the 3rd file of SynBroker Project                      }
{  by c5soft@189.cn  Version 0.9.0.0  2018-5-27                               }
{ *************************************************************************** }

unit SynWebServer;

interface

uses
  SysUtils, Classes, IniFiles, HTTPApp, Contnrs, WebReq, SynCommons, SynCrtSock,
  SynWebEnv, msxml, Vcl.ExtCtrls, QLog;
type
  TSynWebRequestHandler = class(TWebRequestHandler);

  TSynWebServer = class
  private
    FOwner: TObject;
    FIniFile: TIniFile;
    FActive, FHttp,FHttpS: Boolean;
    FMaxNum: Integer;
    FRoot, FPort: string;
    FHttpServer: THttpApiServer;
    FReqHandler: TWebRequestHandler;
    FTimer: TTimer; //主要做轮询
    function Process(AContext: THttpServerRequest): cardinal;
    function DoCommandGet(AContext: THttpServerRequest): cardinal;
    function WebBrokerDispatch(const AEnv: TSynWebEnv): Boolean;
    //1秒检查一次活动中的线程数
    procedure TimerExecute;
    //发送到主界面展示活动的线程数
    procedure OnMyTimer(Sender: TObject);
  public
    property Active: Boolean read FActive;
    property Port: string read FPort;
    constructor Create(AOwner: TComponent = nil);
    destructor Destroy; override;
    function Execute(InValue: string; out OutValue: string): Boolean;
  end;

  TSynHTTPWebBrokerBridge = TSynWebServer;

implementation

uses
  SynZip, SynWebReqRes, uDataYxDserver, System.Variants, Winapi.ActiveX,
  Winapi.Windows, Forms, Winapi.Messages, uHtml;

var
  RequestHandler: TWebRequestHandler = nil;

const
  Success_Result = '<Result><Code>1</Code><Info>成功</Info></Result>';
  Success_Info = '<Result><Code>1</Code><Info>@Info@</Info></Result>';
  Fail_Result = '<Result><Code>0</Code><Info>@Info@</Info></Result>';
  WM_HTTPINFO = WM_USER + 203;
  WM_HTTPCOUNT = WM_USER + 204;

function GetRequestHandler: TWebRequestHandler;
begin
  if RequestHandler = nil then
    RequestHandler := TSynWebRequestHandler.Create(nil);
  Result := RequestHandler;
end;

{ TSynWebServer }

constructor TSynWebServer.Create(AOwner: TComponent);
begin
  inherited Create;
  try
    FActive := False;
    FHttp := False;
    FHttpS := False;
    FOwner := AOwner;
    if (FOwner <> nil) and (FOwner.InheritsFrom(TWebRequestHandler)) then
      FReqHandler := TWebRequestHandler(FOwner)
    else
      FReqHandler := GetRequestHandler;
    FIniFile := TIniFile.Create(ChangeFileExt(ParamStr(0), '.ini'));
    FRoot := FIniFile.ReadString('YxDServer', 'Root', '');
    if ParamStr(1) <> '' then
      FPort := ParamStr(1)
    else
      FPort := FIniFile.ReadString('YxDServer', 'Port', '8080');
    FHttp := FIniFile.ReadBool('YxDServer', 'HttpType', False);
    FMaxNum := FIniFile.ReadInteger('YxDServer', 'Pools', 32);
    FHttpS := FIniFile.ReadBool('YxDServer', 'Https', False);
    if FHttpS then  FPort := '443';
    FReqHandler.MaxConnections := FMaxNum;
    FHttpServer := THttpApiServer.Create(False);
    FHttpServer.AddUrl(StringTOUTF8(FRoot), StringTOUTF8(FPort), False, '+', true);
    FHttpServer.RegisterCompress(CompressDeflate);
    // our server will deflate html :)
    if FHttp then
      FHttpServer.OnRequest := DoCommandGet
    else
      FHttpServer.OnRequest := Process;
    FHttpServer.Clone(FMaxNum - 1); // will use a thread pool of 32 threads in total
    FActive := true;
    PostMessage(Application.MainForm.Handle, WM_HTTPCOUNT, 0, FMaxNum);
    TimerExecute;
  finally
    FreeAndNil(FIniFile);
  end;
end;

destructor TSynWebServer.Destroy;
begin
  FHttpServer.RemoveUrl(StringTOUTF8(FRoot), StringTOUTF8(FPort), False, '+');
  FreeAndNil(FHttpServer);
  FreeAndNil(FTimer);
  inherited;
end;

//WEBSERVICE服务

function TSynWebServer.Process(AContext: THttpServerRequest): cardinal;
var
  FEnv: TSynWebEnv;
begin
  try
    PostMessage(Application.MainForm.Handle, WM_HTTPINFO, 0, 0);
    FEnv := TSynWebEnv.Create(AContext);
    try
      if WebBrokerDispatch(FEnv) then
        Result := 200
      else
        Result := 404;
    finally
      Freeandnil(FEnv);
    end;
  except
    on e: Exception do
    begin
      AContext.OutContent := StringTOUTF8('<HTML><BODY>' +
        '<H1>服务器运行出错</H1>' + '<P>' + UTF8ToString(AContext.Method + ' ' +
        AContext.URL) + '</P>' + '<P>' + e.Message + '</P>' + '</BODY></HTML>');
      //AContext.OutContent := stringreplace(Fail_Result,'ErrorInfo',AContext.OutContent,[]);
      AContext.OutContentType := HTML_CONTENT_TYPE;
      Result := 500;
      PostMessage(Application.MainForm.Handle, WM_HTTPINFO, 0, 2);
    end;
  end;
end;

//http服务

function TSynWebServer.DoCommandGet(AContext: THttpServerRequest): cardinal;
var
  aBuff: string;
  OutValue: string;
  Log: string;
begin
  PostMessage(Application.MainForm.Handle, WM_HTTPINFO, 0, 0);
  try
    OutValue := '';
    if AContext.URL <> '/IWSYXDSVR' then
    begin
      OutValue := stringreplace(cstHTMLBegin + '<p>404！ HTTP NOT FOUND！</p>' +
        cstHTMLEnd, 'text-align:Left;', 'text-align:Center;', []);
      Result := 404;
      Exit;
    end;
    aBuff := UTF8ToString(AContext.InContent);
    if aBuff = '' then
    begin
      OutValue := stringreplace(cstHTMLBegin +
        '<p>Copy That！Please Send Detailed Message To Deal！</p>' + cstHTMLEnd,
        'text-align:Left;', 'text-align:Center;', []);

      Result := 200;
      Exit;
    end;
    try
      Result := 200;
      if not Execute(aBuff, OutValue) then
      begin
        OutValue := stringreplace(Fail_Result, '@Info@', OutValue, []);
        Exit;
      end;
      if OutValue <> '' then
        OutValue := stringreplace(Success_Info, '@Info@', OutValue, [])
      else
        OutValue := Success_Result;
    except
      on e: Exception do
      begin
        OutValue := '服务器运行出错:' + UTF8ToString(AContext.Method + ' ' + AContext.URL)
          + '：' + e.Message;
        OutValue := stringreplace(Fail_Result, '@Info@', OutValue, []);
        Result := 500;
        PostMessage(Application.MainForm.Handle, WM_HTTPINFO, 0, 2);
      end;
    end;
  finally
    Log := aBuff + #13#10 + OutValue;
    if POS('<Code>0</Code>', Log) > 0 then
    begin
      PostLog(llError, Log);
      PostMessage(Application.MainForm.Handle, WM_HTTPINFO, 0, 2);
    end
    else
      PostLog(llMessage, Log);
    AContext.OutContentType := HTML_CONTENT_TYPE;
    AContext.OutContent := (StringTOUTF8(OutValue));
  end;
end;

function TSynWebServer.WebBrokerDispatch(const AEnv: TSynWebEnv): Boolean;
var
  HTTPRequest: TSynWebRequest;
  HTTPResponse: TSynWebResponse;
begin
  HTTPRequest := TSynWebRequest.Create(AEnv);
  try
    HTTPResponse := TSynWebResponse.Create(HTTPRequest);
    try
      Result := TSynWebRequestHandler(FReqHandler).HandleRequest(HTTPRequest,
        HTTPResponse);
    finally
      freeandnil(HTTPResponse);
    end;
  finally
    freeandnil(HTTPRequest);
  end;
end;

function TSynWebServer.Execute(InValue: string; out OutValue: string): Boolean;
var
  YxSvr: TYxDSvr;
begin
  Result := False;
  OutValue := '';
  try
    YxSvr := TYxDSvr.Create(nil);
    try
      if not YxSvr.HelloWorld then
        Exit;
      OutValue := YxSvr.FRet;
    finally
      freeandnil(YxSvr);
    end;
  except
    on e: exception do
    begin
      OutValue := e.message;
      Exit;
    end;
  end;
  Result := True;
end;

procedure TSynWebServer.OnMyTimer(Sender: TObject);//做轮询用
begin
  PostMessage(Application.MainForm.Handle, WM_HTTPCOUNT, 1, FReqHandler.activeCount);
end;

procedure TSynWebServer.TimerExecute;
begin
  FTimer := TTimer.Create(nil);
  FTimer.Enabled := False;
  FTimer.Interval := 1000;
  FTimer.OnTimer := OnMyTimer;
  FTimer.Enabled := True;
end;

initialization
  WebReq.WebRequestHandlerProc := GetRequestHandler;


finalization
  if RequestHandler <> nil then
    FreeAndNil(RequestHandler);

end.

