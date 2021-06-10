/////本单元仅提供主线程调用，保证线程完全
unit UpubFun;

interface

uses
  System.IniFiles, System.SysUtils, uEncry, System.Classes, System.Win.ComObj,
  Winapi.ShellAPI, Windows, Messages, System.DateUtils, System.Variants,
  Registry, Vcl.Forms, TLhelp32, PsAPI, SyncObjs;

type
  TCPUID = array[1..4] of LongInt;

type
  TProcessCpuUsage = record
  private
    FLastUsed, FLastTime: Int64;
    FCpuCount: Integer;
  public
    class function Create: TProcessCpuUsage; static;
    function Current: Single;
  end;
    //自注册Win自启动

procedure SelfAutoRun(R: Boolean);
    //检测CPU序列号

function CheckCPUID: Boolean;
    //注册CPU序列号

function RegisterCPUID: Boolean;
    //获取网络时间

function GetTime: TDateTime;
   //获取CPU使用率

function GetCPURate: Single;
  //获取内存使用

function CurrentMemoryUsage: Cardinal;
  //获取线程数

function GetProcessThreadCount: integer;
  //获取程序运行时间

function GetRunTimeInfo: string;
  //请求数格式化

function SetHTTPCount(x: integer): string;

var
  StartRunTime: Int64 = 0;
  { TProcessCpuUsage }
  ProcessCpuUsage: TProcessCpuUsage = (
    FLastUsed: 0;
    FLastTime: 0;
    FCpuCount: 0
  );

implementation



class function TProcessCpuUsage.Create: TProcessCpuUsage;
begin
  Result.FLastTime := 0;
  Result.FLastUsed := 0;
  Result.FCpuCount := 0;
end;

function TProcessCpuUsage.Current: Single;
var
  Usage, ACurTime: UInt64;
  CreateTime, ExitTime, IdleTime, UserTime, KernelTime: TFileTime;

  function FileTimeToI64(const ATime: TFileTime): Int64;
  begin
    Result := (Int64(ATime.dwHighDateTime) shl 32) + ATime.dwLowDateTime;
  end;

  function GetCPUCount: Integer;
  var
    SysInfo: TSystemInfo;
  begin
    GetSystemInfo(SysInfo);
    Result := SysInfo.dwNumberOfProcessors;
  end;

begin
  Result := 0;
  if GetProcessTimes(GetCurrentProcess, CreateTime, ExitTime, KernelTime, UserTime) then
  begin
    ACurTime := GetTickCount;
    Usage := FileTimeToI64(UserTime) + FileTimeToI64(KernelTime);
    if FLastTime <> 0 then
      Result := (Usage - FLastUsed) / (ACurTime - FLastTime) / FCpuCount / 100
    else
      FCpuCount := GetCpuCount;
    FLastUsed := Usage;
    FLastTime := ACurTime;
  end;
end;

function GetCPURate: Single;
begin
  result := ProcessCpuUsage.Current;
end;

function SetHTTPCount(x: integer): string;
var
  a, b, c: Integer;
begin

  a := x div 10000;
  c := x mod 10000;
  b := a div 10000;
  if a > 0 then
    result := IntToStr(a) + 'W' + inttostr(c)
  else
    result := IntToStr(c);
  if b > 0 then
  begin
    a := x div 100000000;
    c := x mod 100000000;
    b := c div 10000;
    c := b mod 10000;
    result := IntToStr(a) + 'Y' + INTTOSTR(b) + 'W' + inttostr(c);
  end;
end;

function GetRunTimeInfo: string;
var
  lvMSec, lvRemain: Int64;
  lvDay, lvHour, lvMin, lvSec: Integer;
begin
  lvMSec := GetTickCount64 - StartRunTime;
  lvDay := Trunc(lvMSec / MSecsPerDay);
  lvRemain := lvMSec mod MSecsPerDay;

  lvHour := Trunc(lvRemain / (MSecsPerSec * 60 * 60));
  lvRemain := lvRemain mod (MSecsPerSec * 60 * 60);

  lvMin := Trunc(lvRemain / (MSecsPerSec * 60));
  lvRemain := lvRemain mod (MSecsPerSec * 60);

  lvSec := Trunc(lvRemain / (MSecsPerSec));

  if lvDay > 0 then
    Result := Result + IntToStr(lvDay) + ' d ';
  if lvHour > 0 then
    Result := Result + IntToStr(lvHour) + ' h ';
  if lvMin > 0 then
    Result := Result + IntToStr(lvMin) + ' m ';
  if lvSec > 0 then
    Result := Result + IntToStr(lvSec) + ' s ';
end;

function CurrentMemoryUsage: Cardinal;
var
  pmc: _PROCESS_MEMORY_COUNTERS; //uses psApi
  ProcHandle: HWND;
  iSize: DWORD;
begin
  Result := 0;
  try
    iSize := SizeOf(_PROCESS_MEMORY_COUNTERS);
    pmc.cb := iSize;
    ProcHandle := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ,
      False, GetCurrentProcessId); //由PID取得进程对象的句柄
    if GetProcessMemoryInfo(ProcHandle, @pmc, iSize) then
      Result := (pmc.WorkingSetSize div 1024) div 1024;
  finally
    CloseHandle(ProcHandle);
  end;
end;


// 取得当前进程的线程数
function GetProcessThreadCount: integer;
var
  SnapProcHandle: THandle;
  ThreadEntry: TThreadEntry32;
  Next: boolean;
begin
  result := 0;
  try
    SnapProcHandle := CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
    if SnapProcHandle <> THandle(-1) then
    begin
      ThreadEntry.dwSize := SizeOf(ThreadEntry);
      Next := Thread32First(SnapProcHandle, ThreadEntry);
      while Next do
      begin
        if (ThreadEntry.th32OwnerProcessID = GetCurrentProcessId) then
          result := result + 1;
        Next := Thread32Next(SnapProcHandle, ThreadEntry);
      end;
    end;
  finally
    CloseHandle(SnapProcHandle);
  end;
end;

function GetCPUID: TCPUID; assembler; register;
asm
        PUSH    EBX
        PUSH    EDI
        MOV     EDI, EAX
        MOV     EAX, 1
        DW      $A20F
        STOSD
        MOV     EAX, EBX
        STOSD
        MOV     EAX, ECX
        STOSD
        MOV     EAX, EDX
        STOSD
        POP     EDI
        POP     EBX
end;

function GetCPUIDStr: string;
var
  CPUID: TCPUID;
begin
  CPUID := GetCPUID;
  Result := IntToHex(CPUID[4], 8) + IntToHex(CPUID[1], 8);
end;

function CheckCPUID: Boolean;
var
  SDATE: string;
  IDATE: Integer;
  SID: string;
  AiniR: Tinifile;
  Time: TDateTime;
begin
  Result := False;
  try
    try
      AiniR := TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'YxDServer.ini');
      SID := EnCode(GetCPUIDStr);
      if AiniR.ReadString('Rigester', 'ID', '') <> SID then
        Exit;
      SDATE := AiniR.ReadString('Rigester', 'Date', '');
      if SDATE = '' then
        Exit;

      SDATE := DeCode(SDATE);
      IDATE := StrToIntDEF(SDATE, 0);
      if IDATE = 0 then
        exit;
      Time := GetTime;
      if (Time <> 0) then
      begin
        if IDATE < StrToInt(FormatDateTime('YYYYMMDD', Time)) then
          exit;
      end
      else if IDATE < StrToInt(FormatDateTime('YYYYMMDD', Now)) then
        exit;
    except
      exit;
    end;
  finally
    FreeAndNil(AiniR);
  end;
  Result := True;
end;

function RegisterCPUID: Boolean;
var
  SDATE: string;
  SID: string;
  AiniR: Tinifile;
  Time: TDateTime;
begin
  Result := False;
  try
    try
      SID := EnCode(GetCPUIDStr);
      Time := GetTime;
      if Time <> 0 then
        SDATE := FormatDateTime('YYYYMMDD', Time + 365*3)
      else
        SDATE := FormatDateTime('YYYYMMDD', Now + 365*3);
      SDATE := EnCode(SDATE);
      AiniR := TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'YxDServer.ini');
      AiniR.WriteString('Rigester', 'ID', SID);
      AiniR.WriteString('Rigester', 'Date', SDATE);
    except
      Exit;
    end;
  finally
    FreeAndNil(AiniR);
  end;
  Result := True;

end;

function GetTime: TDateTime;
var
  XmlHttp: Variant;
  datetxt: string;
  DateLst: TStringList;
  mon: string;
  timeGMT, GetNetTime: TDateTime;
begin
  result := 0;
  try
    try
      XmlHttp := createoleobject('Microsoft.XMLHTTP');
      try
        XmlHttp.Open('Get', 'http://time.tianqi.com/', False);
        XmlHttp.send;
        datetxt := XmlHttp.getResponseHeader('Date');
      except
        Exit;
      end;
      //if datetxt = '' then Exit;
      datetxt := Copy(datetxt, Pos(',', datetxt) + 1, 100);
      datetxt := StringReplace(datetxt, 'GMT', '', []);
      datetxt := Trim(datetxt);
      DateLst := TStringList.Create;
      while Pos(' ', datetxt) > 0 do
      begin
        DateLst.Add(Copy(datetxt, 1, Pos(' ', datetxt) - 1));
        datetxt := Copy(datetxt, Pos(' ', datetxt) + 1, 100);
      end;
      DateLst.Add(datetxt);
      if DateLst.Count < 1 then Exit;
      if DateLst[1] = 'Jan' then
        mon := '01'
      else if DateLst[1] = 'Feb' then
        mon := '02'
      else if DateLst[1] = 'Mar' then
        mon := '03'
      else if DateLst[1] = 'Apr' then
        mon := '04'
      else if DateLst[1] = 'Mar' then
        mon := '05'
      else if DateLst[1] = 'Jun' then
        mon := '06'
      else if DateLst[1] = 'Jul' then
        mon := '07'
      else if DateLst[1] = 'Aug' then
        mon := '08'
      else if DateLst[1] = 'Sep' then
        mon := '09'
      else if DateLst[1] = 'Oct' then
        mon := '10'
      else if DateLst[1] = 'Nov' then
        mon := '11'
      else if DateLst[1] = 'Dec' then
        mon := '12';
      timeGMT := StrToDateTime(DateLst[2] + '-' + mon + '-' + DateLst[0] + ' ' +
        DateLst[3]);
      GetNetTime := IncHour(timeGMT, 8);
    finally
      FreeAndNil(DateLst);
      XmlHttp := unassigned;
    end;
    Result := GetNetTime;
  except

  end;
end;

procedure SelfAutoRun(R: Boolean);
const
  KEY_WOW64_64KEY = $0100;
  App_Key = 'YxDServer';

  function IsWoW64: Boolean;
  var
    Kernel32Handle: THandle;
    IsWow64Process: function(Handle: THandle; var Res: BOOL): BOOL; stdcall;
    GetNativeSystemInfo: procedure(var lpSystemInfo: TSystemInfo); stdcall;
    isWoW64: Bool;
    SystemInfo: TSystemInfo;
  const
    PROCESSOR_ARCHITECTURE_AMD64 = 9;
    PROCESSOR_ARCHITECTURE_IA64 = 6;
  begin
    Kernel32Handle := GetModuleHandle('KERNEL32.DLL');
    if Kernel32Handle = 0 then
      Kernel32Handle := LoadLibrary('KERNEL32.DLL');
    if Kernel32Handle <> 0 then
    begin
      try
        IsWow64Process := GetProcAddress(Kernel32Handle, 'IsWow64Process');
      //需要注意是GetNativeSystemInfo 函数从Windows XP 开始才有，
      //而 IsWow64Process 函数从 Windows XP with SP2 以及 Windows Server 2003 with SP1 开始才有。
      //所以使用该函数的时候最好用GetProcAddress 。
        GetNativeSystemInfo := GetProcAddress(Kernel32Handle, 'GetNativeSystemInfo');
        if Assigned(IsWow64Process) then
        begin
          IsWow64Process(GetCurrentProcess, isWoW64);
          Result := isWoW64 and Assigned(GetNativeSystemInfo);
          if Result then
          begin
            GetNativeSystemInfo(SystemInfo);
            Result := (SystemInfo.wProcessorArchitecture =
              PROCESSOR_ARCHITECTURE_AMD64) or (SystemInfo.wProcessorArchitecture
              = PROCESSOR_ARCHITECTURE_IA64);
          end;
        end
        else
          Result := False;
      finally
        //CloseHandle(Kernel32Handle);
      end;
    end
    else
      Result := False;

  end;

var
  RegF: TRegistry;
begin
  if isWoW64 then
    RegF := TRegistry.Create(KEY_WRITE or KEY_READ or KEY_WOW64_64KEY)
  else
    RegF := TRegistry.Create;
  RegF.RootKey := HKEY_LOCAL_MACHINE;
  try
    RegF.OpenKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Run', True);
    try
      if R then
      begin
        if not RegF.KeyExists(App_Key) then
          RegF.WriteString(App_Key, application.ExeName);
      end
      else
      begin
        if not RegF.KeyExists(App_Key) then
          RegF.DeleteValue(App_Key);
      end;
    finally
      RegF.CloseKey;
      FreeAndNil(RegF);
    end;
  except
    //nothing...
  end;
end;

end.

