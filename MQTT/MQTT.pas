{
//***********本单元已在initialization中自动加载MQTT，无须手动创建*************//
//***************MQTT单元说明***************************//
1.在工程中引用本单元MQTT.pas
2.配置在函数GetMQTT中加载
3.MQTT业务在函数OnPrePublish中实现
4.实际业务在函数Execute中实现

//****************************源码来自**************************//
//MQTTClient.pas
//QQ 287413288
//Mqtt 客户端(支持协议版本 Mqtt Version 3.1.1)
//支持 Qos0,Qos1,Qos2
//掉线自动重连机制
//(可以选择)是否自动发送心跳包(PingReq-->PingRsp),心跳间隔
//不支持SSL,WeboSocket,后续版本会加入支持
//无第三方代码依赖.AllInOne(全部功能在一个单元内完成)
//编译测试D7,XE7(64位)
//Version 1.0.0.5)
//****************************源码来自**************************//
}


unit MQTT;

interface

uses
  Windows, Messages, SysUtils, classes, WinSock, IniFiles, uDataYxDserver,
  Vcl.Forms,QLog;

type
  TMqttBytes = array of Byte;
  //为64位编译准备
  {$IF Defined(CPUX64)}

  TNativeInt = NativeInt;
  {$ELSE}

  TNativeInt = integer;
  {$IFEND}

  TMQTTMessageType = (Reserved0,	//0	Reserved
    mqCONNECT, //	1	Client request to connect to Broker
    CONNACK, //	2	Connect Acknowledgment
    mqttPUBLISH, //	3	Publish message
    PUBACK, //	4	Publish Acknowledgment
    PUBREC, //	5	Publish Received (assured delivery part 1) Qos2
    PUBREL, //	6	Publish Release (assured delivery part 2)  Qos2
    PUBCOMP, //	7	Publish Complete (assured delivery part 3) Qos2
    SUBSCRIBE, //	8	Client Subscribe request
    SUBACK, //	9	Subscribe Acknowledgment
    UNSUBSCRIBE, // 10	Client Unsubscribe request
    UNSUBACK, // 11	Unsubscribe Acknowledgment
    mqttPINGREQ, //	12	PING Request
    PINGRESP, //	13	PING Response
    mqttDISCONNECT, // 14	Client is Disconnecting
    Reserved15 //	15
);

  TQosLevel = (Qos0, Qos1, Qos2);

  //连接回复的状态码
  TConnectAckState = (csConnectionAccepted, //0
    csInvalidProtocolVersion, //1
    csInvalidClientID, //2
    csServerunavailable, //3
    csInvalidUserOrPassWord, //4
    csNoAuthorizd //5
);

  PMQTTFixedHeader = ^TMQTTFixedHeader;

  TMQTTFixedHeader = record
    MessageType: TMQTTMessageType;
    Dup: Boolean;
    Qos: Byte;
    Retain: Boolean;
    RemainingLength: DWORD; //最大值 268435455(256M)
  end;

  PRecvPublishMessage = ^TRecvPublishMessage;

  TRecvPublishMessage = record
    Dup: Boolean;
    Qos: TQosLevel;
    Retain: Boolean;
    Topic: AnsiString;
    MsgId: Word;
    MsgContent: AnsiString;
  end;

  TConnAckEvent = procedure(Sender: TObject; ReturnCode: integer) of object;

  TPubAckEvent = procedure(Sender: TObject; MsgId: Word) of object;

  TPubRecEvent = procedure(Sender: TObject; MsgId: Word) of object;

  TPubRelEvent = procedure(Sender: TObject; MsgId: Word) of object;

  TPubCompEvent = procedure(Sender: TObject; MsgId: Word) of object;

  TSubAckEvent = procedure(Sender: TObject; MessageID: integer; GrantedQoS:
    Integer) of object;

  TPublishEvent = procedure(Sender: TObject; const msg: TRecvPublishMessage) of object;

  TPingRespEvent = procedure(Sender: TObject) of object;

  TSocketConnectedEvent = procedure(Sender: TObject; Connected: Boolean) of object;
  //

  TMqttDisConnect = procedure(Sender: TObject) of object;

  TUnSubAckEvent = procedure(Sender: TObject; MsgId: Word) of object;

  TMqttSocket = class;

  TMQTTClient = class
  private
    FTCP: TMqttSocket;
    FClientID: AnsiString;
    FUserName: AnsiString;
    FPassWord: AnsiString;
    FSendStream: TMemoryStream;
    FRecvStream: TMemoryStream;
    FCS: TRTLCriticalSection;
    FstrCS: TRTLCriticalSection; //用于FErrDesc
    FUserCancelSocket: Boolean;
    FDisConnectRefCount: Integer;
    FErrDesc: array[1..1024] of Ansichar;
    FAutoPing: Boolean;
    FPingInterval: Integer;
    FAutoPingInterval: Word;
    FMsgId: Word;
    FIocpThreadId: DWORD;
    FTcpAddr: AnsiString;
    FConnectTimeOutSec: Integer; //秒
    FClearSession: Boolean;
    FAutoReConnect: Boolean;
    FAutoReConnectDelaySec: Integer; //秒
    FAutoPingRuning: Boolean;
    FTerminal: Boolean;
    FRunThreadRefCount: Integer;
    //
    FConnAckEvent: TConnAckEvent;
    FPubAckEvent: TPubAckEvent;
    FPubRecEvent: TPubRecEvent;
    FPubRelEvent: TPubRelEvent;
    FPUbCompEvent: TPubCompEvent;
    FSubAckEvent: TSubAckEvent;
    FPublishEvent: TPublishEvent;
    FPingRespEvent: TPingRespEvent;
    FMqttDisConnect: TMqttDisConnect;
    FUnSubscribeEvent: TUnSubAckEvent;
    FSocketConnectedEvent: TSocketConnectedEvent;
    FKeepAliveTimer: Word;
    FComponmentVersion: string;
    FWillFlag: Boolean;
    FWillQos: TQosLevel;
    FWillRetain: Boolean;
    FWillTopic: AnsiString;
    FWillMessage: AnsiString;
    FmqttConnected: Boolean;
    FQos: TQosLevel;
    FReTain: Boolean;
    FSubTopic: AnsiString;
    FBSub: Boolean;
    FBMQTT: Boolean;
    FPubTopic: AnsiString;
    //
    procedure SetErrDesc(const Msg: AnsiString);
    procedure Lock();
    procedure UnLock();
    //
    function FixedHeader(MessageType: TMQTTMessageType; Dup, Qos, Retain: Word): Byte;
    //
    procedure InnerRead();
    procedure ReadDataInThread();
    procedure AutoPingReqProc();
    //
    function Process_CONNACK(const FH: TMQTTFixedHeader): integer;
    function Process_PUBACK(const FH: TMQTTFixedHeader): Integer;
    function Process_PUBREC(const FH: TMQTTFixedHeader): Integer;
    function Process_PUBREL(const FH: TMQTTFixedHeader): Integer;
    function Process_PUBCOMP(const FH: TMQTTFixedHeader): Integer;
    function Process_SUBACK(const FH: TMQTTFixedHeader): Integer;
    function Process_UNSUBACK(const FH: TMQTTFixedHeader): Integer;
    function Process_PUBLISH(const FH: TMQTTFixedHeader): Integer; //收到推送的消息
    function Process_PingResp(): Integer;
    //
    procedure MakeMqttConnectData();
    procedure MakeMqttPublishData(const ATopic, AMsgContent: AnsiString; Dup:
      Boolean; Qos: TQosLevel; Retain: Boolean; var MsgId: Word);
    procedure MakeMqttSubScribeData(const ATopic: AnsiString; Qos: TQosLevel;
      MsgId: Word);
    procedure MakeMqttUnSubScribeData(const ATopic: AnsiString; MsgId: Word);
    procedure MakeMqttPingReqData();
    procedure MakeMqttDisConnectData();
    //
    procedure AckPublish_Qos1(MsgId: Word);
    procedure AckPublish_Qos2(MsgId: Word);
    procedure AckPubRecToServer(MsgId: Word);
    procedure AckPubCompToServer(MsgId: Word);
    //
    function GetErrDesc(): string;
    function GetCurrentMsgId(): Word;
    //
    procedure SocketConnect(TcpAddr: string; ConnectTimeOut: Integer);
    procedure mqttConnect();
    //
    procedure PostThreadMessageEh(ThreadID: DWORD; Msg: DWORD; WParam, LParam:
      TNativeInt);
    function GetClientID: AnsiString;
    procedure SetClientID(const Value: AnsiString);
    function CalcConnectRemainingLength(): Integer; //mqttConnect 数据包 Remaining Length
    //
    procedure ConnectParameterCheck();
  protected
    property TCP: TMqttSocket read FTCP;
    procedure InnerConnect();
    procedure WndProc();
  public
    constructor Create();
    destructor Destroy(); override;
    //
    function Publish(ATopic: AnsiString = ''; AMsgContent: AnsiString = ''; Qos:
      TQosLevel = Qos1; Reatin: Boolean = false): Integer;
    function Subscribe(ATopic: AnsiString = ''; Qos: TQosLevel = Qos0): Integer;
    function UnSubscribe(ATopic: AnsiString = ''): Integer;
    function PingReq(): Integer;
    procedure Connect();
    procedure DisConnect();
    procedure StartAutoPing(Interval: Word); //时间间隔(秒)
    function GetMqttSocket(): TMqttSocket;
  public
    property mqttConnected: Boolean read FmqttConnected;
    property ClientID: AnsiString read GetClientID write SetClientID;
    property ClearSession: Boolean read FClearSession write FClearSession;
    property UserName: AnsiString read FUserName write FUserName;
    property PassWord: AnsiString read FPassWord write FPassWord;
    property KeepAliveTimer: Word read FKeepAliveTimer write FKeepAliveTimer; //默认10秒
    property UserCancelSocket: Boolean read FUserCancelSocket;
    property ErrDesc: string read GetErrDesc;
    property AutoPing: Boolean read FAutoPing write FAutoPing;
    property PingInterval: Integer read FPingInterval write FPingInterval; //AutoPing=true 时有效(秒)
    property CurrentMsgId: Word read GetCurrentMsgId;
    property TcpAddr: AnsiString read FTcpAddr write FTcpAddr; //Host:Port
    property ConnectTimeOutSec: Integer read FConnectTimeOutSec write
      FConnectTimeOutSec; //毫秒
    property AutoReConnect: Boolean read FAutoReConnect write FAutoReConnect; //true 掉线后,自动重连
    property AutoReConnectDelaySec: Integer read FAutoReConnectDelaySec write
      FAutoReConnectDelaySec; //延迟多少秒后,开始重连
    property WillFlag: Boolean read FWillFlag write FWillFlag; // write FWillFlag
    property WillRetain: Boolean read FWillRetain write FWillRetain;
    property WillQos: TQosLevel read FWillQos write FWillQos;
    property WillTopic: AnsiString read FWillTopic write FWillTopic;
    property WillMessage: AnsiString read FWillMessage write FWillMessage;
    property ComponmentVersion: string read FComponmentVersion;
    property Connected: Boolean read FmqttConnected; //true mqtt 已经处于连接状态
    property Qos: TQosLevel read FQos write FQos;
    property ReTain: Boolean read FReTain write FReTain;
    property SubTopic: AnsiString read FSubTopic write FSubTopic;
    property PubTopic: AnsiString read FPubTopic write FPubTopic;
    property BSub: Boolean read FBSub write FBSub;
    property BMQTT: Boolean read FBMQTT write FBMQTT;

    //
    property OnSocketConnect: TSocketConnectedEvent read FSocketConnectedEvent
      write FSocketConnectedEvent;
    property OnFConnAck: TConnAckEvent read FConnAckEvent write FConnAckEvent;
    property OnPubAck: TPubAckEvent read FPubAckEvent write FPubAckEvent;
    property OnPubRec: TPubRecEvent read FPubRecEvent write FPubRecEvent;
    property OnPubRel: TPubRelEvent read FPubRelEvent write FPubRelEvent;
    property OnPubComp: TPubCompEvent read FPUbCompEvent write FPUbCompEvent;
    property onSubAck: TSubAckEvent read FSubAckEvent write FSubAckEvent;
    property OnPublish: TPublishEvent read FPublishEvent write FPublishEvent;
    property OnPingResp: TPingRespEvent read FPingRespEvent write FPingRespEvent;
    property OnDisConnect: TMqttDisConnect read FMqttDisConnect write FMqttDisConnect;
    property OnUnSubAck: TUnSubAckEvent read FUnSubscribeEvent write FUnSubscribeEvent;
    procedure OnPrePublish(Sender: TObject; const msg: TRecvPublishMessage);
    function Execute(InValue: string; out OutValue: string): Boolean;
  end;

  TRedisStreamEh = class(TMemoryStream)
  private
    FReadEndPosition: Int64;
    function getDataLen: Int64;
  public
    property Datalen: Int64 read getDataLen;
    property ReadEndPosition: Int64 read FReadEndPosition write FReadEndPosition;
  end;

  TMqttSocket = class
  private
    FwsaData: TWSADATA;
    FSOCKET: TSocket;
    FHost: AnsiString;
    FPort: WORD;
    FTag: Integer;
    FConnected: Boolean;
    FRecvTimeOut: Integer;
    FSendTimeOut: Integer;
    FErrorCode: Integer;
    FInputStream: TRedisStreamEh;
    function GetLastErrorErrorMessage(ErrCode: Integer): string;
    procedure setRecvTimeOut(const Value: Integer);
    procedure SetSendTimeOut(const Value: Integer);
    function getNagle: Boolean;
    procedure SetNagle(const Value: Boolean);
  protected
    procedure RaiseWSExcption();
    procedure InitSocket(); virtual;
    procedure InnerConnect(const RemoteHost: AnsiString; RemotePort: Word; const
      ATimeOut: Integer = -1); //单位毫秒
  public
    constructor Create();
    destructor Destroy(); override;
    function ResolveIP(const HostName: AnsiString): AnsiString; {将域名解释成IP}
    procedure Connect(const ATimeOut: Integer = -1); //单位毫秒
    procedure Disconnect();
    //Result 0:对方优雅关闭;1:有数据可读;如果出现Socket错误 触发异常
    function WaitForData(ATimeOut: Integer = 0): integer; //单位毫秒

    function PeekBuf(Buf: PAnsiChar; BufSize: Integer): Integer;
    function SendBuf(Buf: Pointer; BufSize: Integer): Integer;
    function ReceiveBuf(Buf: PAnsiChar; BufSize: Integer; ATimeOut: Integer = -1):
      Integer;
    function ReceiveStream(AStream: TStream; MaxRecvSize: Integer; ATimeOut:
      Integer = -1): Int64;
    function ReadLn(const Bufffer: PAnsiChar; BufLen: Integer; ATimeOut: Integer
      = -1): Integer; //扫描 #13#10

  public
    property InputStream: TRedisStreamEh read FInputStream;
    property ErrorCode: Integer read FErrorCode;
    property HSocket: TSocket read FSocket;
    property Host: AnsiString read FHost write FHost;
    property Port: WORD read FPort write FPort;
    property Tag: Integer read FTag write FTag;
    property Connected: Boolean read FConnected;
    property TcpNoDelay: Boolean read getNagle write SetNagle; //true 禁用Nagle 算法,启动时默认禁止
    property ReadTimeOut: Integer read FRecvTimeOut write FRecvTimeOut; //默认 10秒(10 * 1000),单位毫秒
  end;

var
  MQ: TMQTTClient;

procedure GetMQTT;


implementation

procedure GetMQTT;
var
  AINI: TIniFile;
  FileName: string;
begin
  if not Assigned(MQ) then
    MQ := TMQTTClient.Create;
  try
    FileName := ExtractFileDir(ParamStr(0)) + '\YxDServer.ini';
    if not FileExists(FileName) then
      Exit;
    AINI := TIniFile.Create(FileName);
    try
      MQ.ClientID := AINI.ReadString('MQTT', 'ClientID', '');
      MQ.TcpAddr := AINI.ReadString('MQTT', 'Server', '');
      MQ.UserName := AINI.ReadString('MQTT', 'User', '');
      MQ.PassWord := AINI.ReadString('MQTT', 'Pass', '');
      MQ.ClearSession := AINI.ReadBool('MQTT', 'ClearSession', False);
      MQ.ConnectTimeOutSec := 3; //Socket连接超时,3秒
      MQ.AutoPing := AINI.ReadBool('MQTT', 'AutoPing', False); //自动发心跳包(PingReq)
      MQ.PingInterval := 3; //3秒发送1次心跳包
      MQ.KeepAliveTimer := 5; //(1.5倍)秒区间服务器端秒收不到消息,认为掉线
      MQ.AutoReConnect := AINI.ReadBool('MQTT', 'ReConnect', False); //自动重连
      MQ.AutoReConnectDelaySec := 5; //5秒后自动重连
      MQ.Qos := TQosLevel(AINI.ReadInteger('MQTT', 'Qos', 0));
      MQ.ReTain := AINI.ReadBool('MQTT', 'Retain', False); //最后一次消息在服务器上保存
      MQ.PubTopic := AINI.ReadString('MQTT', 'PubTopic', ''); //接收消息的主题
      MQ.SubTopic := AINI.ReadString('MQTT', 'SubTopic', ''); //订阅消息的主题
      MQ.BSub := AINI.ReadBool('MQTT', 'BSub', False); //是否订阅
      MQ.BMQTT := AINI.ReadBool('MQTT', 'BMQTT', False); //是否启用MQTT
      MQ.WillFlag := TRUE;
      MQ.WillRetain := TRUE;
      MQ.WillQos := Qos1;
      MQ.WillTopic := 'clientwillmessage';
      MQ.WillMessage := format('ClientId[%s] off line(WILL MESSAGE)', [MQ.ClientID]);
      if MQ.BMQTT then
        MQ.Connect();
      if MQ.BSub then
        MQ.Subscribe()
      else
        MQ.UnSubscribe();
      MQ.OnPublish := MQ.OnPrePublish;
    finally
      FreeAndNil(AINI);
    end;
  except
  end;
end;

const
  WT_EXECUTELONGFUNCTION = ULONG($00000010);
  WM_MQTT_SOCKET_CONNECT = WM_USER + 1;
  WM_MQTT_DISCONNECT = WM_USER + 2;

const
  ANSI_CRLF: AnsiString = #13#10;

const
  SF_SOCKET_BUFF_SIZE = 1024 * 32;

type
  TVirtualStream = class
  private
    FPosition: Int64;
  public
    function Write(const Buffer; Count: Longint): Longint;
  public
    property Position: Int64 read FPosition write FPosition;
  end;

function PosBuff(PSrc: PAnsiChar; pSubStr: PAnsiChar; LenSrcStr: Integer;
  LenSubStr: Integer; Offset: Cardinal = 1): Integer;
var
  X: Integer;
  Len: Integer;
begin
  if (LenSrcStr < 1) or (LenSubStr < 1) or (PSrc = nil) or (pSubStr = nil) then
  begin
    Result := 0;
    Exit;
  end;

  Result := Offset;
  if Result = 0 then
    Result := 1;
  Len := LenSrcStr - LenSubStr + 1;
  Inc(PSrc, Result - 1);
  while (Result <= Len) do
  begin
    if PSrc^ = pSubStr^ then
    begin
      X := 1;
      while ((X < LenSubStr) and (PSrc[X] = pSubStr[X])) do
        Inc(X);
      if (X = LenSubStr) then
        Exit;
    end;
    Inc(Result);
    Inc(PSrc);
  end;
  Result := 0;
end;

function IsIntString(const Value: AnsiString): Boolean;
var
  Index: Integer;
  CH: AnsiChar;
begin
  Result := false;
  if Value = '' then
  begin
    Result := FALSE;
    Exit;
  end;
  for Index := 1 to Length(Value) do
  begin
    CH := Value[Index];
    Result := (CH = #20) or (CH = '-') or (CH in ['0'..'9']);
    if not Result then
      Break;
  end;
end;

procedure TranData(MS: TMemoryStream; L: DWORD);
var
  Sp: PAnsichar;
  Diff: DWORD;
begin
  Diff := MS.Position - L;
  if Diff > 0 then
  begin
    Sp := MS.Memory;
    Inc(Sp, L);
    Windows.CopyMemory(MS.Memory, Sp, Diff);
    MS.Position := Diff;
    Exit;
  end;
  MS.Position := 0;
end;

function QueueUserWorkItem(func: TThreadStartRoutine; Context: Pointer; Flags:
  ULONG): BOOL; stdcall; external 'Kernel32';

//Result=1;OK
//Result=0;数据不足
//Result<0;协议错误
function ParseMQTTFixedHeader(Buffer: Pointer; Len: Integer; var FH:
  TMQTTFixedHeader): Integer;
var
  B: Byte;
  Sp: PByte;
begin
  (*
     Bit(7-4) MessageType
     Bit(3)   Dup Flag
     Bit(2-1) Qos
     Bit(0)   RETAIN
  *)
  Sp := Buffer;
  B := Byte(Sp^) shr 4;
  B := B and $0F;
  ZeroMemory(@FH, SizeOf(FH));
  //
  FH.MessageType := TMQTTMessageType(B);
  //
  B := Byte(Sp^);
  FH.Dup := (B and $08) = $08;
  //
  B := Sp^ shr 1;
  FH.Qos := (B and $03);
  //
  FH.Retain := (Sp^ and $01) = $01;
  //
  if Len = 1 then
  begin
    Result := 0; //数据不足
    Exit;
  end;
  //
  Inc(Sp);
  B := Sp^;
  if (B and $80) = 0 then
  begin
    //bit7=0;
    FH.RemainingLength := B;
    Result := 1;
    Exit;
  end;
  Result := 1;
end;

(*
    (0x00)                            127 (0x7F)
    128(0x80, 0x01)                   16383 (0xFF, 0x7F)
    16384 (0x80, 0x80, 0x01)          2097151 (0xFF, 0xFF, 0x7F)
    2097152 (0x80, 0x80, 0x80, 0x01)  268435455 (0xFF, 0xFF, 0xFF, 0x7F)
*)
function RLIntToBytes(ARlInt: Integer): TMqttBytes;
var
  byteindex: Integer;
  digit: Integer;
begin
  SetLength(Result, 1);
  byteindex := 0;
  while (ARlInt > 0) do
  begin
    digit := ARlInt mod 128;
    ARlInt := ARlInt div 128;
    if ARlInt > 0 then
    begin
      digit := digit or $80;
    end;
    Result[byteindex] := digit;
    if ARlInt > 0 then
    begin
      Inc(byteindex);
      SetLength(Result, Length(Result) + 1);
    end;
  end;
end;


{ TMqttClient }

procedure TMqttClient.SocketConnect(TcpAddr: string; ConnectTimeOut: Integer);
var
  Index: Integer;
begin
  if FTerminal then
    Exit;
  //
  FUserCancelSocket := FALSE;
  Index := Pos(':', TcpAddr);
  if Index = 0 then
    raise Exception.CreateFmt('%s.SocketConnect(),TcpAddr[%s] InValid Format(HOST:PORT)',
      [ClassName, TcpAddr]);
  TCP.Host := Copy(TcpAddr, 1, Index - 1);
  Tcp.Port := StrToInt(Copy(TcpAddr, Index + 1, system.MaxInt));
  TCP.Connect(ConnectTimeOut);
end;

function ThreadProc_IocpWndProc(lpParameter: Pointer): Integer; stdcall;
var
  Obj: TMqttClient;
begin
  Obj := TMqttClient(lpParameter);
  Windows.InterlockedIncrement(Obj.FRunThreadRefCount);
  try
    Obj.WndProc();
  finally
    Windows.InterlockedDecrement(Obj.FRunThreadRefCount);
  end;
  Result := 0;
end;

constructor TMqttClient.Create;
begin
  System.IsMultiThread := TRUE;
  //
  FTCP := TMqttSocket.Create();
  FSendStream := TMemoryStream.Create();
  FSendStream.Size := 1024 * 32;
  //
  FRecvStream := TMemoryStream.Create();
  FRecvStream.Size := 1024 * 32;
  //
  InitializeCriticalSection(FCS);
  InitializeCriticalSection(FstrCS);
  //
  FUserCancelSocket := FALSE;
  //
 // FHWnd := Classes.AllocateHWnd(WndProc);
  //
  FAutoPing := FALSE;
  FMsgId := 1;
  //
  QueueUserWorkItem(ThreadProc_IocpWndProc, Pointer(Self), WT_EXECUTELONGFUNCTION);
  //
  ClientID := 'mqtt_YxDServer';
  ClearSession := FALSE;
  UserName := '';
  PassWord := '';
  AutoPing := TRUE;
  PingInterval := 2; //2秒
  TcpAddr := '127.0.0.1:1883';
  ConnectTimeOutSec := 3; //3秒
  AutoReConnect := true; //true 掉线后,自动重连
  AutoReConnectDelaySec := 5; ////延迟多少秒后,开始重连,5秒后自动重连
  //
  FAutoPingRuning := FALSE;
  //
  FKeepAliveTimer := 3;
  FTerminal := FALSE;
  //
  FWillFlag := FALSE;
  FWillQos := Qos2;
  FWillRetain := TRUE;
  FComponmentVersion := 'Version 1.0.0.5';
end;

destructor TMqttClient.Destroy;
var
  iRet: Integer;
begin
  //
  FAutoReConnect := FALSE;
  FTerminal := TRUE;
  FTCP.Disconnect();

  //等待运行的线程全部结束
  while (true) do
  begin
    Sleep(10);
    Windows.InterlockedExchange(iRet, FRunThreadRefCount);
    if iRet = 0 then
      Break;
  end;
  //
  FTCP.Free();
  DeleteCriticalSection(FCS);
  DeleteCriticalSection(FstrCS);
  //
  FRecvStream.Free();
  FSendStream.Free();
  inherited;
end;

procedure TMQTTClient.MakeMqttConnectData();
const
  //3.1.1
  MQTT_PROTOCOL: AnsiString = 'MQTT';
  MQTT_VERSION: Byte = 4;
  //3.1
  //MQTT_PROTOCOL:AnsiString='MQIsdp';
  //MQTT_VERSION=3;
var
  B: Byte;
  W: Word;
  Flag: Byte;
 // SavedPosition:int64;
  LvClientID: AnsiString;
  RemainLength: Integer;
  RLB: TMqttBytes;
begin
  RemainLength := CalcConnectRemainingLength(); //Remaining-Length
  RLB := RLIntToBytes(RemainLength);

  //FixHeader(1)
  B := FixedHeader(mqCONNECT, 0, 0, 0);
  FSendStream.Write(B, 1);

  //FixHeader(2)
  W := 0;
  //FSendStream.Write(W,1);//占位符
  FSendStream.Write(RLB[0], Length(RLB)); //Remaining-Length
  //ProtocolName
  W := WinSock.htons(Length(MQTT_PROTOCOL));
  FSendStream.Write(W, 2);
  FSendStream.Write(MQTT_PROTOCOL[1], Length(MQTT_PROTOCOL));

  //ProtocolVersion
  B := MQTT_VERSION;
  FSendStream.Write(B, 1);

  //ConnectFlags
  (*
     UserName(7)        $80
     PassWord(6)        $40
     Will Retain(5)  X  $20
     Will QoS(4-3)   X  $00(Qos0),$08(Qos1),$10(Qos2)
     Will Flag(2)    X  $04
     CleanSession(1) X  $02
     Reserved(0)     X  $00
  *)
  Flag := $00;
  if ClearSession then
    Flag := Flag or $02;
  if Length(UserName) > 0 then
    Flag := Flag or $80;
  if Length(PassWord) > 0 then
    Flag := Flag or $40;
  if WillFlag then
  begin
    Flag := Flag or $04;
    case WillQos of
      Qos0:
        Flag := Flag or $00;
      Qos1:
        Flag := Flag or $08;
      Qos2:
        Flag := Flag or $10;
    end;
    if WillRetain then
      Flag := Flag or $20;
  end;
  FSendStream.Write(Flag, 1);

  //KeepAlive timer
  W := WinSock.htons(KeepAliveTimer);
  FSendStream.Write(W, 2);

  //ClientID
  LvClientID := Self.ClientID;
  W := Length(LvClientID);
  W := WinSock.htons(W);
  FSendStream.Write(W, 2);
  FSendStream.Write(ClientID[1], Length(ClientID));

  if WillFlag then
  begin
    //WillTopic
    W := WinSock.htons(Length(WillTopic));
    FSendStream.Write(W, 2);
    FSendStream.Write(WillTopic[1], Length(WillTopic));
    //WillMessage
    W := WinSock.htons(Length(WillMessage));
    FSendStream.Write(W, 2);
    FSendStream.Write(WillMessage[1], Length(WillMessage));
  end;

  //UserName
  if Length(UserName) > 0 then
  begin
    W := WinSock.htons(Length(Self.UserName));
    FSendStream.Write(W, 2);
    FSendStream.Write(Self.UserName[1], Length(Self.UserName));
  end;

  //PassWord
  if Length(Self.PassWord) > 0 then
  begin
    W := WinSock.htons(Length(Self.PassWord));
    FSendStream.Write(W, 2);
    FSendStream.Write(Self.PassWord[1], Length(Self.PassWord));
  end;
  //
  //SavedPosition := FSendStream.Position;
  //B := SavedPosition - 2;
  //FSendStream.Position := 1;
  //FSendStream.Write(B,1);
  //FSendStream.Position := SavedPosition;
  //
end;

function TMQTTClient.FixedHeader(MessageType: TMQTTMessageType; Dup, Qos, Retain:
  Word): Byte;
begin
  { Fixed Header Spec:
    bit	   |7 6	5	4	    | |3	     | |2	1	     |  |  0   |
    byte 1 |Message Type| |DUP flag| |QoS level|	|RETAIN| }
  Result := (Ord(MessageType) * 16) + (Dup * 8) + (Qos * 2) + (Retain * 1);
end;

function ThreadProc_Mqtt_Read(lpParameter: Pointer): Integer; stdcall;
var
  Obj: TMqttClient;
begin
  Obj := TMqttClient(lpParameter);
  Windows.InterlockedIncrement(Obj.FRunThreadRefCount);
  try
    Obj.ReadDataInThread();
  finally
    Windows.InterlockedDecrement(Obj.FRunThreadRefCount);
  end;
  Result := 0;
end;

procedure TMqttClient.mqttConnect();
begin
  FDisConnectRefCount := 0;
  Lock();
  try
    FSendStream.Position := 0;
    MakeMqttConnectData();
    try
      TCP.SendBuf(FSendStream.Memory, FSendStream.Position);
      //启动消息接收线程
      QueueUserWorkItem(ThreadProc_Mqtt_Read, Pointer(Self), WT_EXECUTELONGFUNCTION);
    except
      on E: Exception do
      begin
        TCP.Disconnect();
        SetErrDesc(E.Message);
        PostThreadMessageEh(FIocpThreadId, WM_MQTT_DISCONNECT, 0, 0);
      end;
    end;
  finally
    UnLock();
  end;
  //
end;
const
  Success_Result = '<Result><MsgID>@MsgID@</MsgID><Code>1</Code><Info>成功</Info></Result>';
  Success_Info = '<Result><MsgID>@MsgID@</MsgID><Code>1</Code><Info>@Info@</Info></Result>';
  Fail_Result = '<Result><MsgID>@MsgID@</MsgID><Code>0</Code><Info>@Info@</Info></Result>';

procedure TMQTTClient.OnPrePublish(Sender: TObject; const msg: TRecvPublishMessage);
var
  Text,MsgID: string;
  OutValue: string;
  Log: string;
begin
  {if cb_utf8.Checked then
     MsgContent := Utf8ToAnsi(msg.MsgContent)
  else
  MsgContent := UTF8Decode(msg.MsgContent);   }
  Text := format('OnPublish,Dup=%s,Qos=%d,MsgID[%d],Retain[%s],Topic=%s,payload=%s',
    [BoolToStr(msg.Dup, TRUE), Integer(msg.Qos), msg.MsgID, BoolToStr(msg.Retain,
    TRUE), msg.topic, msg.MsgContent]);
  if msg.MsgContent <> '' then
  begin
    try
      try
        MsgID := Copy(msg.MsgContent,Pos('<MsgID>', msg.MsgContent)+7,
          Pos('</MsgID>',msg.MsgContent)-Pos('<MsgID>', msg.MsgContent)-7);
        if not Execute(msg.MsgContent, OutValue) then
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
          OutValue := '服务器运行出错:' + e.Message;
          OutValue := stringreplace(Fail_Result, '@Info@', OutValue, []);
        end;
      end;
    finally
      OutValue := stringreplace(OutValue, '@MsgID@', MsgID, []);
      Publish(PubTopic, UTF8Encode(OutValue), MQ.Qos, MQ.Retain);
      Log := Text + #13#10 + OutValue;
      if POS('<Code>0</Code>', OutValue) > 0 then
        PostLog(llError,Log)
      else
        PostLog(llmessage,Log)
    end;
  end;
end;

procedure TMqttClient.ReadDataInThread;
var
  iRet: Integer;
  ErrOccur: Boolean;
begin
//  iRet := 0;
  ErrOccur := FALSE;
  while (TCP.Connected and (not ErrOccur) and (not FTerminal)) do
  begin
    try
      iRet := TCP.WaitForData(10);
      if iRet = 0 then //对方优雅关闭了连接
        raise Exception.CreateFmt('%s.ReadDataInThread(),ERROR_GRACEFUL_DISCONNECT',
          [ClassName]);
      InnerRead();
    except
      on E: Exception do
      begin
        ErrOccur := TRUE;
        SetErrDesc(E.Message);
      end;
    end;
    if UserCancelSocket then
      Break;
  end;
  //
  if FTerminal then
  begin
    Exit;
  end;
  //
  TCP.Disconnect();
  PostThreadMessageEh(FIocpThreadId, WM_MQTT_DISCONNECT, 0, 0); //关闭通知
end;

procedure TMqttClient.InnerRead;
var
  Buf: array[1..8192] of Byte;
  iRet: Integer;
  FH: TMQTTFixedHeader;
label
  lable_begin;
begin
  iRet := TCP.ReceiveBuf(@Buf, SizeOf(Buf));
  FRecvStream.Write(Buf, iRet);
  //
lable_begin:
  if FRecvStream.Position = 0 then
    Exit;
  iRet := ParseMQTTFixedHeader(FRecvStream.Memory, FRecvStream.Position, FH);
  if iRet = 0 then
  begin
    //数据不足
    Exit;
  end;
  //
  if FH.MessageType = CONNACK then
  begin
    if FRecvStream.Position < 3 then
    begin
      Exit; //数据不足
    end;
    Process_CONNACK(FH);
    goto lable_begin;
    Exit;
  end;
  //
  if FH.MessageType = PUBACK then
  begin
    if Process_PUBACK(FH) = 1 then
      goto lable_begin;
    Exit;
  end;
  //
  if FH.MessageType = PUBREC then
  begin
    if Process_PUBREC(FH) = 1 then
      goto lable_begin;
    Exit;
  end;
  //
  if FH.MessageType = PUBREL then
  begin
    if Process_PUBREL(FH) = 1 then
      goto lable_begin;
    Exit;
  end;
  //
  if FH.MessageType = PUBCOMP then
  begin
    if Process_PUBCOMP(FH) = 1 then
      goto lable_begin;
    Exit;
  end;
  //
  if FH.MessageType = SUBACK then
  begin
    if Process_SUBACK(FH) = 1 then
      goto lable_begin;
    Exit;
  end;
  //
  if FH.MessageType = mqttPUBLISH then
  begin
    if Process_PUBLISH(FH) = 1 then
      goto lable_begin;
    Exit;
  end;
  //
  if FH.MessageType = PINGRESP then
  begin
    if Process_PingResp() = 1 then
      goto lable_begin;
    Exit;
  end;

  if FH.MessageType = UNSUBACK then
  begin
    if Process_UNSUBACK(FH) = 1 then
      goto lable_begin;
    Exit;
  end;
end;

function ThreadProc_AutoPing(lpParameter: Pointer): Integer; stdcall;
var
  obj: TMqttClient;
begin
  obj := TMqttClient(lpParameter);
  Windows.InterlockedIncrement(obj.FRunThreadRefCount);
  try
    obj.AutoPingReqProc();
  finally
    Windows.InterlockedDecrement(obj.FRunThreadRefCount);
  end;
  Result := 0;
end;

function TMQTTClient.Process_CONNACK(const FH: TMQTTFixedHeader): integer;
var
  V2: Byte;
  Sp: PByte;
  H: array[1..4] of Byte;
begin
  Sp := FRecvStream.Memory;
  Move(Sp^, H, 4);
  V2 := H[4];
  //
  if not FTerminal then
  begin
    FmqttConnected := (V2 = 0);
  end;
  //
  if (not FTerminal) and Assigned(OnFConnAck) then
  begin
    OnFConnAck(Self, V2);
  end;
  //
  TranData(FRecvStream, 4);
  //
  if (not FTerminal) and AutoPing then
  begin
    StartAutoPing(Self.PingInterval); //自动发送心跳包(间隔5秒)
  end;
  //
  Result := 1;
end;

//Publish and Qos=1 时触发
function TMQTTClient.Process_PUBACK(const FH: TMQTTFixedHeader): Integer;
var
  MsgId: Word;
begin
  if FRecvStream.Position < 4 then
  begin
    Result := 0; //数据不足
    Exit;
  end;

  FRecvStream.Position := 2;
  //
  FRecvStream.Read(MsgId, 2);
  MsgId := WinSock.ntohs(MsgId);
  //
  if (not FTerminal) and Assigned(OnPubAck) then
  begin
    OnPubAck(Self, MsgId);
  end;
  //
  TranData(FRecvStream, 4);
  //
  Result := 1;
end;

function TMQTTClient.Process_SUBACK(const FH: TMQTTFixedHeader): Integer;
var
  MsgId: Word;
  B: Byte;
  QosEx: Integer;
begin
  if FRecvStream.Position < 5 then
  begin
    Result := 0; //数据不足
    Exit;
  end;

  FRecvStream.Position := 2;
  //
  FRecvStream.Read(MsgId, 2);
  MsgId := WinSock.ntohs(MsgId);
  //
  FRecvStream.Read(B, 1);
  QosEx := B;

  if (not FTerminal) and Assigned(onSubAck) then
  begin
    onSubAck(Self, MsgId, QosEx);
  end;
  //
  TranData(FRecvStream, 5);
  //
  Result := 1;
end;

function TMQTTClient.Process_PUBLISH(const FH: TMQTTFixedHeader): Integer;
var
  V2: Byte;
  B: Byte;
  RL: DWORD;
  bNext: Boolean;
  RecvMsg: TRecvPublishMessage;
  W: Word;
  MsgLen: DWORD;
  SavedPosition: int64;
begin
  Result := 0;
  RL := 0;
  V2 := 0;
  SavedPosition := FRecvStream.Position;
  FRecvStream.Position := 1;
  while (TRUE) do
  begin
    //(1)
    V2 := 1;
    if FRecvStream.Read(B, 1) = 0 then
      Exit; //数据不足
    bNext := (B and $80) = $80;
    RL := RL + (B and $7F) * 1;
    if not bNext then
      Break;
    //(2)
    V2 := 2;
    if FRecvStream.Read(B, 1) = 0 then
      Exit;
    bNext := (B and $80) = $80;
    RL := RL + (B and $7F) * 128;
    if not bNext then
      Break;
    //(3)
    V2 := 3;
    if FRecvStream.Read(B, 1) = 0 then
      Exit;
    bNext := (B and $80) = $80;
    RL := RL + (B and $7F) * 16384;
    if not bNext then
      break;
    //(4)
    V2 := 4;
    if FRecvStream.Read(B, 1) = 0 then
      Exit;
    RL := RL + (B and $7F) * 2097152;
    Break;
  end;
  //
  if SavedPosition < RL + (1 + V2){FixedHeadr} then
  begin
    FRecvStream.Position := SavedPosition;
    Exit; //数据不足
  end;

  RecvMsg.Dup := FH.Dup;
  RecvMsg.Qos := TQosLevel(FH.Qos);
  RecvMsg.Retain := FH.Retain;

  MsgLen := RL;
  //Topic
  FRecvStream.Read(W, 2);
  W := WinSock.ntohs(W);
  Dec(MsgLen, 2);
  SetLength(RecvMsg.Topic, W);
  FRecvStream.Read(RecvMsg.Topic[1], W);
  Dec(MsgLen, W);

  if RecvMsg.Qos <> Qos0 then //MsgId
  begin
    FRecvStream.Read(W, 2);
    RecvMsg.MsgId := WinSock.ntohs(W);
    Dec(MsgLen, 2);
  end;

   //MsgContent;
  SetLength(RecvMsg.MsgContent, MsgLen);
  FRecvStream.Read(RecvMsg.MsgContent[1], MsgLen);
   //
  if FTerminal then
  begin
    Exit;
  end;

  if Assigned(OnPublish) then
  begin
    OnPublish(Self, RecvMsg);
  end;

   //发送确认
  case RecvMsg.Qos of
    Qos0:
      begin
             //DoNothing
      end;
    Qos1:
      begin
        AckPublish_Qos1(RecvMsg.MsgId); //PubAck
      end;
    Qos2:
      begin
        AckPublish_Qos2(RecvMsg.MsgId); //PUBREC
      end;
  end;
   //
  FRecvStream.Position := SavedPosition;
  TranData(FRecvStream, RL + (1 + V2));
  Result := 1;
end;

function TMQTTClient.Publish(ATopic, AMsgContent: AnsiString; Qos: TQosLevel;
  Reatin: Boolean): Integer;
var
  MsgId: Word;
begin
  if not MQ.BMQTT then
    Exit;
  if Length(ATopic) = 0 then
    ATopic := MQ.SubTopic;
  Qos := MQ.Qos;
  Reatin := MQ.ReTain;
  Lock();
  try
    FSendStream.Position := 0;
    MakeMqttPublishData(ATopic, AMsgContent, false, Qos, Reatin, MsgId);
    try
      TCP.SendBuf(FSendStream.Memory, FSendStream.Position);
    except
      on E: Exception do
      begin
        TCP.Disconnect();
        SetErrDesc(E.Message);
        PostThreadMessageEh(FIocpThreadId, WM_MQTT_DISCONNECT, 0, 0);
      end;
    end;
  finally
    UnLock();
  end;
  Result := 0;
end;

procedure TMQTTClient.MakeMqttPublishData(const ATopic, AMsgContent: AnsiString;
  Dup: Boolean; Qos: TQosLevel; Retain: Boolean; var MsgId: Word);
  //

  function GetVariableHeadSize(): Integer;
  begin
    Result := (2 + Length(ATopic)) + Length(AMsgContent);
    if Qos <> Qos0 then
    begin
      Result := Result + 2; //MsgId
    end;
  end;

var
  B: Byte;
  W: Word;
  wDup: Word;
  wRetain: Word;
  wQos: Word;
  RlBytes: TmqttBytes;
  IntV: Integer;
begin
  //FixHeader(1)
  if Dup then
    wDup := 1
  else
    wDup := 0;
  if Qos = Qos0 then
    wDup := 0;
  wQos := Word(Qos);
  if Retain then
    wRetain := 1
  else
    wRetain := 0;
  //
  B := FixedHeader(mqttPUBLISH, wDup, wQos, wRetain);
  FSendStream.Write(B, 1);
  //
  IntV := GetVariableHeadSize();
  RlBytes := RLIntToBytes(IntV);
  FSendStream.Write(RlBytes[0], Length(RlBytes));
  //
  //Topic
  W := Length(ATopic);
  W := WinSock.htons(W);
  FSendStream.Write(W, 2);
  FSendStream.Write(ATopic[1], Length(ATopic));
  if Qos <> Qos0 then
  begin
    MsgId := FMsgId;
    FMsgId := FMsgId + 1;
    W := WinSock.htons(MsgId);
    FSendStream.Write(W, 2);
  end;
  //MsgContent
  FSendStream.Write(AMsgContent[1], Length(AMsgContent));
end;

function TMQTTClient.SubScribe(ATopic: AnsiString; Qos: TQosLevel): Integer;
begin
  if not MQ.BMQTT then
    Exit;
  if Length(ATopic) = 0 then
    ATopic := MQ.SubTopic;
  if (Length(ATopic) > 65535) or (Length(ATopic) = 0) then
    raise Exception.CreateFmt('%s.SubScribe() ATopic 长度[%d]必须在 1..65535 之间', [ClassName,
      Length(ATopic)]);
  Lock();
  try
    FSendStream.Position := 0;
    Inc(FMsgId);
    MakeMqttSubScribeData(ATopic, Qos, FMsgId);
    try
      TCP.SendBuf(FSendStream.Memory, FSendStream.Position);
    except
      on E: Exception do
      begin
        TCP.Disconnect();
        SetErrDesc(E.Message);
        PostThreadMessageEh(FIocpThreadId, WM_MQTT_DISCONNECT, 0, 0);
      end;
    end;
  finally
    UnLock();
  end;
  Result := 0;
end;

function TMQTTClient.UnSubscribe(ATopic: AnsiString): Integer;
begin
  if not MQ.BMQTT then
    Exit;
  if Length(ATopic) = 0 then
    ATopic := MQ.SubTopic;
  Lock();
  try
    FSendStream.Position := 0;
    Inc(FMsgId);
    MakeMqttUnSubScribeData(ATopic, FMsgId);
    try
      TCP.SendBuf(FSendStream.Memory, FSendStream.Position);
    except
      on E: Exception do
      begin
        TCP.Disconnect();
        SetErrDesc(E.Message);
        PostThreadMessageEh(FIocpThreadId, WM_MQTT_DISCONNECT, 0, 0);
      end;
    end;
  finally
    UnLock();
  end;
  Result := 0;
end;
//

procedure TMQTTClient.MakeMqttSubScribeData(const ATopic: AnsiString; Qos:
  TQosLevel; MsgId: Word);

  function GetVariableHeadSize(): Integer;
  begin
    Result := 2 +  //MsgId
      2 + Length(ATopic) + //Topic
      1; //Qos
  end;

var
  B: Byte;
  W: Word;
  RlBytes: TmqttBytes;
  IntV: Integer;
begin
  //FixHeader(1)
  B := $82; //
  FSendStream.Write(B, 1);
  //
  IntV := GetVariableHeadSize();
  RlBytes := RLIntToBytes(IntV);
  FSendStream.Write(RlBytes[0], Length(RlBytes));
  //
  W := WinSock.htons(MsgId);
  FSendStream.Write(W, 2);

  //Topic
  W := Length(ATopic);
  W := WinSock.htons(W);
  FSendStream.Write(W, 2);
  FSendStream.Write(ATopic[1], Length(ATopic));

  //Qos
  B := Byte(Qos);
  FSendStream.Write(B, 1);
end;

procedure TMQTTClient.MakeMqttUnSubScribeData(const ATopic: AnsiString; MsgId: Word);

  function GetVariableHeadSize(): Integer;
  begin
    Result := 2 +  //MsgId
      2 + Length(ATopic); //Topic
  end;

var
  B: Byte;
  W: Word;
  RlBytes: TmqttBytes;
  IntV: Integer;
begin
  //FixHeader(1)
  B := $A2; //
  FSendStream.Write(B, 1);
  //
  IntV := GetVariableHeadSize();
  RlBytes := RLIntToBytes(IntV);
  FSendStream.Write(RlBytes[0], Length(RlBytes));
  //
  W := WinSock.htons(MsgId);
  FSendStream.Write(W, 2);

  //Topic
  W := Length(ATopic);
  W := WinSock.htons(W);
  FSendStream.Write(W, 2);
  FSendStream.Write(ATopic[1], Length(ATopic));

end;

procedure TMQTTClient.MakeMqttPingReqData;
var
  B: Byte;
begin
  //FixHeader(1)
  B := FixedHeader(mqttPINGREQ, 0, 0, 0);
  FSendStream.Write(B, 1);
  B := 0;
  FSendStream.Write(B, 1);
end;

function TMQTTClient.PingReq: Integer;
begin
  Lock();
  try
    FSendStream.Position := 0;
    MakeMqttPingReqData();
    try
      TCP.SendBuf(FSendStream.Memory, FSendStream.Position);
    except
      on E: Exception do
      begin
        TCP.Disconnect();
        SetErrDesc(E.Message);
      end;
    end;
  finally
    UnLock();
  end;
  Result := 0;
end;

function TMQTTClient.Process_PingResp: Integer;
begin
  if FRecvStream.Position < 2 then
  begin
    Result := 0;
    Exit;
  end;
  if Assigned(OnPingResp) then
  begin
    OnPingResp(Self);
  end;
  //
  TranData(FRecvStream, 2);
  Result := 1;
end;

procedure TMQTTClient.DisConnect();
begin
  Lock();
  try
    if TCP.Connected then
    begin
      FSendStream.Position := 0;
      MakeMqttDisConnectData();
      TCP.SendBuf(FSendStream.Memory, FSendStream.Position);
      FUserCancelSocket := TRUE;
      TCP.Disconnect();
    end;
    PostThreadMessageEh(FIocpThreadId, WM_MQTT_DISCONNECT, 0, 0);
  finally
    UnLock();
  end;
end;

function TMQTTClient.Execute(InValue: string; out OutValue: string): Boolean;
var
  YxDSvr: TYxDSvr;
begin
  Result := False;
  OutValue := '';
  try
    YxDSvr := TYxDSvr.Create(nil);
    try
      with  YxDSvr do
      begin
        if not HelloWorld then
          OutValue :=  FError
        else
          OutValue := FRet;
      end;
    finally
      freeandnil(YxDSvr);
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

procedure TMQTTClient.MakeMqttDisConnectData;
var
  B: Byte;
begin
  //FixHeader(1)
  B := FixedHeader(mqttDISCONNECT, 0, 0, 0);
  FSendStream.Write(B, 1);
  B := 0;
  FSendStream.Write(B, 1);
end;

procedure TMQTTClient.Lock;
begin
  EnterCriticalSection(FCS);
end;

procedure TMQTTClient.UnLock;
begin
  LeaveCriticalSection(FCS);
end;

procedure TMQTTClient.AckPubCompToServer(MsgId: Word);
var
  H: array[1..2] of Byte;
  W: Word;
begin
  H[1] := $70; //PUBCOMP报文固定报头
  H[2] := $02;
  W := WinSock.htons(MsgId);
  Lock();
  try
    TCP.SendBuf(@H, 2);
    TCP.SendBuf(@W, 2);
  finally
    UnLock();
  end;
end;

procedure TMQTTClient.AckPublish_Qos1(MsgId: Word);
var
  H: array[1..2] of Byte;
  W: Word;
begin
  H[1] := $40;
  H[2] := $02;
  W := WinSock.htons(MsgId);
  Lock();
  try
    TCP.SendBuf(@H, 2);
    TCP.SendBuf(@W, 2);
  finally
    UnLock();
  end;
end;

function TMQTTClient.GetErrDesc: string;
begin
  EnterCriticalSection(FstrCS);
  try
    Result := StrPas(PAnsichar(@FErrDesc));
  finally
    LeaveCriticalSection(FstrCS);
  end;
end;

procedure TMQTTClient.SetErrDesc(const Msg: AnsiString);
var
  L: integer;
begin
  EnterCriticalSection(FstrCS);
  try
    L := Length(Msg);
    if L > (SizeOf(FErrDesc) - 1) then
      Dec(L);
    ZeroMemory(@FErrDesc, SizeOf(FErrDesc));
    Move(Msg[1], FErrDesc[1], L);
  finally
    LeaveCriticalSection(FstrCS);
  end;
end;

procedure TMQTTClient.StartAutoPing(Interval: Word);
begin
  Lock();
  try
    if not FAutoPingRuning then
    begin
      FAutoPingInterval := Interval;
      if FAutoPingInterval = 0 then
        FAutoPingInterval := 5;
      QueueUserWorkItem(ThreadProc_AutoPing, Pointer(Self), WT_EXECUTELONGFUNCTION);
      FAutoPingRuning := TRUE;
    end;
  finally
    UnLock();
  end;
end;

procedure TMQTTClient.AutoPingReqProc;
var
  Delay: Integer;
begin
  FAutoPingRuning := TRUE;
  try
    while (TCP.Connected and AutoPing and (not FTerminal)) do
    begin
      Delay := FAutoPingInterval * 1000;
      while (TCP.Connected and AutoPing and (not FTerminal) and (Delay > 0)) do
      begin
        Sleep(10);
        Dec(Delay, 10);
      end;
      if TCP.Connected and AutoPing and (not FTerminal) then
        PingReq();
    end;
  finally
    FAutoPingRuning := FALSE;
  end;
end;

function TMQTTClient.GetCurrentMsgId: Word;
begin
  lock();
  Result := FMsgId;
  UnLock();
end;

function TMQTTClient.Process_UNSUBACK(const FH: TMQTTFixedHeader): Integer;
var
  MsgId: Word;
begin
  if FRecvStream.Position < 4 then
  begin
    Result := 0; //数据不足
    Exit;
  end;

  FRecvStream.Position := 2;
  //
  FRecvStream.Read(MsgId, 2);
  MsgId := WinSock.ntohs(MsgId);
  //
  if (not FTerminal) and Assigned(OnUnSubAck) then
  begin
    OnUnSubAck(Self, MsgId);
  end;
  //
  TranData(FRecvStream, 4);
  //
  Result := 1;
end;

procedure TMQTTClient.WndProc;
var
  _Msg: tagMsg;
  DelayMill: Integer;
begin
  FIocpThreadId := GetCurrentThreadID();
  //
  while (not FTerminal) do
  begin
    if not PeekMessage(_Msg, 0, WM_USER, WM_USER + 1100, PM_REMOVE) then
    begin
      Sleep(10);
      Continue;
    end;
    //
    if _Msg.message = WM_MQTT_SOCKET_CONNECT then
    begin
      SetErrDesc('');
      FDisConnectRefCount := 0;
      //
      try
        InnerConnect();
      except
        on E: Exception do
        begin
          SetErrDesc(E.Message);
          TCP.Disconnect();
          PostThreadMessageEh(Self.FIocpThreadId, WM_MQTT_DISCONNECT, 0, 0);
        end;
      end;
    end;
    //
    if _Msg.message = WM_MQTT_DISCONNECT then
    begin
      FmqttConnected := FALSE;
      if Assigned(OnDisConnect) and (FDisConnectRefCount = 0) then
      begin
        FDisConnectRefCount := 1;
        OnDisConnect(Self);
        if AutoReConnect then
        begin
          DelayMill := AutoReConnectDelaySec * 1000; //转换到毫秒
          if DelayMill <= 0 then
            DelayMill := 1000;

          while ((not FTerminal) and (DelayMill > 0)) do
          begin
            Sleep(10);
            Dec(DelayMill, 10);
          end;
          if FTerminal then
            Break;
          //
          PostThreadMessageEh(FIocpThreadId, WM_MQTT_SOCKET_CONNECT, 0, 0);
          Continue;
        end;
      end;
    end;
    //\\
  end; //while_end

end;

procedure TMQTTClient.PostThreadMessageEh(ThreadID, Msg: DWORD; WParam, LParam:
  TNativeInt);
begin
  while (not PostThreadMessage(ThreadID, Msg, WParam, LParam)) do
    Sleep(5);
end;

function TMQTTClient.CalcConnectRemainingLength(): Integer;
const
  //3.1.1
  MQTT_PROTOCOL: AnsiString = 'MQTT';
  MQTT_VERSION: Byte = 4;
  //3.1
  //MQTT_PROTOCOL:AnsiString='MQIsdp';
  //MQTT_VERSION=3;
var
  B: Byte;
  W: Word;
  Flag: Byte;
  LvClientID: AnsiString;
  VS: TVirtualStream;
begin
//  Result := 0;
  VS := TVirtualStream.Create();

  //FixHeader(1)
  //B := FixedHeader(mqCONNECT,0,0,0);
  //VS.Write(B,1);
  //FixHeader(2)
  //W := 0;
  //VS.Write(W,1);//占位符
  //ProtocolName
  W := WinSock.htons(Length(MQTT_PROTOCOL));
  VS.Write(W, 2);
  VS.Write(MQTT_PROTOCOL[1], Length(MQTT_PROTOCOL));

  //ProtocolVersion
  B := MQTT_VERSION;
  VS.Write(B, 1);

  //ConnectFlags
  (*
     UserName(7)        $80
     PassWord(6)        $40
     Will Retain(5)  X  $20
     Will QoS(4-3)   X  $00(Qos0),$08(Qos1),$10(Qos2)
     Will Flag(2)    X  $04
     CleanSession(1) X  $02
     Reserved(0)     X  $00
  *)
  Flag := $00;
  if ClearSession then
    Flag := Flag or $02;
  if Length(UserName) > 0 then
    Flag := Flag or $80;
  if Length(PassWord) > 0 then
    Flag := Flag or $40;
  if WillFlag then
  begin
    Flag := Flag or $04;
    case WillQos of
      Qos0:
        Flag := Flag or $00;
      Qos1:
        Flag := Flag or $08;
      Qos2:
        Flag := Flag or $10;
    end;
    if WillRetain then
      Flag := Flag or $20;
  end;
  VS.Write(Flag, 1);

  //KeepAlive timer
  W := WinSock.htons(KeepAliveTimer);
  VS.Write(W, 2);

  //ClientID
  LvClientID := ClientID;
  W := Length(LvClientID);
  W := WinSock.htons(W);
  VS.Write(W, 2);
  VS.Write(ClientID[1], Length(ClientID));

  if WillFlag then
  begin
    //WillTopic
    W := WinSock.htons(Length(WillTopic));
    VS.Write(W, 2);
    VS.Write(WillTopic[1], Length(WillTopic));
    //WillMessage
    W := WinSock.htons(Length(WillMessage));
    VS.Write(W, 2);
    VS.Write(WillMessage[1], Length(WillMessage));
  end;

  //UserName
  if Length(UserName) > 0 then
  begin
    W := WinSock.htons(Length(Self.UserName));
    VS.Write(W, 2);
    VS.Write(Self.UserName[1], Length(Self.UserName));
  end;

  //PassWord
  if Length(Self.PassWord) > 0 then
  begin
    W := WinSock.htons(Length(Self.PassWord));
    VS.Write(W, 2);
    VS.Write(Self.PassWord[1], Length(Self.PassWord));
  end;
  //
  Result := VS.Position;
  VS.Free();
  //
end;

procedure TMQTTClient.Connect();
begin
  if Connected then
  begin
    Exit;
  end;
  ConnectParameterCheck();
  FTerminal := FALSE;
  PostThreadMessageEh(FIocpThreadId, WM_MQTT_SOCKET_CONNECT, 0, 0);
end;

procedure TMQTTClient.ConnectParameterCheck;
begin
  if Length(ClientID) > 23 then
    raise Exception.Create('ClientID 长度必须小于23');
  //
  if Length(FUserName) > 1024 * 64 then
    raise Exception.Create('UserName 长度必须小于 65535');
  //
  if Length(PassWord) > 1024 * 64 then
    raise Exception.Create('PassWord 长度必须小于 65535');

end;

procedure TMQTTClient.InnerConnect();
begin
  try
    SocketConnect(TcpAddr, ConnectTimeOutSec * 1000);
  except
    on E: Exception do
    begin
      SetErrDesc(E.Message);
      if Assigned(OnSocketConnect) then
        OnSocketConnect(Self, FALSE);
      raise;
    end;
  end;
  //
  if (not FTerminal) and TCP.Connected then
  begin
    if Assigned(OnSocketConnect) then
      OnSocketConnect(Self, TRUE);
    mqttConnect();
  end;

end;

function TMQTTClient.GetMqttSocket: TMqttSocket;
begin
  Result := FTCP;
end;

function TMQTTClient.Process_PUBREC(const FH: TMQTTFixedHeader): Integer;
var
  MsgId: Word;
begin
  if FRecvStream.Position < 4 then
  begin
    Result := 0; //数据不足
    Exit;
  end;

  FRecvStream.Position := 2;
  //
  FRecvStream.Read(MsgId, 2);
  MsgId := WinSock.ntohs(MsgId);
  //
  if (not FTerminal) and Assigned(OnPubRec) then
  begin
    OnPubRec(Self, MsgId);
  end;
  //
  //发送确认(PUBREL)-->服务器端
  if (not FTerminal) then
  begin
    AckPubRecToServer(MsgId);
  end;
  //
  TranData(FRecvStream, 4);
  //
  Result := 1;
end;

function TMQTTClient.Process_PUBREL(const FH: TMQTTFixedHeader): Integer;
var
  MsgId: Word;
begin
  if FRecvStream.Position < 4 then
  begin
    Result := 0; //数据不足
    Exit;
  end;

  FRecvStream.Position := 2;
  //
  FRecvStream.Read(MsgId, 2);
  MsgId := WinSock.ntohs(MsgId);
  //
  if (not FTerminal) and Assigned(OnPubRel) then
  begin
    OnPubRel(Self, MsgId);
  end;
  //
  if not FTerminal then
  begin
    AckPubCompToServer(MsgId);
  end;

  TranData(FRecvStream, 4);
  //
  Result := 1;
end;

function TMQTTClient.Process_PUBCOMP(const FH: TMQTTFixedHeader): Integer;
var
  MsgId: Word;
begin
  if FRecvStream.Position < 4 then
  begin
    Result := 0; //数据不足
    Exit;
  end;

  FRecvStream.Position := 2;
  //
  FRecvStream.Read(MsgId, 2);
  MsgId := WinSock.ntohs(MsgId);
  //
  if (not FTerminal) and Assigned(OnPUbComp) then
  begin
    OnPUbComp(Self, MsgId);
  end;
  //
  TranData(FRecvStream, 4);
  //
  Result := 1;
end;

procedure TMQTTClient.AckPubRecToServer(MsgId: Word);
var
  H: array[1..2] of Byte;
  W: Word;
begin
  H[1] := $62; //PUBREL报文固定报头
  H[2] := $02;
  W := WinSock.htons(MsgId);
  Lock();
  try
    TCP.SendBuf(@H, 2);
    TCP.SendBuf(@W, 2);
  finally
    UnLock();
  end;
end;

procedure TMQTTClient.AckPublish_Qos2(MsgId: Word);
var
  H: array[1..2] of Byte;
  W: Word;
begin
  H[1] := $50; //PUBREC – 发布收到（QoS 2，第一步）
  H[2] := $02;
  W := WinSock.htons(MsgId);
  Lock();
  try
    TCP.SendBuf(@H, 2);
    TCP.SendBuf(@W, 2);
  finally
    UnLock();
  end;
end;

function TMQTTClient.GetClientID: AnsiString;
begin
  EnterCriticalSection(FstrCS);
  try
    Result := FClientID;
  finally
    LeaveCriticalSection(FstrCS);
  end;
end;

procedure TMQTTClient.SetClientID(const Value: AnsiString);
begin
  EnterCriticalSection(FstrCS);
  try
    FClientID := Value;
  finally
    LeaveCriticalSection(FstrCS);
  end;
end;

{TMqttSocket}

procedure TMqttSocket.Connect(const ATimeOut: Integer);

  procedure FD_SET(Socket: TSocket; var FDSet: TFDSet);
  begin
    if FDSet.fd_count < FD_SETSIZE then
    begin
      FDSet.fd_array[FDSet.fd_count] := Socket;
      Inc(FDSet.fd_count);
    end;
  end;

  procedure FD_ZERO(var FDSet: TFDSet);
  begin
    FDSet.fd_count := 0;
  end;

var
  iRet, ul: Integer;
  strErr: string;
  FWSAddr: SockAddr_in;
  TimeOut: TTimeVal;
  FDSet: TFDSet;
  LHost: Ansistring;
begin
  if FConnected then
    Exit;

  FErrorCode := 0;

  if FSocket = INVALID_SOCKET then
  begin
    FSocket := Socket(AF_INET, SOCK_STREAM, 0);
    if FSocket = INVALID_SOCKET then
      RaiseWSExcption();
  end;

  ZeroMemory(@FWSAddr, SizeOf(FWSAddr));
  FWSAddr.sin_family := AF_INET;
  LHost := ResolveIP(Host);
  if LHost = '' then
    raise Exception.CreateFmt('<%s.Connect>.ResolveIP Failure Host "%s:%d"', [ClassName,
      Host, Port]);
  FWSAddr.sin_addr.S_addr := inet_addr(PAnsiChar(LHost));
  FWSAddr.sin_port := htons(Port);
  if ATimeOut > 0 then
  begin
    //设置非阻塞方式连接
    ul := 1;
    iRet := ioctlsocket(HSocket, FIONBIO, ul);
    if (iRet = SOCKET_ERROR) then
    begin
      iRet := WSAGetLastError();
      strErr := GetLastErrorErrorMessage(iRet);
      CloseSocket(FSocket);
      FSocket := INVALID_SOCKET;
      raise exception.CreateFmt('%s Connect [1] socket error %d  %s', [ClassName,
        iRet, strErr]);
    end;

    iRet := Winsock.connect(FSocket, TSockAddr(FWSAddr), SizeOf(FWSAddr));
    if iRet = SOCKET_ERROR then
    begin
      iRet := WSAGetLastError();
      if iRet <> WSAEWOULDBLOCK then
      begin
        strErr := GetLastErrorErrorMessage(iRet);
        CloseSocket(FSocket);
        FSocket := INVALID_SOCKET;
        raise exception.CreateFmt('%s Connect socket [2] error %d  %s', [ClassName,
          iRet, strErr]);
      end;
    end;

    //select 模型，即设置超时
    TimeOut.tv_sec := ATimeOut div 1000;
    TimeOut.tv_usec := ATimeOut mod 1000;
    FD_ZERO(FDSet);
    FD_SET(FSocket, FDSet);
    iRet := select(0, nil, @FDSet, nil, @TimeOut);
    if iRet = 0 then //超时
    begin
      CloseSocket(FSocket);
      FSocket := INVALID_SOCKET;
      raise exception.CreateFmt('%s.Connect TimeOut[%d],Host[%s:%d],ErrCode=%d',
        [ClassName, ATimeOut, Host, Port, WSAGetLastError()]);
    end;
    //一般非锁定模式套接比较难控制，可以根据实际情况考虑 再设回阻塞模式
    ul := 0;
    iRet := ioctlsocket(FSocket, FIONBIO, ul);
    if (iRet = SOCKET_ERROR) then
    begin
      iRet := WSAGetLastError();
      strErr := GetLastErrorErrorMessage(iRet);
      CloseSocket(FSocket);
      FSocket := INVALID_SOCKET;
      raise exception.CreateFmt('%s Connect socket [3] error %d  %s', [ClassName,
        iRet, strErr]);
    end;
  end
  else
  begin
    iRet := Winsock.connect(FSocket, TSockAddr(FWSAddr), SizeOf(FWSAddr));
    if iRet = SOCKET_ERROR then
    begin
      iRet := WSAGetLastError();
      strErr := GetLastErrorErrorMessage(iRet);
      CloseSocket(FSocket);
      FSocket := INVALID_SOCKET;
      raise exception.CreateFmt('%s Connect socket [4] error %d  %s', [ClassName,
        iRet, strErr]);
    end;
  end;
  FConnected := TRUE;
end;

constructor TMqttSocket.Create;
begin
  inherited Create();
  FConnected := FALSE;
  FSocket := INVALID_SOCKET;
  FInputStream := TRedisStreamEh.Create();
  FInputStream.Size := SF_SOCKET_BUFF_SIZE;
  windows.ZeroMemory(FInputStream.Memory, FInputStream.Size);
  FInputStream.Position := 0;
  FInputStream.ReadEndPosition := 0;

  FRecvTimeOut := 10 * 1000; //读超时,默认10秒
  InitSocket();
end;

destructor TMqttSocket.Destroy;
begin
  Disconnect();
  WSACleanup();
  FInputStream.Free();
  inherited;
end;

function TMqttSocket.GetLastErrorErrorMessage(ErrCode: Integer): string;
var
  ErrorMessage: Pointer;      // holds a system error string
begin
  Windows.FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER or
    FORMAT_MESSAGE_FROM_SYSTEM, nil, ErrCode, 0, @ErrorMessage, 0, nil);
  Result := string(PChar(ErrorMessage));
  Windows.LocalFree(hlocal(ErrorMessage))
end;

function TMqttSocket.getNagle: Boolean;
var
  iRet: Integer;
begin
  iRet := SizeOf(Result);
  if Getsockopt(FSocket, IPPROTO_TCP, TCP_NODELAY, PAnsichar(@Result), iRet) =
    SOCKET_ERROR then
  begin
    iRet := WSAGetLastError();
    raise Exception.CreateFmt('getNagle SocketError %d', [iRet]);
  end;
end;

procedure TMqttSocket.InitSocket;
var
  iRet: Integer;
  ErrStr: string;
begin
  iRet := WSAStartup($0002, FwsaData);
  if iRet <> 0 then
  begin
    ErrStr := GetLastErrorErrorMessage(WSAGetLastError());
    raise exception.Create(ErrStr);
  end;
  FSocket := Socket(AF_INET, SOCK_STREAM, 0);
  if FSocket = INVALID_SOCKET then
  begin
    RaiseWSExcption();
  end;

  //接收及发送超时，默认为 10秒
  setRecvTimeOut(1000 * 10);

  //发送超时 10秒
  SetSendTimeOut(1000 * 10);

  //默认关掉Nagle TCP_NODELAY
  TcpNoDelay := TRUE;

end;

procedure TMqttSocket.InnerConnect(const RemoteHost: AnsiString; RemotePort:
  Word; const ATimeOut: Integer);

  procedure FD_SET(Socket: TSocket; var FDSet: TFDSet);
  begin
    if FDSet.fd_count < FD_SETSIZE then
    begin
      FDSet.fd_array[FDSet.fd_count] := Socket;
      Inc(FDSet.fd_count);
    end;
  end;

  procedure FD_ZERO(var FDSet: TFDSet);
  begin
    FDSet.fd_count := 0;
  end;

var
  iRet, ul: Integer;
  strErr: string;
  FWSAddr: SockAddr_in;
  TimeOut: TTimeVal;
  FDSet: TFDSet;
begin
  if FSocket = INVALID_SOCKET then
  begin
    FSocket := Socket(AF_INET, SOCK_STREAM, 0);
    if FSocket = INVALID_SOCKET then
      RaiseWSExcption();
  end;

  ZeroMemory(@FWSAddr, SizeOf(FWSAddr));
  FWSAddr.sin_family := AF_INET;
  FWSAddr.sin_addr.S_addr := inet_addr(PAnsiChar(RemoteHost));
  FWSAddr.sin_port := htons(RemotePort);
  if ATimeOut > 0 then
  begin
    //设置非阻塞方式连接
    ul := 1;
    iRet := ioctlsocket(FSocket, FIONBIO, ul);
    if (iRet = SOCKET_ERROR) then
    begin
      iRet := WSAGetLastError();
      strErr := GetLastErrorErrorMessage(iRet);
      raise exception.CreateFmt('%s.Connect [1] socket error %d  %s', [ClassName,
        iRet, strErr]);
    end;

    iRet := Winsock.connect(FSocket, TSockAddr(FWSAddr), SizeOf(FWSAddr));
    if iRet = SOCKET_ERROR then
    begin
      iRet := WSAGetLastError();
      if iRet <> WSAEWOULDBLOCK then
      begin
        strErr := GetLastErrorErrorMessage(iRet);
        raise exception.CreateFmt('%s.Connect socket [2] error %d  %s', [ClassName,
          iRet, strErr]);
      end;
    end;

    //select 模型，即设置超时
    TimeOut.tv_sec := ATimeOut div 1000;
    TimeOut.tv_usec := ATimeOut mod 1000;
    FD_ZERO(FDSet);
    FD_SET(FSocket, FDSet);
    iRet := select(0, nil, @FDSet, nil, @TimeOut);
    if iRet = 0 then //超时
    begin
      CloseSocket(FSocket);
      FSocket := INVALID_SOCKET;
      raise exception.CreateFmt('%s.Connect TimeOut %d,ErrCode=%d', [ClassName,
        ATimeOut, WSAGetLastError()]);
    end;
    //一般非锁定模式套接比较难控制，可以根据实际情况考虑 再设回阻塞模式
    ul := 0;
    iRet := ioctlsocket(FSocket, FIONBIO, ul);
    if (iRet = SOCKET_ERROR) then
    begin
      iRet := WSAGetLastError();
      strErr := GetLastErrorErrorMessage(iRet);
      raise exception.CreateFmt('%s.Connect socket [3] error %d  %s', [ClassName,
        iRet, strErr]);
    end;
  end
  else
  begin
    iRet := Winsock.connect(FSocket, TSockAddr(FWSAddr), SizeOf(FWSAddr));
    if iRet = SOCKET_ERROR then
    begin
      iRet := WSAGetLastError();
      strErr := GetLastErrorErrorMessage(iRet);
      raise exception.CreateFmt('%s.Connect socket [4] error %d  %s', [ClassName,
        iRet, strErr]);
    end;
  end;
  FConnected := TRUE;
end;

procedure TMqttSocket.Disconnect;
var
  Linger: TLinger;
begin
  if FSocket = INVALID_SOCKET then
    Exit;
  Shutdown(FSocket, SD_SEND);
  Linger.l_onoff := 1;
  //Specifies whether a socket should remain open for a
  //specified amount of time after a closesocket function call to enable queued data to be sent.
  Linger.l_linger := 0;
  if Setsockopt(FSocket, SOL_SOCKET, SO_LINGER, @Linger, SizeOf(Linger)) =
    SOCKET_ERROR then
  begin
   // ErrCode := WSAGetLastError();
  end;
  CloseSocket(FSocket);
  FSocket := INVALID_SOCKET;
  FConnected := FALSE;
  FInputStream.Position := 0;
  FInputStream.ReadEndPosition := 0;
  Windows.ZeroMemory(FInputStream.Memory, FInputStream.Size);
end;

procedure TMqttSocket.RaiseWSExcption;
var
  iRet: Integer;
  strErr: string;
begin
  iRet := WSAGetLastError();
  strErr := GetLastErrorErrorMessage(iRet);
  Disconnect();
  raise exception.CreateFmt('%s.socket error %d  %s', [ClassName, iRet, strErr]);
end;

procedure TMqttSocket.setRecvTimeOut(const Value: Integer);
var
  nNetTimeout: Integer;
  iRet: Integer;
begin
  nNetTimeout := Value;
  iRet := Setsockopt(FSocket, SOL_SOCKET, SO_RCVTIMEO, PAnsiChar(@nNetTimeout),
    Sizeof(nNetTimeout));
  if iRet = SOCKET_ERROR then
  begin
    RaiseWSExcption();
  end;
  //FRecvTimeOut := Value;
end;

procedure TMqttSocket.SetSendTimeOut(const Value: Integer);
var
  nNetTimeout: Integer;
  iRet: Integer;
begin
  if FSendTimeOut <> Value then
  begin
    nNetTimeout := Value;
    iRet := Setsockopt(FSocket, SOL_SOCKET, SO_SNDTIMEO, PAnsiChar(@nNetTimeout),
      Sizeof(nNetTimeout));
    if iRet = SOCKET_ERROR then
    begin
      RaiseWSExcption();
    end;
  end;
end;

function TMqttSocket.WaitForData(ATimeOut: Integer): Integer;
var
  CH: Byte;
begin
  FErrorCode := 0;
  setRecvTimeOut(ATimeOut);
  Result := PeekBuf(@CH, 1);
  if (FErrorCode <> 0) and (FErrorCode <> WSAETIMEDOUT) then
    raise Exception.CreateFmt('%s.WaitForData Socket Error %d', [ClassName, FErrorCode]);
end;

function TMqttSocket.ReceiveBuf(Buf: PAnsiChar; BufSize: Integer; ATimeOut:
  Integer): Integer;
var
  Len, iRet: Integer;
  P: PAnsichar;
begin
  FErrorCode := 0;
  Result := 0;

  if ATimeOut > 0 then
    SetRecvTimeOut(ATimeOut)
  else
    SetRecvTimeOut(FRecvTimeOut); //设置读超时为默认值

  if FInputStream.Datalen > 0 then
  begin
    Len := FInputStream.Datalen;
    if Len > BufSize then
      Len := BufSize;
    P := FInputStream.Memory;
    Inc(P, FInputStream.Position);
    Move(P^, Buf^, Len);
    Inc(Buf, Len);
    FInputStream.Position := FInputStream.Position + Len;
    Dec(BufSize, Len);
    Result := Result + Len;
  end;
  if FInputStream.Datalen = 0 then
  begin
    FInputStream.Position := 0;
    FInputStream.ReadEndPosition := 0;
  end;

  if BufSize > 0 then
  begin
    iRet := recv(FSocket, Buf^, BufSize, 0);
    if iRet = SOCKET_ERROR then
    begin
      FErrorCode := WSAGetLastError();
      Disconnect();
      raise exception.CreateFmt('%s.ReceiveBuf() Socket Error: %d;FRecvTimeOut[%d]ms;RowNo[MQTTClient.pas:2259]',
        [ClassName, FErrorCode, FRecvTimeOut]);
    end;
    Result := Result + iRet;
  end;
end;

function TMqttSocket.SendBuf(Buf: Pointer; BufSize: Integer): Integer;
const
  INT_BUF_SIZE = SF_SOCKET_BUFF_SIZE;
var
  P: PAnsiChar;
  Len: Integer;
  iRet: Integer;
begin
  P := Buf;
  Result := 0;
  FErrorCode := 0;
  while (BufSize > 0) do
  begin
    if BufSize > INT_BUF_SIZE then
      Len := INT_BUF_SIZE
    else
      Len := BufSize;
    iRet := Send(FSocket, P^, Len, 0);
    if iRet = SOCKET_ERROR then
    begin
      FErrorCode := WSAGetLastError();
      Disconnect();
      raise Exception.CreateFmt('%s SendBuf() ErrorCode = %d', [ClassName, FErrorCode]);
    end;
    Inc(Result, iRet);
    Inc(P, iRet);
    Dec(BufSize, iRet);
  end;
end;

function TMqttSocket.ResolveIP(const HostName: AnsiString): AnsiString;

  function IsIP(const IP: AnsiString): Boolean;
  const
    IP_MB = '0123456789.';
  var
    Index: Integer;
  begin
    Result := FALSE;
    for Index := 1 to Length(IP) do
    begin
      Result := Pos(IP[Index], IP_MB) > 0;
      if not Result then
        Break;
    end;
  end;

type
  tAddr = array[0..100] of PInAddr;

  pAddr = ^tAddr;
var
  I: Integer;
  PHE: PHostEnt;
  P: pAddr;
begin

  if IsIP(HostName) then
  begin
    Result := HostName;
    Exit;
  end;

  PHE := GetHostByName(pAnsiChar(HostName));
  if (PHE <> nil) then
  begin
    P := pAddr(PHE^.h_addr_list);
    I := 0;
    while (P^[I] <> nil) do
    begin
      Result := (inet_nToa(P^[I]^));
      Inc(I);
    end;
  end
  else
    Result := '';
end;

function TMqttSocket.PeekBuf(Buf: PAnsiChar; BufSize: Integer): Integer;
begin
  FErrorCode := 0;
  Result := Recv(FSocket, Buf^, BufSize, MSG_PEEK);
  if (Result = SOCKET_ERROR) or (Result = 0) then
    FErrorCode := WSAGetLastError();
end;

function TMqttSocket.ReceiveStream(AStream: TStream; MaxRecvSize: Integer;
  ATimeOut: Integer): Int64;
var
  Len, iRet, ErrCode: Integer;
  P: PAnsiChar;
  Buf: array[1..1024 * 32] of Byte;
begin
  Result := 0;
  FErrorCode := 0;
  if MaxRecvSize <= 0 then
    Exit;

  if ATimeOut > 0 then
    SetRecvTimeOut(ATimeOut)
  else
    SetRecvTimeOut(Self.FRecvTimeOut); //设置读超时,默认值

  if FInputStream.Datalen > 0 then
  begin
    Len := FInputStream.Datalen;
    if Len > MaxRecvSize then
      Len := MaxRecvSize;
    P := FInputStream.Memory;
    Inc(P, FInputStream.Position);
    AStream.Write(P^, Len);
    FInputStream.Position := FInputStream.Position + Len;
    Dec(MaxRecvSize, Len);
    Result := Result + Len;
  end;
  if FInputStream.Datalen = 0 then
  begin
    FInputStream.Position := 0;
    FInputStream.ReadEndPosition := 0;
  end;

  while (MaxRecvSize > 0) do
  begin
    if MaxRecvSize > SizeOf(Buf) then
      Len := SizeOf(Buf)
    else
      Len := MaxRecvSize;
    iRet := recv(FSocket, Buf, Len, 0);
    if iRet = SOCKET_ERROR then
    begin
      ErrCode := WSAGetLastError();
      Disconnect();
      raise exception.Create('ReceiveStream Error = ' + IntToStr(ErrCode));
    end;
    if iRet = 0 then
      Break; //对方优雅的关闭了连接
    Result := Result + iRet;
    Dec(MaxRecvSize, iRet);
    AStream.Write(Buf, iRet);
  end;
end;

function TMqttSocket.ReadLn(const Bufffer: PAnsiChar; BufLen: Integer; ATimeOut:
  Integer): Integer;
const
  eof: AnsiString = #13#10;
  eof_len: Integer = 2;
var
  iRet, Len: Integer;
  P: PAnsiChar;
begin
  Result := -1;

  if ATimeOut > 0 then
    SetRecvTimeOut(ATimeOut)
  else
    SetRecvTimeOut(FRecvTimeOut); //设置读超时,默认值

  if FInputStream.Datalen >= 2 then
  begin
    P := FInputStream.Memory;
    Inc(P, FInputStream.Position);
    Result := PosBuff(P, PAnsiChar(eof), FInputStream.Datalen, eof_len);
    if Result > 0 then
    begin
      if (Result - 1) <= BufLen then
      begin
        FInputStream.Read(Bufffer^, Result - 1);
        FInputStream.Position := FInputStream.Position + eof_len;
      end
      else
      begin
        Disconnect();
        raise exception.Create('ReadLn 缓冲区内未收到#13#10 ---1');
      end;
      Exit;
    end;
  end;
  if FInputStream.Datalen = 0 then
  begin
    FInputStream.Position := 0;
    FInputStream.ReadEndPosition := 0;
  end;

  //数据归位
  P := FInputStream.Memory;
  Inc(P, FInputStream.Position);
  Windows.MoveMemory(FInputStream.Memory, P, FInputStream.Datalen);
  FInputStream.ReadEndPosition := FInputStream.Datalen;
  FInputStream.Position := 0;
  //\\
  while (TRUE) do
  begin
    P := FInputStream.Memory;
    Inc(P, FInputStream.ReadEndPosition);
    Len := FInputStream.Size - FInputStream.ReadEndPosition;
    if Len <= 0 then
      Break;
    iRet := recv(FSocket, P^, Len, 0);
    if iRet > 0 then
    begin
      P := FInputStream.Memory;
      Inc(P, FInputStream.position);
      FInputStream.ReadEndPosition := FInputStream.ReadEndPosition + iRet;
      Result := PosBuff(P, PAnsiChar(eof), FInputStream.Datalen, eof_len);
      if Result > 0 then
      begin
        if (Result - 1) <= BufLen then
        begin
          FInputStream.Read(Bufffer^, Result - 1);
          FInputStream.Position := FInputStream.Position + eof_len;
          Break;
        end
        else
        begin
          if P = nil then
            Break;
          Disconnect();
          raise exception.Create('ReadLn 缓冲区内未收到#13#10----2');
        end;
      end;
    end
    else
    begin
      Result := -1;
      FErrorCode := WSAGetLastError();
      if FErrorCode <> 0 then
      begin
        Disconnect();
        raise Exception.CreateFmt('ReadLn Error %d', [FErrorCode]);
      end;
      Break;
    end;
  end;
end;

procedure TMqttSocket.SetNagle(const Value: Boolean);
var
  iRet: Integer;
begin
  iRet := SizeOf(Value);
  if Setsockopt(FSocket, IPPROTO_TCP, TCP_NODELAY, PAnsichar(@Value), iRet) =
    SOCKET_ERROR then
  begin
    iRet := WSAGetLastError();
    raise Exception.CreateFmt('getNagle SocketError %d', [iRet]);
  end;
end;

{ TRedisStreamEh }

function TRedisStreamEh.getDataLen: Int64;
var
  EndPos: Int64;
begin
  if ReadEndPosition < 0 then
    EndPos := Self.Size
  else
    EndPos := Self.ReadEndPosition;
  //\\
  Result := EndPos - Position;
  if Result < 0 then
    Result := 0;
end;

{ TVirtualStream }

function TVirtualStream.Write(const Buffer; Count: Integer): Longint;
begin
  Result := Count;
  if Count > 0 then
    FPosition := FPosition + Count;
end;

initialization
  //GetMQTT;

finalization
  if Assigned(MQ) then
    FreeAndNil(MQ);

end.

