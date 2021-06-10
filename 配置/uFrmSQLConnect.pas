unit uFrmSQLConnect;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Mask, ExtCtrls, ComCtrls, IniFiles, uEncry, Data.DB,
  Data.Win.ADODB, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error,
  FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys, FireDAC.VCLUI.Wait, FireDAC.Comp.Client,
  Vcl.Buttons;

type
  TFrmSQLConnect = class(TForm)
    lbl1: TLabel;
    EdtServer: TEdit;
    EdtDBName: TEdit;
    lbl2: TLabel;
    lbl3: TLabel;
    EdtUserName: TEdit;
    EdtPass: TEdit;
    EdtPort: TEdit;
    lbl4: TLabel;
    lbl5: TLabel;
    BtnCSLJ: TBitBtn;
    BtnMod: TBitBtn;
    BtnSave: TBitBtn;
    BtnCancel: TBitBtn;
    ck1: TCheckBox;
    procedure FormShow(Sender: TObject);
    procedure ReadConfig;
    procedure BtnModClick(Sender: TObject);
    procedure BtnCancelClick(Sender: TObject);
    procedure BtnCSLJClick(Sender: TObject);
    procedure BtnSaveClick(Sender: TObject);
    procedure ck1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }

    YxSCKTINI: string;
    function BSTATUS(ISTATUS: Boolean): Boolean;
  end;

var
  FrmSQLConnect: TFrmSQLConnect;

implementation

{$R *.dfm}

procedure TFrmSQLConnect.BtnCancelClick(Sender: TObject);
begin
  ReadConfig;
  BSTATUS(false);
end;

procedure TFrmSQLConnect.BtnCSLJClick(Sender: TObject);
var
  FConnObj: TFDConnection; //数据库连接对象
  str: string;
begin
  try
    FConnObj := TFDConnection.Create(nil);
    str := 'DriverID=MSSQL;Server=' + EdtServer.Text + ';Database=' + EdtDBName.Text
      + ';User_name=' + EdtUserName.Text + ';Password=' + EdtPASS.Text;
    with FConnObj do
    begin
      //ConnectionTimeout:=18000;
      ConnectionString := str;
      try
        Connected := True;
      except
        on e: Exception do
        begin
          MessageBox(Handle, PChar('数据库连接失败！' + e.Message), '错误', MB_ICONERROR);
          Exit;
        end;
      end;
      if Connected then
        Connected := False;
      MessageBox(Handle, '数据库连接成功！', '提示', MB_ICONASTERISK and MB_ICONINFORMATION);
    end;
  finally
    FreeAndNil(FConnObj);
  end;
end;

procedure TFrmSQLConnect.BtnModClick(Sender: TObject);
begin
  BSTATUS(True);
end;

procedure TFrmSQLConnect.BtnSaveClick(Sender: TObject);
var
  AINI: TIniFile;
begin
  AINI := TIniFile.Create(YxSCKTINI);
  AINI.WriteString('DB', 'Server', EnCode(Edtserver.Text));
  AINI.WriteString('DB', 'DataBase', EnCode(Edtdbname.Text));
  AINI.WriteString('DB', 'UserName', EnCode(Edtusername.Text));
  AINI.WriteString('DB', 'PassWord', EnCode(Edtpass.text));
  FreeAndNil(AINI);
  MessageBox(Handle, '链接保存成功！请重启程序生效！', '提示', MB_ICONASTERISK and
    MB_ICONINFORMATION);
  ReadConfig;
  BSTATUS(false);
end;

procedure TFrmSQLConnect.ck1Click(Sender: TObject);
begin
  if ck1.Checked then EdtPass.PasswordChar := #0
  else if not ck1.checked then EdtPass.PasswordChar := '*';

end;

function TFrmSQLConnect.BSTATUS(ISTATUS: Boolean): boolean;
begin
  EdtServer.Enabled := ISTATUS;
  EdtDBName.Enabled := ISTATUS;
  EdtUserName.Enabled := ISTATUS;
  Edtpass.Enabled := ISTATUS;
  BtnCancel.Enabled := ISTATUS;
  BtnSave.Enabled := ISTATUS;
  BtnMod.Enabled := not ISTATUS;
  Result := True;
end;

procedure TFrmSQLConnect.FormShow(Sender: TObject);
begin
  BSTATUS(false);
  ReadConfig;
end;

procedure TFrmSQLConnect.ReadConfig;
var
  Inifile: TIniFile;
begin
  YxSCKTINI := ExtractFileDir(ParamStr(0)) + '\YxDServer.ini';
  if FileExists(YxSCKTINI) then
  begin
    Inifile := TIniFile.Create(YxSCKTINI);
    try
      EdtServer.Text := DeCode(Inifile.ReadString('DB', 'Server', ''));
      EdtDBName.Text := DeCode(Inifile.ReadString('DB', 'DataBase', ''));
      EdtUserName.Text := DeCode(Inifile.ReadString('DB', 'UserName', ''));
      EdtPass.Text := DeCode(Inifile.ReadString('DB', 'PassWord', ''));
    finally
      FreeAndNil(Inifile);
    end;
  end;
end;

end.

