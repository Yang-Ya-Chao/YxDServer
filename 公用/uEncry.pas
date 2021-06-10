unit uEncry;
(**************************************************)
(*                                                *)
(* Advanced Encryption Standard (AES) Extend      *)
(*                                                *)
(* Copyright (c) 2005-2016                        *)
(* aisino, qiaobu@139.com qiaohaidong@aisino.com  *)
(*                                                *)
(**************************************************)

interface

{$WARN IMPLICIT_STRING_CAST OFF} // �رվ���
{$WARN IMPLICIT_STRING_CAST_LOSS OFF}

uses
  SysUtils, Classes, Math, ElAES, System.Generics.Collections;

const
  Key: AnsiString = 'AbCd1EFG2h3I4j5kLm9no4PQr8Stu6Vw5X7yz';

type
  TPaddingType = (PKCS5Padding { , PKCS7Padding } );

  TKeyBit = (kb128, kb192, kb256);

  TalgoMode = (amECB, amCBC { , amCFB, amOFB, amCTR } );

  TCipherType = ({ctBase64,} ctHex);

  TArrayPadding = array of Byte;

  TArrayByte = array of Byte;

var
  AESKey128: TAESKey128;
  AESKey192: TAESKey192;
  AESKey256: TAESKey256;
  InitVector: TAESBuffer;

function EnCode(Value: AnsiString; KeyBit: TKeyBit = kb128; algoMode: TalgoMode
  = amECB; padding: TPaddingType = PKCS5Padding; sInitVector: AnsiString =
  '0000000000000000'; CipherType: TCipherType = ctHex): AnsiString;

function DeCode(Value: AnsiString; KeyBit: TKeyBit = kb128; algoMode: TalgoMode
  = amECB; padding: TPaddingType = PKCS5Padding; sInitVector: AnsiString =
  '0000000000000000'; CipherType: TCipherType = ctHex): AnsiString;

implementation

//�ַ���ת16���ƣ��ַ�����
function StrToHex(Value: AnsiString): string;
var
  i: Integer;
begin
  Result := '';
  for i := 1 to Length(Value) do
    Result := Result + IntToHex(Ord(Value[i]), 2);
end;
//16���ƣ��ַ�����ת�ַ���

function HexToStr(Value: AnsiString): AnsiString;
var
  i: Integer;
begin
  Result := '';
  for i := 1 to Length(Value) do
  begin
    if ((i mod 2) = 1) then
      Result := Result + ansichar(StrToInt('0x' + Copy(Value, i, 2)));
  end;
end;

//PKCS5������
function PKCS5_Padding(Value: AnsiString; out arrayValue: TArrayByte): Int64;
var
  Valueutf8: UTF8String;
  BytesValue: array of Byte;
  intMod: Byte;
  valueLen: Integer;
  i: Integer;
begin
  Valueutf8 := Value;
  SetLength(BytesValue, Length(Valueutf8));
  Move(Valueutf8[1], BytesValue[0], Length(Valueutf8));
  intMod := 16 - Length(BytesValue) mod 16;

  valueLen := Length(BytesValue);
  SetLength(BytesValue, valueLen + intMod);
  for i := 0 to intMod - 1 do
  begin
    BytesValue[valueLen + i] := intMod;
  end;
  SetLength(arrayValue, Length(BytesValue));
  Move(BytesValue[0], arrayValue[0], Length(BytesValue));
  Result := Length(BytesValue);
end;

//PKCS5����ȥ����
function PKCS5_DePadding(bytes: TBytes): string;
var
  Encoding: TEncoding;
  size: Integer;
  paddingByte: Byte;
  tmpBytes: TBytes;
begin
  paddingByte := bytes[Length(bytes) - 1];

  SetLength(tmpBytes, Length(bytes) - paddingByte);
  Move(bytes[0], tmpBytes[0], Length(tmpBytes));
  Encoding := TEncoding.UTF8;
  size := TEncoding.GetBufferEncoding(tmpBytes, Encoding);
  Result := Encoding.GetString(tmpBytes, size, Length(tmpBytes) - size)
end;

//��Կ����λ��0����
procedure ZeroPadding(KeyBit: TKeyBit);
begin
  case KeyBit of
    kb128:
      FillChar(AESKey128, SizeOf(AESKey128), 0);
    kb192:
      FillChar(AESKey192, SizeOf(AESKey192), 0);
    kb256:
      FillChar(AESKey256, SizeOf(AESKey256), 0);
  end;
end;

function EnCode(Value: AnsiString; KeyBit: TKeyBit = kb128; algoMode: TalgoMode
  = amECB; padding: TPaddingType = PKCS5Padding; sInitVector: AnsiString =
  '0000000000000000'; CipherType: TCipherType = ctHex): AnsiString;
var
  SS, DS: TMemoryStream;
  str: AnsiString;
  byteContent: TArrayByte;
begin
  Result := '';
  PKCS5_Padding(Value, byteContent);

  SS := TMemoryStream.Create;
  SS.WriteBuffer(byteContent[0], Length(byteContent));

  SS.Position := SS.size;
  DS := TMemoryStream.Create;

  try
    case KeyBit of
      kb128:
        begin
          ZeroPadding(kb128);
          Move(PAnsiChar(Key)^, AESKey128, Length(Key));
          case algoMode of
            amECB:
              begin
                EncryptAESStreamECB(SS, 0, AESKey128, DS);
              end;
            amCBC:
              begin
                // ����16λ��0����
                FillChar(InitVector, SizeOf(InitVector), 0);
                Move(PAnsiChar(sInitVector)^, InitVector, Length(sInitVector));
                EncryptAESStreamCBC(SS, 0, AESKey128, InitVector, DS);
              end;
          end;
        end;
      kb192:
        begin
          ZeroPadding(kb192);
          Move(PAnsiChar(Key)^, AESKey192, Length(Key));
          case algoMode of
            amECB:
              begin
                EncryptAESStreamECB(SS, 0, AESKey192, DS);
              end;
            amCBC:
              begin
                FillChar(InitVector, SizeOf(InitVector), 0);
                Move(PAnsiChar(sInitVector)^, InitVector, Length(sInitVector));
                EncryptAESStreamCBC(SS, 0, AESKey192, InitVector, DS);
              end;
          end;
        end;
      kb256:
        begin
          ZeroPadding(kb256);
          Move(PAnsiChar(Key)^, AESKey256, Length(Key));
          case algoMode of
            amECB:
              begin
                EncryptAESStreamECB(SS, 0, AESKey256, DS);
              end;
            amCBC:
              begin
                FillChar(InitVector, SizeOf(InitVector), 0);
                Move(PAnsiChar(sInitVector)^, InitVector, Length(sInitVector));
                EncryptAESStreamCBC(SS, 0, AESKey256, InitVector, DS);
              end;
          end;
        end;
    end;

    SetLength(str, DS.size);
    DS.Position := 0;
    DS.ReadBuffer(PAnsiChar(str)^, DS.size);
    Result := StrToHex(str);
  finally
    SS.Free;
    DS.Free;
  end;
end;

function DeCode(Value: AnsiString; KeyBit: TKeyBit = kb128; algoMode: TalgoMode
  = amECB; padding: TPaddingType = PKCS5Padding; sInitVector: AnsiString =
  '0000000000000000'; CipherType: TCipherType = ctHex): AnsiString;
var
  SS, DS: TMemoryStream;
  str: AnsiString;
  byteContent: TBytes;
  BytesValue: TBytes;
begin
  Result := '';
  if Value = '' then
    Exit;
  // pcharValue := pchar(Value);
  str := HexToStr(Value);

  SS := TMemoryStream.Create;

  SetLength(byteContent, Length(str));
  Move(str[1], byteContent[0], Length(str));

  SS.WriteBuffer(byteContent[0], Length(byteContent));

  DS := TMemoryStream.Create;

  try
    case KeyBit of
      kb128:
        begin
          ZeroPadding(kb128);
          Move(PAnsiChar(Key)^, AESKey128, Length(Key));
          case algoMode of
            amECB:
              begin
                DecryptAESStreamECB(SS, 0, AESKey128, DS);
              end;
            amCBC:
              begin
                // ����16λ��0����
                FillChar(InitVector, SizeOf(InitVector), 0);
                Move(PAnsiChar(sInitVector)^, InitVector, Length(sInitVector));
                DecryptAESStreamCBC(SS, 0, AESKey128, InitVector, DS);
              end;
          end;
        end;
      kb192:
        begin
          ZeroPadding(kb192);
          Move(PAnsiChar(Key)^, AESKey192, Length(Key));
          case algoMode of
            amECB:
              begin
                DecryptAESStreamECB(SS, 0, AESKey192, DS);
              end;
            amCBC:
              begin
                FillChar(InitVector, SizeOf(InitVector), 0);
                Move(PAnsiChar(sInitVector)^, InitVector, Length(sInitVector));
                DecryptAESStreamCBC(SS, 0, AESKey192, InitVector, DS);
              end;
          end;
        end;
      kb256:
        begin
          ZeroPadding(kb256);
          Move(PAnsiChar(Key)^, AESKey256, Length(Key));
          case algoMode of
            amECB:
              begin
                DecryptAESStreamECB(SS, 0, AESKey256, DS);
              end;
            amCBC:
              begin
                FillChar(InitVector, SizeOf(InitVector), 0);
                Move(PAnsiChar(sInitVector)^, InitVector, Length(sInitVector));
                DecryptAESStreamCBC(SS, 0, AESKey256, InitVector, DS);
              end;
          end;
        end;
    end;
    DS.Position := 0;
    SetLength(BytesValue, DS.size);
    DS.ReadBuffer(BytesValue[0], DS.size);
    Result := PKCS5_DePadding(BytesValue);
  finally
    SS.Free;
    DS.Free;
  end;
end;

end.

