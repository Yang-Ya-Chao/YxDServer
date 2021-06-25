
(*******************************************************************************
                            FireDac连接池
*******************************************************************************
池满的情况下 池子DAC连接 动态创建
系统默认池子中 一个小时以上未用的 TFDConnection 连接 系统自动释放
使用如下
先Uses SQLFirDACPoolUnit 单元
在程序初始化时(initialization)创建连接池类
DAConfig := TDAConfig.Create('YxDServer.ini');
DACPool := TDACPool.Create(32);
在程序关闭时(finalization)释放连接池类
DACPool.Free;
DAConfig.Free;
调用如下
try
  FDQuery.Connecttion:= DACPool.GetCon(DAConfig);
  FDQuery.Open;
finally
  DACPool.PutCon(FDQuery.Connecttion);
end;
QQ:2405414352
2021-3
如有优化 请传一份 。谢谢！
*********************************************************************************
代码源自：作者:何应祖--SQLADOPoolUnit.pas
********************************************************************************)

unit SQLFirDACPoolUnit;

interface

uses
  Windows, SqlExpr, SysUtils, Classes, ExtCtrls, DateUtils, IniFiles, uEncry,
  Messages, Provider, FireDAC.Comp.Client, FireDAC.Phys.MSSQL,
  FireDAC.Phys.ODBCBase, FireDAC.DApt,FireDAC.Moni.FlatFile,FireDAC.Stan.Intf,
  FireDAC.Moni.Base,QLog;

type// 数据库类型
  TDBType = (Access, SqlServer, Oracle);
  //数据库配置 DAC

type
  TDAConfig = class
  private
  //数据库配置
    ConnectionName: string; //连接驱动名字
    ProviderName: string; //通用驱动
    DBServer: ansistring; //数据源 --数据库服务器IP
    DataBase: ansistring; //数据库名字 //sql server连接时需要数据库名参数--数据库实例名称
    OSAuthentication: Boolean; //是否是windows验证
    UserName: ansistring; //数据库用户
    PassWord: ansistring; //密码
    AccessPassWord: string; //Access可能需要数据库密码
    Port: integer; //数据库端口
    BDEBUG:Boolean; //是否记录sql语句
    DriverName: string; //驱动
    HostName: string; //服务地址
  //端口配置
    TCPPort: Integer; //TCP端口
    HttpPort: Integer; //http 端口
    LoginSrvUser: string; //验证中间层服务登录用户
    LoginSrvPassword: string; //验证登录模块密码
  public
    constructor Create(iniFile: string); overload;
    destructor Destroy; override;
  end;

type
  TDACon = class
  private
    FConnObj: TFDConnection; //数据库连接对象
    FMDFF:TFDMoniFlatFileClientLink; //SQL记录对象
    FAStart: TDateTime; //最后一次活动时间
    function GetUseFlag: Boolean;
    procedure SetUseFlag(value: Boolean);
    procedure FDMFFOutput(ASender: TFDMoniClientLinkBase; const AClassName,
      AObjName, AMessage: string);
  public
    constructor Create(DAConfig: TDAConfig); overload;
    destructor Destroy; override;
  //当前对象是否被使用
    property UseFlag: boolean read GetUseFlag write SetUseFlag;
    property ConnObj: TFDConnection read FConnObj;
    property AStart: TDateTime read FAStart write FAStart;
  end;

type
  TDACPool = class
    procedure OnMyTimer(Sender: TObject); //做轮询用
  private
    FSection: TRTLCriticalSection;
    FPoolNumber: Integer; //池大小
    FPollingInterval: Integer; //轮询时间 以 分 为单位
    FDACon: TDACon;
    FList: TList; //用来管理连接
    FTime: TTimer; //主要做轮询
    procedure Enter;
    procedure Leave;
    function SameConfig(const Source: TDAConfig; Target: TDACon): Boolean;
    function GetConnectionCount: Integer;
  public
    constructor Create(const MaxNumBer: Integer; FreeMinutes: Integer = 60;
      TimerTime: Integer = 5000); overload;
    destructor Destroy; override;
  //从池中取出可用的连接。
    function GetCon(const tmpConfig: TDAConfig): TFDConnection;
  //把用完的连接放回连接池。
    procedure PutCon(const DAConnection: TFDConnection);
  //释放池中许久未用的连接，由定时器定期扫描执行
    procedure FreeConnection;
  //当前池中连接数.
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
    //解决执行sql过程断线，等待时间过程 ,加上之后，数据量过大写入会超时！屏蔽！
    //Params.add('ResourceOptions.CmdExecTimeout=3');
    //解决查询只返回50条数据问题
    Params.add('FetchOptions.Mode=fmAll');
    //解决！，&等字符插入数据库时丢失
    Params.add('ResourceOptions.MacroCreate=False');
    Params.add('ResourceOptions.MacroExpand=False');
    //////////SQL日志设置/////////
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
      raise Exception.Create('数据库连接失败！请检查数据库配置或者网络链接！');
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
  //False表示闲置，True表示在使用。
  if not value then
    FConnObj.Tag := 0
  else
  begin
    if FConnObj.Tag = 0 then
      FConnObj.Tag := 1; //设置为使用标识。
    FAStart := now; //设置启用时间 。
  end;
end;

function tdacon.GetUseFlag: Boolean;
begin
  Result := (FConnObj.Tag > 0); //Tag=0表示闲置，Tag>0表示在使用。
end;
{ TDACPool }

constructor TDACPool.Create(const MaxNumBer: Integer; FreeMinutes: Integer = 60;
  TimerTime: Integer = 5000);
begin
  InitializeCriticalSection(FSection);
  FPOOLNUMBER := MaxNumBer; //设置池大小
  FPollingInterval := FreeMinutes; // 连接池中 FPollingInterval 以上没用的 自动回收连接池
  FList := TList.Create;
  FTime := TTimer.Create(nil);
  FTime.Enabled := False;
  FTime.Interval := TimerTime; //5秒检查一次
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
//根据字符串连接参数 取出当前连接池可以用的tdaconnection

function TDACPool.GetCon(const tmpConfig: TDAConfig): TFDConnection;
var
  i: Integer;
  IsResult: Boolean; //标识
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
      if not FDACon.UseFlag then //可用
        if SameConfig(tmpConfig, FDACon) then //找到
        begin
          FDACon.UseFlag := True; //标记已经分配用了
          Result := FDACon.ConnObj;
          IsResult := True;
          Break; //退出循环
        end;
    end; // end for
  finally
    Leave;
  end;
  if IsResult then
    Exit;
  //池未满 新建一个
  Enter;
  try
    if FList.Count < FPOOLNUMBER then //池未满
    begin
      FDACon := tdacon.Create(tmpConfig);
      FDACon.UseFlag := True;
      Result := FDACon.ConnObj;
      IsResult := True;
      FList.Add(FDACon); //加入管理队列
    end;
  finally
    Leave;
  end;
  if IsResult then
    Exit;
  //池满 等待 等候释放
  while True do
  begin
    Enter;
    try
      for i := 0 to FList.Count - 1 do
      begin
        FDACon := tdacon(FList.Items[i]);
        if SameConfig(tmpConfig, FDACon) then //找到
          if not FDACon.UseFlag then //可用
          begin
            FDACon.UseFlag := True; //标记已经分配用了
            Result := FDACon.ConnObj;
            IsResult := True;
            Break; //退出循环
          end;
      end; // end for
      if IsResult then
        Break; //找到退出
    finally
      Leave;
    end;
    //如果不存在这种字符串的池子 则 一直等到超时
    if CurOutTime >= 5000 * 6 then //1分钟
    begin
      raise Exception.Create('连接超时!');
      Break;
    end;
    Sleep(500); //0.5秒钟
    CurOutTime := CurOutTime + 500; //超时设置成60秒
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
DAConnection.Tag := 0; //如此应该也可以 ，未测试...
finally
Leave;
end;
}
  Enter; //并发控制
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
      if MyMinutesBetween(Now, FDACon.AStart) >= FPollingInterval then //释放池子许久不用的DAC
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
//考虑到支持多数据库连接，需要本方法做如下等效连接判断.如果是单一数据库，可忽略本过程。
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
//初始化时创建对象

initialization
  DAConfig := TDAConfig.Create(ExtractFileDir(ParamStr(0)) + '\YxDServer.ini');
  DACPool := TDACPool.Create(PoolNum);

finalization
  if Assigned(DACPool) then
    DACPool.Free;
  if Assigned(DAConfig) then
    DAConfig.Free;

end.

