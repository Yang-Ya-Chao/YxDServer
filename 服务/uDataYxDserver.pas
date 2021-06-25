unit uDataYxDserver;

interface
 uses Classes,FireDAC.Comp.Client,System.SysUtils,SQLFirDACPoolUnit;

type
  TYxDSvr = class
  private
    //数据库链接对象
    DATABASE : TFDConnection;
    FQry:TFDQuery;
    //执行sql语句
    function ExeSql(AQuery: TFDQuery; CSQL: string; ExecFlag: Boolean): Boolean;
  public
    FRet:String;
    FError:String;  //错误信息
    function HelloWorld:Boolean;
    constructor Create(AOwner: TComponent);
    destructor Destroy; override;
  end;
implementation

{ TYxDSvr }

function TYxDSvr.ExeSql(AQuery: TFDQuery; CSQL: string; ExecFlag: Boolean): Boolean;
begin
  Result := False;
  if not Assigned(DATABASE) then
    raise Exception.Create('无数据库连接！请检查！');
  if CSQL = '' then
    raise Exception.Create('没有SQL语句！请检查！');
  AQuery.Connection := DATABASE;
  with AQuery do
  begin
    Close;
    Sql.Clear;
    Sql.Add(CSQL);
    try
      if ExecFlag then
        ExecSQL
      else
        Open;
    except
      on E: Exception do
      begin
        Close;
        FError := '错误信息:' + E.Message + #13#10 +
          ' SQL:' + CSQL;
        Exit;
      end;
    end;
  end;
  Result := True;
end;

constructor TYxDSvr.Create(AOwner: TComponent);
begin
  DATABASE := DACPool.GetCon(DAConfig);
 { DATABASE:= TFDConnection.Create(nil);
  with DATABASE do
  begin
    ConnectionDefName := 'MSSQL_Pooled';
    try
      Connected := True;
    except
      raise Exception.Create('数据库连接失败！请检查数据库配置或者网络链接！');
    end;
  end;   }
  FQry:=TFDQuery.Create(nil);
end;

destructor TYxDSvr.Destroy;
begin
  DACPool.PutCon(DATABASE);
  {if Assigned(DATABASE) then
    FreeAndNil(DATABASE); }
  if Assigned(FQry) then
    FreeAndNil(FQry);
  inherited;
end;

function TYxDSvr.HelloWorld: Boolean;
var
  CSQL:String;
begin
  Result := False;
  try
    CSQL := 'SELECT GETDATE() Time';
    if not ExeSql(FQry,CSQL,False) then Exit;
    FRet := 'HelloWorld:'+FQry.FieldByName('Time').AsString;
  finally

  end;
  Result := True;
end;

end.
