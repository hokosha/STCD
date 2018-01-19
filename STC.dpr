program STC;

uses
  Forms,
  uvSTC in 'uvSTC.pas' {fmSTC},
  uConnect in 'uConnect.pas',
  uStateMsg in 'uStateMsg.pas',
  uCommon in 'uCommon.pas',
  uMsgExchange in 'uMsgExchange.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfmSTC, fmSTC);
  Application.Run;
end.
