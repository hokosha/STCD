unit uStateMsg;

interface

uses
  Graphics,
  uCommon;

type
  TErrOpr = class
    class procedure ShowError;
  private
  end;

type
  TStateMsg = class
    class procedure ShowMsg(_sMsg: string = 'Ok');
  private
  end;

implementation

uses
  uvSTC;

{ TErrOpr }

class procedure TErrOpr.ShowError;
begin
  sErrMsg := 'Error';
  fmSTC.lblState.Caption := sErrMsg;
  fmSTC.lblState.Font.Color := clRed;
  fmSTC.Update;
end;

{ TStateMsg }

class procedure TStateMsg.ShowMsg(_sMsg: string = 'Ok');
begin
  fmSTC.lblState.Caption := _sMsg;
  fmSTC.lblState.Font.Color := clNavy;
  fmSTC.Update;
end;

end.

