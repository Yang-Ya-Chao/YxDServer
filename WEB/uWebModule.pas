unit uWebModule;

interface

uses SysUtils, Classes, HTTPApp, InvokeRegistry, WSDLIntf, TypInfo, WebServExp,
  WSDLBind, XMLSchema, WSDLPub, SOAPPasInv, SOAPHTTPPasInv, SOAPHTTPDisp,
  WebBrokerSOAP,WebReq,uHtml;

type
  TWebModule1 = class(TWebModule)
    HTTPSoapDispatcher1: THTTPSoapDispatcher;
    HTTPSoapPascalInvoker1: THTTPSoapPascalInvoker;
    WSDLHTMLPublish1: TWSDLHTMLPublish;
    procedure WebModule1WebActionItemDefaultAction(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
    procedure WebModule1WebActionItemPostAction(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
  private
    function RequestInfo(const Request: TWebRequest): string;
  public
    { Public declarations }
  end;

var
  WebModule1: TWebModule1;
  WebModuleClass: TComponentClass = TWebModule1;

implementation
{$R *.dfm}



function TWebModule1.RequestInfo(const Request: TWebRequest): string;
begin
  Result :=
    '<p>'
    +'Service: YxDServer<br>'
    +'Date: '+string(FormatDateTime('YYYY-MM-DD HH:NN:SS',Request.Date))+'<br>'
    +'Host: ' + string(Request.Host) + '<br>'
    +'Client IP: ' + string(Request.RemoteAddr) + '<br>'
    +'Method: ' + string(Request.Method) + '<br>'
    +'URL: '+ string(Request.URL)
    +'</p>';
end;

procedure TWebModule1.WebModule1WebActionItemDefaultAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
var
    cName, cPhone: string;
begin
  //cName := Request.QueryFields.Values['name'];
  //cPhone := Request.QueryFields.Values['phone'];
  Response.ContentType := 'text/html; charset=utf8'; // 让汉字正确显示
  Response.Content := cstHTMLBegin + RequestInfo(Request) + cstHTMLEnd;
 // WSDLHTMLPublish1.ServiceInfo(Sender, Request, Response, Handled);
end;

procedure TWebModule1.WebModule1WebActionItemPostAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
begin
  Response.ContentType := 'text/html; charset=utf8'; // 让汉字正确显示
  Response.Content := cstHTMLBegin + RequestInfo(Request) +
    '<a href="/?' + Request.Content + '">返回</a>' +
    cstHTMLEnd;
end;

initialization
  if WebRequestHandler <> nil then
    WebRequestHandler.WebModuleClass := WebModuleClass;
end.
