unit uFrmMQTTClient;

interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, MQTT, Vcl.Buttons, Vcl.ComCtrls;

const
  WM_WRITE_LOG = WM_USER + 1;
type
  TFrmMQTTClient = class(TForm)
    MMLog: TMemo;
    pnl1: TPanel;
    btnPublish: TButton;
    EdtPubTopic: TEdit;
    lbl2: TLabel;
    lbl1: TLabel;
    btnPing: TButton;
    mmo1: TMemo;
    Connect: TBitBtn;
    DisConnect: TBitBtn;
    stat1: TStatusBar;
    lbl3: TLabel;
    EdtSubTopic: TEdit;
    btnSub: TButton;
    btnDisSub: TButton;
    procedure btnPublishClick(Sender: TObject);
    procedure ConnectClick(Sender: TObject);
    procedure DisConnectClick(Sender: TObject);
    procedure SetMQTTStatus;
    procedure FormCreate(Sender: TObject);
    procedure btnSubClick(Sender: TObject);
    procedure btnDisSubClick(Sender: TObject);
  private
    procedure WriteLog(const Msg: string);
    procedure MSG_Log(var message:TMessage); message WM_WRITE_LOG;
    { Private declarations }
  public
    { Public declarations }
    procedure OnSocketConnect(Sender: TObject;Connected:Boolean);
    procedure OnConnAck(Sender: TObject; ReturnCode: integer);
    procedure OnPubAck(Sender: TObject; MsgId:Word);
    procedure OnPubRec(Sender: TObject; MsgId:Word);
    procedure OnPubRel(Sender: TObject; MsgId:Word);
    procedure OnPubComp(Sender: TObject; MsgId:Word);
    procedure OnSubAck(Sender: TObject; MessageID: integer; GrantedQoS: Integer);
    procedure OnPublish(Sender: TObject;const msg:TRecvPublishMessage);
                       //Qos:TQosLevel;MsgID:Word;Retain:Boolean;const topic, payload: AnsiString);
    procedure OnPingResp(Sender: TObject);
    procedure OnUnSubAck(Sender: TObject; MsgId:Word);
    procedure OnDisConnect(Sender: TObject);
  end;

var
  FrmMQTTClient: TFrmMQTTClient;
  gConnectError:Boolean;

implementation

{$R *.dfm}

procedure TFrmMQTTClient.btnDisSubClick(Sender: TObject);
var
  Topic:AnsiString;
begin
  Topic := AnsiString(edtSubTopic.Text);
  MQ.UnSubScribe(Topic);
end;

procedure TFrmMQTTClient.btnPublishClick(Sender: TObject);
var
  Topic, Data: AnsiString;
begin
  Topic := Self.edtPubTopic.Text;
  Data := Self.MMO1.Lines.Text;
  Data := AnsiToUtf8(Data);
  MQ.Publish(Topic, Data, MQ.Qos, MQ.Retain);
  //WriteLog(format('[published],[%s],iRet[%d]',[Topic,iRet]));
end;

procedure TFrmMQTTClient.btnSubClick(Sender: TObject);
var
  Topic:AnsiString;
begin
  Topic := edtSubTopic.Text;
  MQ.SubScribe(Topic,MQ.Qos);
end;


procedure TFrmMQTTClient.ConnectClick(Sender: TObject);
begin
  GetMQTT;
  if MQ.Connected then
    Stat1.Panels[0].Text := '连接时间: ' + FormatDateTime('YYYY-MM-DD hh:mm:ss',Now());
end;

procedure TFrmMQTTClient.DisConnectClick(Sender: TObject);
begin
  if MQ.Connected then
    MQ.DisConnect;
end;

procedure TFrmMQTTClient.FormCreate(Sender: TObject);
begin
  SetMQTTStatus;
  //
  {$IF Defined(CPUX64)}
     Stat1.Panels[1].Text := 'Win64A';
  {$ELSE}
     Stat1.Panels[1].Text := 'Win32';
  {$IFEND}
  //
  Stat1.Panels[2].Text := MQ.ComponmentVersion;
end;

procedure TFrmMQTTClient.MSG_Log(var message: TMessage);
var
  Msg:string;
begin
  Msg := FormatDateTime('YYYY-MM-DD hh:mm:ss.zzz',Now());
  Msg := Msg + ': ' + PString(message.WParam)^;
  mmLog.Lines.Add(Msg);
end;

procedure TFrmMQTTClient.WriteLog(const Msg: string);
begin
  if mmLog.Lines.Count > 2048 then
    mmLog.Lines.Clear();
  SendMessage(Handle,WM_WRITE_LOG,WPARAM(@Msg),0);
end;

procedure TFrmMQTTClient.OnConnAck(Sender: TObject; ReturnCode: integer);
  function ReturnCodeToStr():string;
  begin
    case ReturnCode of
      0: Result := 'OK';
      1: Result := 'ConnectAckState';
      2: Result := 'InvalidClientID';
      3: Result := 'Serverunavailable';
      4: Result := 'InvalidUserOrPassWord';
      5: Result := 'NoAuthorizd';
      else
        Result := 'Unknown';
    end;
  end;
begin
  WriteLog('OnConnAck ReturnCode=' + IntToStr(ReturnCode) + ',Status=' + ReturnCodeToStr());
  if ReturnCode = 0 then
  begin
    Connect.Enabled := FALSE;
  end;
end;

procedure TFrmMQTTClient.OnDisConnect(Sender: TObject);
var
  Msg:string;
  Obj:TMQTTClient;
begin
  Obj := Sender as TMQTTClient;
  Msg := Format('OnDisConnect...,UserCancel[%s],ErrDesc[%s]',[
                 BoolToStr(Obj.UserCancelSocket,true),
                 Obj.ErrDesc]);
  gConnectError :=  Obj.ErrDesc <> '';
  WriteLog(Msg);
  //
  if Obj.AutoReConnect then
  begin
    WriteLog('OnDisConnect...ReConnect-----AutoReConnect,延迟 :' + IntToStr(Obj.AutoReConnectDelaySec) + '秒后重连');
  end;

  Connect.Enabled := not MQ.AutoReConnect;

end;

procedure TFrmMQTTClient.OnPingResp(Sender: TObject);
begin
  WriteLog('OnPingResp');
end;

procedure TFrmMQTTClient.OnPubAck(Sender: TObject; MsgId: Word);
begin
  WriteLog('OnPubAck MsgId=' + IntToStr(MsgId));
end;

procedure TFrmMQTTClient.OnPubComp(Sender: TObject; MsgId: Word);
begin
  WriteLog('OnPubComp MsgId=' + IntToStr(MsgId));
end;

procedure TFrmMQTTClient.OnPublish(Sender: TObject;
  const msg: TRecvPublishMessage);
var
  Text:string;
  MsgContent:AnsiString;
begin
  {if cb_utf8.Checked then
     MsgContent := Utf8ToAnsi(msg.MsgContent)
  else  }
  MsgContent := UTF8Decode(msg.MsgContent);
  Text := format('OnPublish,Dup=%s,Qos=%d,MsgID[%d],Retain[%s],Topic=%s,payload=%s',
                [BoolToStr(msg.Dup,TRUE),
                 Integer(msg.Qos),
                 msg.MsgID,
                 BoolToStr(msg.Retain,TRUE),
                 msg.topic,
                 msg.MsgContent]);
  WriteLog(Text);
end;

procedure TFrmMQTTClient.OnPubRec(Sender: TObject; MsgId: Word);
begin
  WriteLog('OnPubRec MsgId=' + IntToStr(MsgId));
end;

procedure TFrmMQTTClient.OnPubRel(Sender: TObject; MsgId: Word);
begin
  WriteLog('OnPubRel MsgId=' + IntToStr(MsgId));
end;

procedure TFrmMQTTClient.OnSocketConnect(Sender: TObject;
  Connected: Boolean);
var
  Msg:string;
  Obj :TMQTTClient;
begin
  Obj := Sender as TMQTTClient;
  Msg := Format('OnSocketConnect,Connected[%s],ErrDesc[%s]',[
                BoolToStr(Connected,TRUE),
                Obj.ErrDesc]);
  WriteLog(Msg);
  //
  Self.Connect.Enabled := FALSE;
  Self.DisConnect.Enabled := TRUE;
  Self.btnPublish.Enabled := TRUE;
  Self.btnPing.Enabled := TRUE;
end;
procedure TFrmMQTTClient.OnSubAck(Sender: TObject; MessageID,
  GrantedQoS: Integer);
var
  Msg:string;
begin
  Msg := Format('OnSubAck MsgId=%d,GrantedQoS=%d',[MessageID,GrantedQoS]);
  WriteLog(Msg);
end;

procedure TFrmMQTTClient.OnUnSubAck(Sender: TObject; MsgId: Word);
var
  Msg:string;
begin
  Msg := Format('OnUnSubAck,MsgId=%d',[MsgId]);
  WriteLog(Msg);
end;

procedure TFrmMQTTClient.SetMQTTStatus;
begin
  MQ.OnFConnAck := OnConnAck;
  MQ.OnPubAck   := OnPubAck;
  MQ.OnPubRec   := OnPubRec;
  MQ.OnPubRel   := OnPubRel;
  MQ.OnPubComp  := OnPubComp;
  MQ.onSubAck   := OnSubAck;
  MQ.OnUnSubAck := OnUnSubAck;
  MQ.OnPublish  := OnPublish;
  MQ.OnPingResp := OnPingResp;
  MQ.OnSocketConnect := OnSocketConnect;
  MQ.OnDisConnect    := OnDisConnect;
end;

end.

