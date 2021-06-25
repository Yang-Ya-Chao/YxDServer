
(*******************************************************************************
                            FireDac���ӳ�
*******************************************************************************
����������� ����DAC���� ��̬����
ϵͳĬ�ϳ����� һ��Сʱ����δ�õ� TFDConnection ���� ϵͳ�Զ��ͷ�
ʹ������
��Uses SQLFirDACPoolUnit ��Ԫ
�ڳ����ʼ��ʱ(initialization)�������ӳ���
DAConfig := TDAConfig.Create('YxDServer.ini');
DACPool := TDACPool.Create(32);
�ڳ���ر�ʱ(finalization)�ͷ����ӳ���
DACPool.Free;
DAConfig.Free;
��������
try
  FDQuery.Connecttion:= DACPool.GetCon(DAConfig);
  FDQuery.Open;
finally
  DACPool.PutCon(FDQuery.Connecttion);
end;
QQ:2405414352
2021-3
�����Ż� �봫һ�� ��лл��
*********************************************************************************
����Դ�ԣ�����:��Ӧ��--SQLADOPoolUnit.pas
********************************************************************************)

unit SQLFirDACPoolUnit;

interface

uses
  Windows, SqlExpr, SysUtils, Classes, ExtCtrls, DateUtils, IniFiles, uEncry,
  Messages, Provider, FireDAC.Comp.Client, FireDAC.Phys.MSSQL,
  FireDAC.Phys.ODBCBase, FireDAC.DApt,FireDAC.Moni.FlatFile,FireDAC.Stan.Intf,
  FireDAC.Moni.Base,QLog;

type// ���ݿ�����
  TDBType = (Access, SqlServer, Oracle);
  //���ݿ����� DAC

type
  TDAConfig = class
  private
  //���ݿ�����
    ConnectionName: string; //������������
    ProviderName: string; //ͨ������
    DBServer: ansistring; //����Դ --���ݿ������IP
    DataBase: ansistring; //���ݿ����� //sql server����ʱ��Ҫ���ݿ�������--���ݿ�ʵ������
    OSAuthentication: Boolean; //�Ƿ���windows��֤
    UserName: ansistring; //���ݿ��û�
    PassWord: ansistring; //����
    AccessPassWord: string; //Access������Ҫ���ݿ�����
    Port: integer; //���ݿ�˿�
    BDEBUG:Boolean; //�Ƿ��¼sql���
    DriverName: string; //����
    HostName: string; //�����ַ
  //�˿�����
    TCPPort: Integer; //TCP�˿�
    HttpPort: Integer; //http �˿�
    LoginSrvUser: string; //��֤�м������¼�û�
    LoginSrvPassword: string; //��֤��¼ģ������
  public
    constructor Create(iniFile: string); overload;
    destructor Destroy; override;
  end;

type
  TDACon = class
  private
    FConnObj: TFDConnection; //���ݿ����Ӷ���
    FMDFF:TFDMoniFlatFileClientLink; //SQL��¼����
    FAStart: TDateTime; //���һ�λʱ��
    function GetUseFlag: Boolean;
    procedure SetUseFlag(value: Boolean);
    procedure FDMFFOutput(ASender: TFDMoniClientLinkBase; const AClassName,
      AObjName, AMessage: string);
  public
    constructor Create(DAConfig: TDAConfig); overload;
    destructor Destroy; override;
  //��ǰ�����Ƿ�ʹ��
    property UseFlag: boolean read GetUseFlag write SetUseFlag;
    property ConnObj: TFDConnection read FConnObj;
    property AStart: TDateTime read FAStart write FAStart;
  end;

type
  TDACPool = class
    procedure OnMyTimer(Sender: TObject); //����ѯ��
  private
    FSection: TRTLCriticalSection;
    FPoolNumber: Integer; //�ش�С
    FPollingInterval: Integer; //��ѯʱ�� �� �� Ϊ��λ
    FDACon: TDACon;
    FList: TList; //������������
    FTime: TTimer; //��Ҫ����ѯ
    procedure Enter;
    procedure Leave;
    function SameConfig(const Source: TDAConfig; Target: TDACon): Boolean;
    function GetConnectionCount: Integer;
  public
    constructor Create(const MaxNumBer: Integer; FreeMinutes: Integer = 60;
      TimerTime: Integer = 5000); overload;
    destructor Destroy; override;
  //�ӳ���ȡ�����õ����ӡ�
    function GetCon(const tmpConfig: TDAConfig): TFDConnection;
  //����������ӷŻ����ӳء�
    procedure PutCon(const DAConnection: TFDConnection);
  //�ͷų������δ�õ����ӣ��ɶ�ʱ������ɨ��ִ��
    procedure FreeConnection;
  //��ǰ����������.
    property ConnectionCount: Integer read GetConnectionCount;
  end;

var
  DACPool: TDACPool;
  DAConfig: TDAConfig;
  PoolNum: Integer = 32;

implementation
{ TDAConfig }

constructor TDAConfig.Create(iniFile: string);
var
  AINI: TIniFile;
begin
  try
    AINI := TIniFile.Create(iniFile);
    DBServer := AINI.ReadString('DB', 'Server', '');
    DataBase := AINI.ReadString('DB', 'DataBase', '');
    DBServer := DeCode(AINI.ReadString('DB', 'Server', ''));
    DataBase := DeCode(AINI.ReadString('DB', 'DataBase', ''));
    UserName := DeCode(AINI.ReadString('DB', 'UserName', ''));
    PassWord := DeCode(AINI.ReadString('DB', 'PassWord', ''));
    PoolNum := AINI.ReadInteger('YxDServer', 'Pools', 32);
    BDEBUG :=  AINI.ReadBool('YxDServer', 'SQLDEBUG', False);
  finally
    Freeandnil(AINI);
  end;

end;

destructor TDAConfig.Destroy;
begin
  inherited;
end;
{ tdacon }

procedure TDACon.FDMFFOutput(ASender: TFDMoniClientLinkBase;
  const AClassName, AObjName, AMessage: string);
begin
  PostLog(llDebug,AMessage);
end;

constructor TDACon.Create(DAConfig: TDAConfig);
var
  str: string;
begin
  str := 'DriverID=MSSQL;Server=' + DAConfig.DBServer + ';Database=' + DAConfig.DataBase
    + ';User_name=' + DAConfig.UserName + ';Password=' + DAConfig.PassWord +
    ';LoginTimeOut=3';
  FConnObj := TFDConnection.Create(nil);
  FMDFF := TFDMoniFlatFileClientLink.Create(nil);
  with FConnObj,FMDFF do
  begin
    //ConnectionTimeout:=18000;
    ConnectionString := str;
    //���ִ��sql���̶��ߣ��ȴ�ʱ����� ,����֮������������д��ᳬʱ�����Σ�
    //Params.add('ResourceOptions.CmdExecTimeout=3');
    //�����ѯֻ����50����������
    Params.add('FetchOptions.Mode=fmAll');
    //�������&���ַ��������ݿ�ʱ��ʧ
    Params.add('ResourceOptions.MacroCreate=False');
    Params.add('ResourceOptions.MacroExpand=False');
    //////////SQL��־����/////////
    Params.add('MonitorBy=FlatFile');
    Params.add('ConnectionIntf.Tracing=True');
    FileName :='';
    EventKinds := [ekcmdExecute];
    FileAppend := True;
    ShowTraces := False;
    OnOutput := nil;
    OnOutput := FDMFFOutput;
    ///////////////////////////
    try
      Connected := True;
      FileEncoding := ecANSI;
      Tracing := DAConfig.BDEBUG;
    except
      raise Exception.Create('���ݿ�����ʧ�ܣ��������ݿ����û����������ӣ�');
    end;
  end;
end;

destructor tdacon.Destroy;
begin
  FAStart := 0;
  if Assigned(FConnObj) then
  begin
    if FConnObj.Connected then
      FConnObj.Close;
    FreeAndnil(FConnObj);
    FreeAndnil(FMDFF);
  end;
  inherited;
end;

procedure tdacon.SetUseFlag(value: Boolean);
begin
  //False��ʾ���ã�True��ʾ��ʹ�á�
  if not value then
    FConnObj.Tag := 0
  else
  begin
    if FConnObj.Tag = 0 then
      FConnObj.Tag := 1; //����Ϊʹ�ñ�ʶ��
    FAStart := now; //��������ʱ�� ��
  end;
end;

function tdacon.GetUseFlag: Boolean;
begin
  Result := (FConnObj.Tag > 0); //Tag=0��ʾ���ã�Tag>0��ʾ��ʹ�á�
end;
{ TDACPool }

constructor TDACPool.Create(const MaxNumBer: Integer; FreeMinutes: Integer = 60;
  TimerTime: Integer = 5000);
begin
  InitializeCriticalSection(FSection);
  FPOOLNUMBER := MaxNumBer; //���óش�С
  FPollingInterval := FreeMinutes; // ���ӳ��� FPollingInterval ����û�õ� �Զ��������ӳ�
  FList := TList.Create;
  FTime := TTimer.Create(nil);
  FTime.Enabled := False;
  FTime.Interval := TimerTime; //5����һ��
  FTime.OnTimer := OnMyTimer;
  FTime.Enabled := True;
end;

destructor TDACPool.Destroy;
var
  i: integer;
begin
  FTime.OnTimer := nil;
  FTime.Free;
  for i := FList.Count - 1 downto 0 do
  begin
    try
      FDACon := TDAcon(FList.Items[i]);
      if Assigned(FDACon) then
        FreeAndNil(FDACon);
      FList.Delete(i);
    except
    end;
  end;
  FList.Free;
  DeleteCriticalSection(FSection);
  inherited;
end;

procedure TDACPool.Enter;
begin
  EnterCriticalSection(FSection);
  //System.TMonitor.Enter(self);
end;

procedure TDACPool.Leave;
begin
  LeaveCriticalSection(FSection);
 // System.TMonitor.Exit(self);
end;
//�����ַ������Ӳ��� ȡ����ǰ���ӳؿ����õ�tdaconnection

function TDACPool.GetCon(const tmpConfig: TDAConfig): TFDConnection;
var
  i: Integer;
  IsResult: Boolean; //��ʶ
  CurOutTime: Integer;
begin
  Result := nil;
  IsResult := False;
  CurOutTime := 0;
  Enter;
  try
    for i := 0 to FList.Count - 1 do
    begin
      FDACon := TDACon(FList.Items[i]);
      if not FDACon.UseFlag then //����
        if SameConfig(tmpConfig, FDACon) then //�ҵ�
        begin
          FDACon.UseFlag := True; //����Ѿ���������
          Result := FDACon.ConnObj;
          IsResult := True;
          Break; //�˳�ѭ��
        end;
    end; // end for
  finally
    Leave;
  end;
  if IsResult then
    Exit;
  //��δ�� �½�һ��
  Enter;
  try
    if FList.Count < FPOOLNUMBER then //��δ��
    begin
      FDACon := tdacon.Create(tmpConfig);
      FDACon.UseFlag := True;
      Result := FDACon.ConnObj;
      IsResult := True;
      FList.Add(FDACon); //����������
    end;
  finally
    Leave;
  end;
  if IsResult then
    Exit;
  //���� �ȴ� �Ⱥ��ͷ�
  while True do
  begin
    Enter;
    try
      for i := 0 to FList.Count - 1 do
      begin
        FDACon := tdacon(FList.Items[i]);
        if SameConfig(tmpConfig, FDACon) then //�ҵ�
          if not FDACon.UseFlag then //����
          begin
            FDACon.UseFlag := True; //����Ѿ���������
            Result := FDACon.ConnObj;
            IsResult := True;
            Break; //�˳�ѭ��
          end;
      end; // end for
      if IsResult then
        Break; //�ҵ��˳�
    finally
      Leave;
    end;
    //��������������ַ����ĳ��� �� һֱ�ȵ���ʱ
    if CurOutTime >= 5000 * 6 then //1����
    begin
      raise Exception.Create('���ӳ�ʱ!');
      Break;
    end;
    Sleep(500); //0.5����
    CurOutTime := CurOutTime + 500; //��ʱ���ó�60��
  end; //end while
end;

procedure TDACPool.PutCon(const DAConnection: TFDConnection);
var
  i: Integer;
begin
{
if not Assigned(DAConnection) then Exit;
try
Enter;
DAConnection.Tag := 0; //���Ӧ��Ҳ���� ��δ����...
finally
Leave;
end;
}
  Enter; //��������
  try
    for i := FList.Count - 1 downto 0 do
    begin
      FDACon := tdacon(FList.Items[i]);
      if FDACon.ConnObj = DAConnection then
      begin
        FDACon.UseFlag := False;
        Break;
      end;
    end;
  finally
    Leave;
  end;
end;

procedure TDACPool.FreeConnection;
var
  i: Integer;

  function MyMinutesBetween(const ANow, AThen: TDateTime): Integer;
  begin
    Result := Round(MinuteSpan(ANow, AThen));
  end;

begin
  Enter;
  try
    for i := FList.Count - 1 downto 0 do
    begin
      FDACon := tdacon(FList.Items[i]);
      if MyMinutesBetween(Now, FDACon.AStart) >= FPollingInterval then //�ͷų�����ò��õ�DAC
      begin
        FreeAndNil(FDACon);
        FList.Delete(i);
      end;
    end;
  finally
    Leave;
  end;
end;

procedure TDACPool.OnMyTimer(Sender: TObject);
begin
  FreeConnection;
end;

function TDACPool.SameConfig(const Source: TDAConfig; Target: TDACon): Boolean;
begin
//���ǵ�֧�ֶ����ݿ����ӣ���Ҫ�����������µ�Ч�����ж�.����ǵ�һ���ݿ⣬�ɺ��Ա����̡�
{ Result := False;
if not Assigned(Source) then Exit;
if not Assigned(Target) then Exit;
Result := SameStr(LowerCase(Source.ConnectionName),LowerCase(Target.ConnObj.Name));
Result := Result and SameStr(LowerCase(Source.DriverName),LowerCase(Target.ConnObj.Provider));
Result := Result and SameStr(LowerCase(Source.HostName),LowerCase(Target.ConnObj.Properties['Data Source'].Value));
Result := Result and SameStr(LowerCase(Source.DataBase),LowerCase(Target.ConnObj.Properties['Initial Catalog'].Value));
Result := Result and SameStr(LowerCase(Source.UserName),LowerCase(Target.ConnObj.Properties['User ID'].Value));
Result := Result and SameStr(LowerCase(Source.PassWord),LowerCase(Target.ConnObj.Properties['Password'].Value));
//Result := Result and (Source.OSAuthentication = Target.ConnObj.OSAuthentication);
}
end;

function TDACPool.GetConnectionCount: Integer;
begin
  Result := FList.Count;
end;
//��ʼ��ʱ��������

initialization
  DAConfig := TDAConfig.Create(ExtractFileDir(ParamStr(0)) + '\YxDServer.ini');
  DACPool := TDACPool.Create(PoolNum);

finalization
  if Assigned(DACPool) then
    DACPool.Free;
  if Assigned(DAConfig) then
    DAConfig.Free;

end.

