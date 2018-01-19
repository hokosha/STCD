unit uProxy;

interface

uses
  Windows,
  SysUtils,
  Classes,
  Dialogs,
  Generics.Collections,
//  WinSock,
  WinSock2;

type
  TErrOperate = (eoShowMsg, eoWriteFile);

type
  TErrDescription = class(TDictionary<integer, string>);

  TRedirectDict = class(TDictionary<string, string>);

type
  TErrOperates = set of TErrOperate;

type
  TBuff = array[0..1023] of AnsiChar;

type
  TServerThread = class(TThread)
    SockListen: TSocket;
    ErrOperate: TErrOperates;
    RedirectDict: TRedirectDict;
    constructor Create(_IntPort, _ExtPort: Integer; _sIntAddr, _sExtAddr: string; _eo: TErrOperates);
    destructor Destroy; override;
  protected
    procedure Execute; override;
  private
    FIntPort: Integer;
    FExtPort: Integer;
    FIntAddr: string;
    FExtAddr: string;
    procedure GetRedirectDictionary;
  public
    property IntPort: Integer read FIntPort write FIntPort;
    property ExtPort: Integer read FExtPort write FExtPort;
    property IntAddr: string read FIntAddr write FIntAddr;
    property ExtAddr: string read FExtAddr write FExtAddr;
    procedure ErrOpr(_sProcName: string);
  end;

type
  TClientThread = class(TThread)
    SockInt: TSocket;
    ErrOperate: TErrOperates;
    RedirectDict: TRedirectDict;
    constructor Create(_sock: TSocket; _ProxyPort: Integer; _ProxyAddr: string; _eo: TErrOperates);
    destructor Destroy; override;
  protected
    procedure Execute; override;
  private
    FProxyPort: Integer;
    FProxyAddr: string;
    procedure ErrOpr(_sProcName: string);
  public
    procedure ReturnString(_s: AnsiString);
    var
      ThreadNum: integer;
  end;

type
  TProxyServer = class
    ServerThread: TServerThread;
    constructor Create;
    destructor Destroy; override;
  private
    FLibOk: Boolean;
    function LoadSocketLib: Boolean;
  public
    procedure StartThread;
  end;

procedure FillErrorDescriptions;

procedure ErrorOperate(_sProcName: string; _eo: TErrOperates);

procedure WriteLog(_sMsg: string);

function PrepareAddr(var _addr: TSockAddr; _sAddr: AnsiString = ''; _iPort: integer = 80; _eo: TErrOperates = []): boolean;

procedure SaveBuf(_buff: TBuff; _fn: string);

procedure SaveString(_s: string; _fn: string);

function IpAdrToSocketAdr(_sAddr: string): TinAddr;

const
  BUFFLEN = 1024;

var
  ErrDescr: TErrDescription;

implementation

procedure FillErrorDescriptions;
begin
  ErrDescr := TErrDescription.Create;
  ErrDescr.Add(WSANOTINITIALISED, 'Socket library not initialized');
  ErrDescr.Add(WSAEAFNOSUPPORT, 'An address is incompatible with the requested protocol');
  ErrDescr.Add(WSAEINTR, 'A blocking operation was interrupted by a call to WSACancelBlockingCall');
{$REGION ''}
{
  ErrDescr.Add(WSAEBADF, '');
  ErrDescr.Add(WSAEACCES, '');
  ErrDescr.Add(WSAEFAULT, '');
  ErrDescr.Add(WSAEINVAL, '');
  ErrDescr.Add(WSAEMFILE, '');
  ErrDescr.Add(WSAEWOULDBLOCK, '');
  ErrDescr.Add(WSAEINPROGRESS, '');
  ErrDescr.Add(WSAEALREADY, '');
  ErrDescr.Add(WSAENOTSOCK, '');
  ErrDescr.Add(WSAEDESTADDRREQ, '');
  ErrDescr.Add(WSAEMSGSIZE, '');
  ErrDescr.Add(WSAEPROTOTYPE, '');
  ErrDescr.Add(WSAENOPROTOOPT, '');
  ErrDescr.Add(WSAEPROTONOSUPPORT, '');
  ErrDescr.Add(WSAESOCKTNOSUPPORT, '');
  ErrDescr.Add(WSAEOPNOTSUPP, '');
  ErrDescr.Add(WSAEPFNOSUPPOR, '');
  ErrDescr.Add(WSAEADDRINUSE, '');
  ErrDescr.Add(WSAEADDRNOTAVAIL, '');
  ErrDescr.Add(WSAENETDOWN, '');
  ErrDescr.Add(WSAENETUNREACH, '');
  ErrDescr.Add(WSAENETRESET, '');
  ErrDescr.Add(WSAECONNABORTED, '');
  ErrDescr.Add(WSAECONNRESET, '');
  ErrDescr.Add(WSAENOBUFS, '');
  ErrDescr.Add(WSAEISCONN, '');
  ErrDescr.Add(WSAENOTCONN, '');
  ErrDescr.Add(WSAESHUTDOWN, '');
  ErrDescr.Add(WSAETOOMANYREFS, '');
  ErrDescr.Add(WSAETIMEDOUT, '');
  ErrDescr.Add(WSAECONNREFUSED, '');
  ErrDescr.Add(WSAELOOP, '');
  ErrDescr.Add(WSAENAMETOOLONG, '');
  ErrDescr.Add(WSAEHOSTDOWN, '');
  ErrDescr.Add(WSAEHOSTUNREACH, '');
  ErrDescr.Add(WSAENOTEMPTY, '');
  ErrDescr.Add(WSAEPROCLIM, '');
  ErrDescr.Add(WSAEUSERS, '');
  ErrDescr.Add(WSAEDQUOT, '');
  ErrDescr.Add(WSAESTALE, '');
  ErrDescr.Add(WSAEREMOTE, '');
  ErrDescr.Add(WSASYSNOTREADY, '');
  ErrDescr.Add(WSAVERNOTSUPPORTED, '');
  ErrDescr.Add(WSAEDISCON, '')
  ErrDescr.Add(WSAENOMORE, '');
  ErrDescr.Add(WSAECANCELLED, '');
  ErrDescr.Add(WSAEEINVALIDPROCTABLE, '');
  ErrDescr.Add(WSAEINVALIDPROVIDER, '');
  ErrDescr.Add(WSAEPROVIDERFAILEDINIT, '');
  ErrDescr.Add(WSASYSCALLFAILURE, '');
  ErrDescr.Add(WSASERVICE_NOT_FOUND, '');
  ErrDescr.Add(WSATYPE_NOT_FOUN, '');
  ErrDescr.Add(WSA_E_NO_MORE, '');
  ErrDescr.Add(WSA_E_CANCELLED, '');
  ErrDescr.Add(WSAEREFUSED, '');
  ErrDescr.Add(WSAHOST_NOT_FOUND, '');
  ErrDescr.Add(WSATRY_AGAIN, '');
  ErrDescr.Add(WSANO_RECOVERY, '');
  ErrDescr.Add(WSANO_DATA, '');
}
{$ENDREGION}
end;

procedure ErrorOperate(_sProcName: string; _eo: TErrOperates);
var
  sErr, sMsg: string;
  iErr: Integer;
begin
  if _eo = [] then
    Exit;
  sErr := '';
  sMsg := 'Socket Error in procedure ' + _sProcName;
  iErr := WSAGetLastError;
  if ErrDescr.ContainsKey(iErr) then
    ErrDescr.TryGetValue(iErr, sErr);
  if sErr = '' then
    sMsg := sMsg + ': error ' + IntToStr(iErr)
  else
    sMsg := sMsg + ': ' + sErr;
  if eoShowMsg in _eo then
    ShowMessage(sMsg);
  if eoWriteFile in _eo then
    WriteLog(sMsg);
end;

function IpAdrToSocketAdr(_sAddr: string): TInAddr;
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

function PrepareAddr(var _addr: TSockAddr; _sAddr: AnsiString = ''; _iPort: integer = 80; _eo: TErrOperates = []): boolean;
var
  HostEnt: PHostEnt;
  inAdr: PInAddr;
  iLen, iErr: integer;

  function UrlIsIPAdress(_sUrl: AnsiString): boolean;
  var
    ch: AnsiChar;
  begin
    result := true;
    for ch in _sUrl do
      if not (ch in ['0'..'9', '.', ':']) then
      begin
        result := false;
        break;
      end;
  end;

begin
  result := false;
  inAdr := nil;

  _addr.sin_family := AF_INET;
  _addr.sin_port := HtoNS(_iPort);
  FillChar(_addr.sin_zero, SizeOf(_addr.sin_zero), 0);
  if _sAddr = '' then
    _addr.sin_addr.S_addr := InAddr_Any
  else
  begin
    if UrlIsIPAdress(_sAddr) then
      _addr.sin_addr := IpAdrToSocketAdr(_sAddr)
    else
    begin
      FillChar(_addr.sin_addr, SizeOf(_addr.sin_addr), 0);
      HostEnt := gethostbyname(PAnsiChar(_sAddr));
//        iErr := WSAAsyncGetHostByName(0, 0, PChar(_sAddr), @HostEnt, MAXGETHOSTSTRUCT); // _sAddr
//        if iErr = 0 then
      if HostEnt = nil then
//          ErrorOperate('WSAAsyncGetHostByName', _eo)
        ErrorOperate('gethostbyname', _eo)
      else
      begin
        try
          inAdr := HostEnt.h_addr^;
        except
          ErrorOperate('Prepare address ' + _sAddr, _eo);
          exit;
        end;
        _addr.sin_addr := inAdr^;
      end;
    end;
  end;
  result := true;
end;

procedure WriteLog(_sMsg: string);
begin

end;

procedure SaveBuf(_buff: TBuff; _fn: string);
var
  ms: TMemoryStream;
begin
  ms := TMemoryStream.Create;
  try
    ms.WriteBuffer(_buff, BUFFLEN);
    ms.SaveToFile('buf\' + _fn);
  finally
    ms.Free;
  end;
end;

procedure SaveString(_s: string; _fn: string);
var
  ss: TStringStream;
begin
  ss := TStringStream.Create(_s);
  try
    ss.SaveToFile(_fn);
  finally
    ss.Free;
  end;
end;

{$REGION '***  TProxyServer ***'}
constructor TProxyServer.Create;
begin
  inherited;
  FillErrorDescriptions;
  FLibOk := LoadSocketLib;
  if FLibOk then
    StartThread;
end;

destructor TProxyServer.Destroy;
begin

  inherited;
end;

function TProxyServer.LoadSocketLib: Boolean;
var
  wData: TWSAData;
begin
  Result := WSAStartup($0202, wData) = 0;
end;

procedure TProxyServer.StartThread;
var
  st: TServerThread;
begin
  st := TServerThread.Create(8080, 0, '', '', [eoShowMsg]);
  if st.SockListen <> INVALID_SOCKET then
    st.Start;
end;

{$ENDREGION}

{$REGION '*** TServerThread ***'}
constructor TServerThread.Create(_IntPort, _ExtPort: Integer; _sIntAddr, _sExtAddr: string; _eo: TErrOperates);
var
  addrIn: TSockAddr;
begin
  inherited Create(True);
  FreeOnTerminate := True;
  IntPort := _IntPort;
  ExtPort := _ExtPort;
  IntAddr := _sIntAddr;
  ExtAddr := _sExtAddr;
  ErrOperate := _eo;
  GetRedirectDictionary;

  SockListen := WSASocket(AF_INET, SOCK_STREAM, IPPROTO_TCP, nil, 0, WSA_Flag_Overlapped);
  if SockListen = INVALID_SOCKET then
  begin
    ErrOpr('Create input socket');
    Exit;
  end;

  PrepareAddr(addrIn, '', FIntPort, ErrOperate);
  if bind(SockListen, @addrIn, SizeOf(addrIn)) <> 0 then
  begin
    ErrOpr('Bind input socket');
    Exit;
  end;
  if listen(SockListen, 4) <> 0 then
  begin
    ErrOpr('Listen input socket');
    Exit;
  end;
end;

destructor TServerThread.Destroy;
begin

  inherited;
end;

procedure TServerThread.ErrOpr(_sProcName: string);
begin
  ErrorOperate(_sProcName, ErrOperate);
end;

procedure TServerThread.Execute;
var
  sockClient: TSocket;
  addrIn: TSockAddr;
  FDSet: TFDSet;
  Len: integer;
  ClientThread: TClientThread;
  i: integer;
begin
  inherited;
  i := 0;
  while not Terminated do
  begin
    FD_Zero(FDSet);
    FD_Set(SockListen, FDSet);
    Select(0, @FDSet, nil, nil, nil);
    if FD_IsSet(SockListen, FDSet) then  // (i = 0)and()
    begin
      Inc(i);
      Len := SizeOf(TSockAddr);
      sockClient := WSAAccept(SockListen, @addrIn, @Len, nil, 0);
      if sockClient = INVALID_SOCKET then
        Continue;
      ClientThread := TClientThread.Create(sockClient, ExtPort, ExtAddr, ErrOperate);
      ClientThread.RedirectDict := self.RedirectDict;
      ClientThread.ThreadNum := i;
      ClientThread.Start;
    end;
  end;
end;

procedure TServerThread.GetRedirectDictionary;
begin
  RedirectDict := TRedirectDict.Create;
  RedirectDict.Add('thebestasiandramas.blogspot.com', '127.0.0.1');
  RedirectDict.Add('booking.com', '127.0.0.1');
  RedirectDict.Add('whoer.net', '127.0.0.1');
  RedirectDict.Add('google.com', '127.0.0.1');
  RedirectDict.Add('google.com.ua', '127.0.0.1');
  RedirectDict.Add('clients1.google.com', '127.0.0.1');
  {select redirect info from repository}
end;

{$ENDREGION}

{$REGION '*** TClientThread ***'}
constructor TClientThread.Create(_sock: TSocket; _ProxyPort: Integer; _ProxyAddr: string; _eo: TErrOperates);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FProxyPort := _ProxyPort;
  FProxyAddr := _ProxyAddr;
  SockInt := _sock;
  ErrOperate := _eo;
end;

destructor TClientThread.Destroy;
var
  sFn: string;

  procedure DelFl(s: string);
  var
    i: integer;
    s1, s2: string;
  begin
    try
      s1 := ExtractFilePath(ParamStr(0)) + 'buf\' + s + '_' + IntToStr(ThreadNum);
      if FileExists(s1) then
        DeleteFile(s1);
      for i := 1 to 50 do
      begin
        s2 := s1 + '_' + IntToStr(i);
        if FileExists(s2) then
          DeleteFile(s2)
        else
          break;
      end;
    except
    end;
  end;

begin
  DelFl('buf_in');
  DelFl('buf_in_ext');
  DelFl('buf_out_ext');
  inherited;
end;

procedure TClientThread.ErrOpr(_sProcName: string);
begin
  ErrorOperate(_sProcName, ErrOperate);
end;

procedure TClientThread.Execute;
var
  BuffSend, BufRecv: TBuff;
  sTemp, sRequest, sHostExt, sUrl, sUrlRedirect, sUrlType: string;
  asUrlRedirect: AnsiString;
  iPortExt: Integer;
  addrExt: TSockAddr;
  SockExt: TSocket;
  iMode, iSize: Integer;
  FDSet: TFDSet;
  i, j, iPos: integer;
begin
  inherited;
  Recv(SockInt, BuffSend, BUFFLEN, 0);
  SaveBuf(BuffSend, 'buf_in_' + IntToStr(ThreadNum) + '.txt');
  sRequest := string(BuffSend);
  if sRequest = '' then
  begin
    CloseSocket(SockInt);
    Exit;
  end;

  sHostExt := Copy(sRequest, Pos('sHost: ', sRequest), 255);
  if sHostExt = '' then
  begin
    ReturnString('HTTP/1.1 400 Invalid header received from browser');
    Terminate;
  end;

  if (FProxyAddr <> '') and (FProxyPort <> 0) then
  begin
    sHostExt := FProxyAddr;
    iPortExt := FProxyPort;
  end
  else
  begin
    sUrlType := '';
    iPos := Pos(#13, sHostExt);
    Delete(sHostExt, iPos, Length(sHostExt) - iPos + 1);
    iPos := Pos('http://', sHostExt) - 1;
    Delete(sHostExt, 1, iPos);
    if Pos('https://', sHostExt) <> 0 then
      sUrlType := 'https://'
    else if Pos('http://', sHostExt) <> 0 then
      sUrlType := 'http://';
    if sUrlType = '' then
    begin
      ReturnString('Invalid URL in browser request');
      Terminate;
    end;
    sUrl := StringReplace(sHostExt, sUrlType, '', []);
    iPos := Pos('HTTP', sUrl);
    if iPos <> 0 then
      Delete(sUrl, iPos, Length(sUrl) - iPos + 1);
    sUrl := Trim(sUrl);
    iPos := Pos(':', sUrl);
    if iPos = 0 then
      iPortExt := 80
    else
    begin
      iPortExt := StrToIntDef(Copy(sUrl, iPos + 1, Length(sUrl) - iPos), 80);
      Delete(sUrl, iPos, Length(sUrl) - iPos + 1);
    end;
    StringReplace(sUrl, 'www.', '', []);
    iPos := Pos('/', sUrl);
    if iPos <> 0 then
      Delete(sUrl, iPos, Length(sUrl) - iPos + 1);
    sUrlRedirect := sUrl;

    if RedirectDict.ContainsKey(sUrl) then
      RedirectDict.TryGetValue(sUrl, sUrlRedirect);
    asUrlRedirect := Ansistring(sUrlRedirect);
  end;

  if not PrepareAddr(addrExt, asUrlRedirect, iPortExt, ErrOperate) then
  begin
    ErrorOperate('Prepare adress', ErrOperate);
    ReturnString('Invalid redirect URL');
    Terminate;
  end;

  SockExt := WSASocket(AF_INET, SOCK_STREAM, IPPROTO_TCP, nil, 0, WSA_Flag_Overlapped);
  if SockExt = INVALID_SOCKET then
  begin
    ReturnString('Create redirect socket fail');
    ErrOpr('Create proxy exit socket');
    Terminate;
  end;

  if Connect(SockExt, @addrExt, SizeOf(addrExt)) = SOCKET_ERROR then
  begin
    ReturnString('Error 404: Host not found');
    CloseSocket(SockExt);
    Terminate;
  end;

  iMode := 1;
  SetSockOpt(SockExt, IPPROTO_TCP, TCP_NODELAY, @iMode, SizeOf(integer));
  send(SockExt, BuffSend, StrLen(BuffSend), 0);
  i := 0;
  j := 0;
  while not Terminated do
  begin
    FD_ZERO(FDSet);
    FD_SET(SockInt, FDSet);
    FD_SET(SockExt, FDSet);

    if select(0, @FDSet, nil, nil, nil) < 0 then
      Break;

    if FD_ISSET(SockInt, FDSet) then
    begin
      inc(i);
      iSize := recv(SockInt, BuffSend, SizeOf(BuffSend), 0);
      if iSize <= 0 then
        Break;
      send(SockExt, BuffSend, iSize, 0);
      SaveBuf(BuffSend, 'buf_out_ext_' + IntToStr(ThreadNum) + '_' + IntToStr(i) + '.txt');
      Continue;
    end;

    if FD_ISSET(SockExt, FDSet) then
    begin
      inc(j);
      iSize := recv(SockExt, BufRecv, SizeOf(BufRecv), 0);
      SaveBuf(BufRecv, 'buf_in_ext_' + IntToStr(ThreadNum) + '_' + IntToStr(j) + '.txt');
      if iSize <= 0 then
      begin
        CloseSocket(SockInt);
        Shutdown(SockExt, SD_Send);
        CloseSocket(SockExt);
        Terminate;
      end;

      send(SockInt, BufRecv, iSize, 0);
      Continue;
    end;
  end;
end;

procedure TClientThread.ReturnString(_s: AnsiString);
begin
  send(SockInt, TBytes(_s), Length(_s), 0);
  CloseSocket(SockInt);
end;
{$ENDREGION}

end.

