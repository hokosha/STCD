unit uConnect;

interface

uses
  Classes,
  SysUtils,
  WinSock,

  uCommon;

type
  TConnector = class(TThread)
    Sct: TSocket;
    constructor Create;
    destructor Destroy; override;
  protected
    procedure Execute; override;
    procedure ShowError;
    procedure ShowMsg;
  private
    FMsgStr: string;
    FSocketReady: boolean;
    FCheckAttempt: byte;
    function IpAdrToSocketAdr(_sAddr: string): TInAddr;
    procedure PrepareAddr(var _addr: TSockAddr; _sAddr: AnsiString = ''; _iPort: integer = 80);
    procedure ShowState(_sState: string = '');
    procedure OpenSocket;
    procedure FinishSocket;
  public
    property SocketReady: boolean read FSocketReady write FSocketReady;
  end;



implementation

uses
  uStateMsg,
  uMsgExchange;

{ TConnector }

constructor TConnector.Create;
begin
  inherited Create(true);
  FreeOnTerminate := true;
  OpenSocket;

end;

destructor TConnector.Destroy;
begin
  FinishSocket;
  inherited;
end;

procedure TConnector.Execute;
var blCheckMsg: boolean;
begin
  inherited;
  blCheckMsg := false;
  while not Terminated do
  with TMsgExchange do
  begin
    repeat
      blCheckMsg := CheckEncryptedMsg;
      if not blCheckMsg then
      begin
        FinishSocket;
        OpenSocket;
        Inc(FCheckAttempt);
      end;
    until blCheckMsg or (FCheckAttempt > MAX_CHECK_ATTEMPTS);
    begin
      if not blCheckMsg then
      begin
        Synchronize(ShowError);
        Terminate;
        Continue;
      end;
    end;
    sleep(1000);
  end;
end;

procedure TConnector.FinishSocket;
begin
  Shutdown(Sct, SD_Send);
  CloseSocket(Sct);
end;

function TConnector.IpAdrToSocketAdr(_sAddr: string): TInAddr;
var
  sTemp, sCec: string;
  i, iPos, iSec: integer;
  aChar: array[1..4] of u_char;
begin
  FillChar(result, SizeOf(TInAddr), 0);
  i := 0;
  sTemp := _sAddr;
  iPos := Pos(':', sTemp);
  if iPos <> 0 then
    Delete(sTemp, iPos, Length(sTemp) - iPos + 1);
  repeat
    Inc(i);
    sCec := sTemp;
    iPos := Pos('.', sTemp);
    Delete(sCec, iPos, Length(sCec) - iPos + 1);
    iSec := StrToInt(sCec);
    aChar[i] := AnsiChar(iSec);
    Delete(sTemp, 1, iPos);
  until iPos = 0;
  if i = 4 then
    with result do
    begin
      S_un_b.s_b1 := aChar[1];
      S_un_b.s_b2 := aChar[2];
      S_un_b.s_b3 := aChar[3];
      S_un_b.s_b4 := aChar[4];
    end;
end;

procedure TConnector.OpenSocket;
var
  addr: TSockAddr;
begin
  FSocketReady  := false;
  Sct := Socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
  if Sct = INVALID_SOCKET then
    Synchronize(ShowError)
  else
  begin
    PrepareAddr(addr, SERVER_IP, SERFER_PORT);
    if Connect(Sct, addr, SizeOf(addr)) = SOCKET_ERROR then
    begin
      Synchronize(ShowError);
      Exit;
    end;
    ShowState;
    FSocketReady  := true;
  end;
end;

procedure TConnector.PrepareAddr(var _addr: TSockAddr; _sAddr: AnsiString = ''; _iPort: integer = 80);
begin
  _addr.sin_family := AF_INET;
  _addr.sin_port := HtoNS(_iPort);
  FillChar(_addr.sin_zero, SizeOf(_addr.sin_zero), 0);
  _addr.sin_addr := IpAdrToSocketAdr(_sAddr);
end;

procedure TConnector.ShowState(_sState: string = '');
begin
  if _sState = '' then
    FMsgStr := 'Ok'
  else
    FMsgStr := _sState;
  Synchronize(ShowMsg);
end;

procedure TConnector.ShowError;
begin
  CrSec.Enter;
  TErrOpr.ShowError;
  CrSec.Leave;
end;

procedure TConnector.ShowMsg;
begin
  CrSec.Enter;
  TStateMsg.ShowMsg(FMsgStr);
  CrSec.Leave;
end;

end.
