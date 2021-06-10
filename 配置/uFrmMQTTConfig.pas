unit uFrmMQTTConfig;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.Buttons, Vcl.ExtCtrls,IniFiles,MQTT,UFrmMQTTClient,
  Vcl.ComCtrls;

type
  TFrmMQTTConfig = class(TForm)
    pnl2: TPanel;
    pnl1: TPanel;
    BtnCSLJ: TBitBtn;
    BtnMod: TBitBtn;
    BtnSave: TBitBtn;
    BtnCancel: TBitBtn;
    lbl1: TLabel;
    EdtServer: TEdit;
    lbl2: TLabel;
    EdtClientID: TEdit;
    lbl3: TLabel;
    EdtUserName: TEdit;
    EdtPass: TEdit;
    lbl5: TLabel;
    ckReConnect: TCheckBox;
    lbl4: TLabel;
    EdtSub: TEdit;
    ckSub: TCheckBox;
    lbl6: TLabel;
    EdtPub: TEdit;
    cbbSubQos: TComboBox;
    ckAutoPing: TCheckBox;
    ckRetain: TCheckBox;
    ckclearsession: TCheckBox;
    stat1: TStatusBar;
    ckMQTT: TCheckBox;
    procedure BtnSaveClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure BtnModClick(Sender: TObject);
    procedure BtnCancelClick(Sender: TObject);
    procedure BtnCSLJClick(Sender: TObject);
    procedure ckMQTTClick(Sender: TObject);
  private
    procedure ReadConfig;
    function BSTATUS(ISTATUS: Boolean): boolean;
    procedure SetMQTTStatus;
    { Private declarations }
  public
    YxSCKTINI:string;
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
    { Public declarations }
  end;

var
  FrmMQTTConfig: TFrmMQTTConfig;

implementation

{$R *.dfm}

procedure TFrmMQTTConfig.BtnCancelClick(Sender: TObject);
begin
  BSTATUS(false);
  ReadConfig;
end;

procedure TFrmMQTTConfig.BtnCSLJClick(Sender: TObject);
begin
  with TFrmMQTTClient.Create(self) do
  try
    Position := poScreenCenter;
    ShowModal;
  finally
    Free;
  end;
end;

procedure TFrmMQTTConfig.BtnModClick(Sender: TObject);
begin
  BSTATUS(True);
end;

procedure TFrmMQTTConfig.BtnSaveClick(Sender: TObject);
var
  AINI: TIniFile;
begin
  AINI := TIniFile.Create(YxSCKTINI);
  try
    AINI.WriteString('MQTT', 'Server', EdtServer.Text);
    AINI.WriteString('MQTT', 'ClientID', EdtClientId.Text);
    AINI.WriteString('MQTT', 'User', EdtUserName.Text);
    AINI.WriteString('MQTT', 'Pass', EdtPass.Text);
    AINI.WriteString('MQTT', 'SubTopic', EdtSub.Text);
    AINI.WriteString('MQTT', 'PubTopic', EdtPub.Text);
    AINI.WriteBool('MQTT', 'BSub', ckSub.CHECKED);
    AINI.WriteBool('MQTT', 'Retain', ckRetain.CHECKED);
    AINI.WriteBool('MQTT', 'ReConnect', ckReConnect.CHECKED);
    AINI.WriteBool('MQTT', 'ClearSession', ckclearsession.CHECKED);
    AINI.WriteBool('MQTT', 'AutoPing', ckAutoPing.CHECKED);
    AINI.WriteInteger('MQTT', 'Qos', cbbSubQos.ItemIndex);
    AINI.WriteBool('MQTT', 'BMQTT', CKMQTT.CHECKED);
  finally
    FreeAndNil(AINI);
  end;
  MessageBox(Handle, '配置保存成功！请重启程序生效！', '提示', MB_ICONASTERISK and MB_ICONINFORMATION);
  ReadConfig;
  BSTATUS(false);
end;

procedure TFrmMQTTConfig.FormShow(Sender: TObject);
begin
  BSTATUS(false);
  ReadConfig;
end;

function TFrmMQTTConfig.BSTATUS(ISTATUS: Boolean): boolean;
begin
  pnl1.Enabled := ISTATUS;
  BtnCancel.Enabled := ISTATUS;
  BtnSave.Enabled := ISTATUS;
  BtnMod.Enabled := not ISTATUS;
  Result := True;
end;

procedure TFrmMQTTConfig.ReadConfig;
var
  Inifile: TIniFile;
begin
  YxSCKTINI := ExtractFileDir(ParamStr(0)) + '\YxDServer.ini';
  if FileExists(YxSCKTINI) then
  begin
    Inifile := TIniFile.Create(YxSCKTINI);
    try
      EdtServer.Text := Inifile.ReadString('MQTT', 'Server', '');
      EdtClientId.Text := Inifile.ReadString('MQTT', 'ClientID', '');
      EdtUserName.Text := Inifile.ReadString('MQTT', 'User', '');
      EdtPass.Text := Inifile.ReadString('MQTT', 'Pass', '');
      EdtSub.Text := Inifile.ReadString('MQTT', 'SubTopic', '');
      EdtPub.Text := Inifile.ReadString('MQTT', 'PubTopic', '');
      ckSub.CHECKED := Inifile.ReadBool('MQTT', 'BSub', False);
      ckRetain.CHECKED := Inifile.ReadBool('MQTT', 'Retain', False);
      ckReConnect.CHECKED := Inifile.ReadBool('MQTT', 'ReConnect', False);
      ckclearsession.CHECKED := Inifile.ReadBool('MQTT', 'ClearSession', False);
      ckAutoPing.CHECKED := Inifile.ReadBool('MQTT', 'AutoPing', False);
      cbbSubQos.ItemIndex := Inifile.ReadInteger('MQTT', 'Qos', -1);
      CKMQTT.CHECKED := Inifile.ReadBool('MQTT', 'BMQTT', false);
    finally
      FreeAndNil(Inifile);
    end;
  end;
end;

procedure TFrmMQTTConfig.ckMQTTClick(Sender: TObject);
var
  AINI: TIniFile;
begin
  AINI := TIniFile.Create(YxSCKTINI);
  try
    AINI.WriteBool('MQTT', 'BMQTT', CKMQTT.CHECKED);
  finally
    FreeAndNil(AINI);
    if ckMQTT.Checked then
      GetMQTT
    else
    begin
      if MQ.Connected then
        MQ.DisConnect;
    end;
  end;

end;


procedure TFrmMQTTConfig.OnConnAck(Sender: TObject; ReturnCode: integer);
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
  {WriteLog('OnConnAck ReturnCode=' + IntToStr(ReturnCode) + ',Status=' + ReturnCodeToStr());
  if ReturnCode = 0 then
  begin
    Connect.Enabled := FALSE;
  end;  }
end;

procedure TFrmMQTTConfig.OnDisConnect(Sender: TObject);
var
  Msg:string;
  Obj:TMQTTClient;
begin
  Obj := Sender as TMQTTClient;
  Msg := Format('OnDisConnect...,UserCancel[%s],ErrDesc[%s]',[
                 BoolToStr(Obj.UserCancelSocket,true),
                 Obj.ErrDesc]);
  //gConnectError :=  Obj.ErrDesc <> '';
  //WriteLog(Msg);

end;

procedure TFrmMQTTConfig.OnPingResp(Sender: TObject);
begin
  //WriteLog('OnPingResp');
end;

procedure TFrmMQTTConfig.OnPubAck(Sender: TObject; MsgId: Word);
begin
  //WriteLog('OnPubAck MsgId=' + IntToStr(MsgId));
end;

procedure TFrmMQTTConfig.OnPubComp(Sender: TObject; MsgId: Word);
begin
  //WriteLog('OnPubComp MsgId=' + IntToStr(MsgId));
end;

procedure TFrmMQTTConfig.OnPublish(Sender: TObject;
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
  showmessage(msg.MsgContent);
  //WriteLog(Text);
end;

procedure TFrmMQTTConfig.OnPubRec(Sender: TObject; MsgId: Word);
begin
  //WriteLog('OnPubRec MsgId=' + IntToStr(MsgId));
end;

procedure TFrmMQTTConfig.OnPubRel(Sender: TObject; MsgId: Word);
begin
  //WriteLog('OnPubRel MsgId=' + IntToStr(MsgId));
end;

procedure TFrmMQTTConfig.OnSocketConnect(Sender: TObject;
  Connected: Boolean);
var
  Msg:string;
  Obj :TMQTTClient;
begin
  Obj := Sender as TMQTTClient;
  Msg := Format('OnSocketConnect,Connected[%s],ErrDesc[%s]',[
                BoolToStr(Connected,TRUE),
                Obj.ErrDesc]);
 // WriteLog(Msg);
end;
procedure TFrmMQTTConfig.OnSubAck(Sender: TObject; MessageID,
  GrantedQoS: Integer);
var
  Msg:string;
begin
  Msg := Format('OnSubAck MsgId=%d,GrantedQoS=%d',[MessageID,GrantedQoS]);
  //WriteLog(Msg);
end;

procedure TFrmMQTTConfig.OnUnSubAck(Sender: TObject; MsgId: Word);
var
  Msg:string;
begin
  Msg := Format('OnUnSubAck,MsgId=%d',[MsgId]);
  //WriteLog(Msg);
end;

procedure TFrmMQTTConfig.SetMQTTStatus;
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

