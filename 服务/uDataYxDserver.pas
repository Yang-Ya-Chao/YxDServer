unit uDataYxDserver;

interface
type
  TYxDSvr = class
  public
    FRet:String;
    FError:String;
    function HelloWorld:Boolean;
  end;
implementation

{ TYxDSvr }

function TYxDSvr.HelloWorld: Boolean;
begin
  FRet := 'HelloWorld';
  Result := True;
end;

end.
