unit uCommon;

interface

uses
  SyncObjs;

const
  SERVER_IP = '149.154.167.51';
  SERFER_PORT = 80;
  MAX_CHECK_ATTEMPTS: byte = 2;

var
  CrSec: TCriticalSection;
  sErrMsg: string;
  sMsg: string;

implementation

end.

