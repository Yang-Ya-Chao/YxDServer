{ Invokable implementation File for TTest which implements ITest }

unit SoapImpl;

interface

uses
  InvokeRegistry, Types, XSBuiltIns, SoapIntf, Winapi.Windows, Controls,
  SynCommons,QLog;

type

  { TTest }
  TWSYXDSVR = class(TInvokableClass, IWSYXDSVR)
  public
    function HelloWorld: string;
  end;

implementation

uses
  uDataYxDserver, Winapi.Messages, Forms, Soap.EncdDecd, System.SysUtils;

const
  Success_Result = '<Result><Code>1</Code><Info>³É¹¦</Info></Result>';
  Success_Info = '<Result><Code>1</Code><Info>@Info@</Info></Result>';
  Fail_Result = '<Result><Code>0</Code><Info>@Info@</Info></Result>';
  WM_HTTPINFO = WM_USER + 203;

function TWSYXDSVR.HelloWorld: string;
var
  Af: TYxDSvr;
  Log: string;
begin
  Result := Fail_Result;
  try
    try
      Af := TYxDSvr.Create(nil);
      try
        if not Af.HelloWorld then
        begin
          Result := stringreplace(Fail_Result, '@Info@', Af.FERROR, []);
          Exit;
        end;
        Result := stringreplace(Success_Info, '@Info@', Af.FRet, []);
      finally
        freeandnil(Af);
      end;
    except
      on e: exception do
      begin
        Result := stringreplace(Fail_Result, '@Info@', e.message, []);
        Exit;
      end;
    end;
  finally
    Log := Log + #13#10 + Result;
    if POS('<Code>0</Code>', Log) > 0 then
    begin
      PostLog(llError,Log);
      PostMessage(Application.MainForm.Handle, WM_HTTPINFO, 0, 2);
    end
    else
      PostLog(llMessage,Log);
  end;
end;


initialization

{ Invokable classes must be registered }
  InvRegistry.RegisterInvokableClass(TWSYXDSVR);

end.

