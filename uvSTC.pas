unit uvSTC;

interface

uses
  Windows,
  Messages,
  SysUtils,
  Variants,
  Classes,
  Graphics,
  Controls,
  Forms,
  WinSock,
  Dialogs,
  StdCtrls,
  SyncObjs,

  uCommon,
  uConnect;

type
  TfmSTC = class(TForm)
    lblState: TLabel;
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private
    Conn: TConnector;
  public

  end;

var
  fmSTC: TfmSTC;

implementation

{$R *.dfm}

procedure TfmSTC.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if Conn <> nil then
    Conn.Terminate;
end;

procedure TfmSTC.FormCreate(Sender: TObject);
var
  wData: TWSAData;
begin
  if WSAStartup($101, wData) <> 0 then  // initialization of wsock32.dll
  begin
    ShowMessage('Loading of wsock32.dll library fault');
    Close;
  end;
  CrSec := TCriticalSection.Create;
end;

procedure TfmSTC.FormShow(Sender: TObject);
begin
  Conn := TConnector.Create;
  if Conn.SocketReady then
    Conn.Start;
end;

end.
