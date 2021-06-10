program YxDServer;

uses
  Forms,
  Winapi.Windows,
  System.SysUtils,
  uFrmMain in 'uFrmMain.pas' {MainForm},
  SoapImpl in 'WEB\SoapImpl.pas',
  SoapIntf in 'WEB\SoapIntf.pas',
  SynWebEnv in 'WEB\SynWebEnv.pas',
  SynWebReqRes in 'WEB\SynWebReqRes.pas',
  SynWebServer in 'WEB\SynWebServer.pas',
  uWebModule in 'WEB\uWebModule.pas' {WebModule1: TWebModule},
  uHtml in 'WEB\uHtml.pas',
  uEncry in '公用\uEncry.pas',
  ElAES in '公用\ElAES.pas',
  UpubFun in '公用\UpubFun.pas',
  SQLFirDACPoolUnit in '公用\SQLFirDACPoolUnit.pas',
  uFrmSQLConnect in '配置\uFrmSQLConnect.pas' {FrmSQLConnect},
  uFrmSvrConfig in '配置\uFrmSvrConfig.pas' {FrmSvrConfig},
  uFrmMQTTConfig in '配置\uFrmMQTTConfig.pas' {FrmMQTTConfig},
  MQTT in 'MQTT\MQTT.pas',
  uFrmMQTTClient in 'MQTT\uFrmMQTTClient.pas' {FrmMQTTClient},
  uDataYxDserver in '服务\uDataYxDserver.pas';

{$R *.res}
var
  hMutex: HWND;
  Ret: Integer;

begin
  Application.Initialize;
  //初始化程序中使用的时间格式
  formatsettings.LongDateFormat := 'yyyy-MM-dd';
  formatsettings.ShortDateFormat := 'yyyy-MM-dd';
  formatsettings.LongTimeFormat := 'HH:nn:ss';
  formatsettings.ShortTimeFormat := 'HH:nn:ss';
  formatsettings.DateSeparator := '-';
  formatsettings.TimeSeparator := ':';

  Application.Title := 'YxDSvr应用服务器';
  if ParamStr(1) = '' then
  begin
    hMutex := CreateMutex(nil, False, 'YxDServer');
    Ret := GetLastError;
    ReleaseMutex(hMutex);
    if Ret = ERROR_ALREADY_EXISTS then
      Exit;
  end;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;

end.

