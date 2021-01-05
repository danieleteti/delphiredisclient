unit MainFormU;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.AppEvnts, System.Threading, LoggerPro.GlobalLogger, Redis.Commons, Redis.Client, Redis.Values, Redis.NetLib.Indy;

type
  TMainForm = class(TForm)
    Memo1: TMemo;
    Panel1: TPanel;
    Splitter1: TSplitter;
    btnConn: TButton;
    ApplicationEvents1: TApplicationEvents;
    pnlToolbar: TPanel;
    btnSubscription: TButton;
    btnXADD: TButton;
    btnXRANGE: TButton;
    btnAnotherMe: TButton;
    btnXREAD: TButton;
    btnBulkXADD: TButton;
    procedure btnConnClick(Sender: TObject);
    procedure ApplicationEvents1Idle(Sender: TObject; var Done: Boolean);
    procedure btnXADDClick(Sender: TObject);
    procedure btnSubscriptionClick(Sender: TObject);
    procedure btnXRANGEClick(Sender: TObject);
    procedure btnAnotherMeClick(Sender: TObject);
    procedure btnXREADClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnBulkXADDClick(Sender: TObject);
  private
    fRedis: IRedisClient;
    fTask: ITask;
    fLastXRANGEID, fLastXREADID: String;
    procedure Log(const MSG: String);
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

uses
  Winapi.ShellAPI;

{$R *.dfm}


procedure TMainForm.ApplicationEvents1Idle(Sender: TObject; var Done: Boolean);
begin
  if Assigned(fRedis) then
  begin
    btnConn.Caption := 'Disconnect';
  end
  else
  begin
    btnConn.Caption := 'Connect';
  end;
  pnlToolbar.Visible := Assigned(fRedis);

  if fLastXRANGEID.IsEmpty then
  begin
    btnXRANGE.Caption := 'XRANGE (get all)';
  end
  else
  begin
    btnXRANGE.Caption := 'XRANGE (' + fLastXRANGEID + ')';
  end;

  if fLastXREADID.IsEmpty then
  begin
    btnXREAD.Caption := 'XREAD (get new)';
  end
  else
  begin
    btnXREAD.Caption := 'XREAD ( > ' + fLastXREADID + ')';
  end;

end;

procedure TMainForm.btnAnotherMeClick(Sender: TObject);
begin
  ShellExecute(0, pchar('open'), pchar(ParamStr(0)), nil, nil, SW_SHOW);
end;

procedure TMainForm.btnBulkXADDClick(Sender: TObject);
var
  lCmd: IRedisCommand;
  lRes: TRedisNullable<string>;
  I: Integer;
begin
  // XADD mystream MAXLEN ~ 1000 * ... entry fields here ...
  for I := 1 to 50000 do
  begin
    lCmd := NewRedisCommand('XADD');
    lCmd
      .Add('mystream')
      .Add('MAXLEN')
      .Add('~')
      .Add(200000)
      .Add('*')
      .Add('key' + I.ToString)
      .Add(Format('Value %4.4d',[I]));
    lRes := fRedis.ExecuteWithStringResult(lCmd);
  end;
//  Log(lRes.Value);
end;

procedure TMainForm.btnConnClick(Sender: TObject);
begin
  if Assigned(fRedis) then
  begin
    fRedis.Disconnect;
    fRedis := nil;
  end
  else
  begin
    fRedis := NewRedisClient();
  end;

end;

procedure TMainForm.btnSubscriptionClick(Sender: TObject);
begin
  fTask := TTask.Run(
    procedure
    begin
      var lRedis := NewRedisClient();
      var lLastID := '';
      while TTask.CurrentTask.Status <> TTaskStatus.Canceled do
      begin
        var lCmd := NewRedisCommand('XREAD');
        lCmd.Add('BLOCK');
        lCmd.Add('5000');
        lCmd.Add('STREAMS');
        lCmd.Add('mystream');

        // XRANGE key start end [COUNT count]
        if lLastID.IsEmpty then
        begin
          lCmd.Add('$');
        end
        else
        begin
          lCmd.Add(lLastID);
        end;
        var lRes: TRedisRESPArray := lRedis.ExecuteAndGetRESPArray(lCmd);
        if not Assigned(lRes) then
        begin
          Log('Timeout');
          Continue;
        end;
        try
          Log(lRes.ToJSON());
          if lRes.Count > 0 then
          begin
            var
            lSizeOfMyStreamArray := lRes
              .Items[0].ArrayValue
              .Items[1].ArrayValue
              .Count;

            lLastID := lRes
              .Items[0].ArrayValue
              .Items[1].ArrayValue
              .Items[lSizeOfMyStreamArray - 1].ArrayValue
              .Items[0].Value;
          end;
        finally
          lRes.Free;
        end;
      end;
      lRedis.Disconnect();
    end);
end;

procedure TMainForm.btnXADDClick(Sender: TObject);
var
  lCmd: IRedisCommand;
  lRes: TRedisNullable<string>;
begin
  // XADD mystream MAXLEN ~ 1000 * ... entry fields here ...
  lCmd := NewRedisCommand('XADD');
  lCmd
    .Add('mystream')
    .Add('MAXLEN')
    .Add('~')
    .Add(10)
    .Add('*')
    .Add('key1')
    .Add('001' + DateTimeToStr(now))
    .Add('key2')
    .Add('002' + DateTimeToStr(now));
  lRes := fRedis.ExecuteWithStringResult(lCmd);
  Log(lRes.Value);
end;

procedure TMainForm.btnXRANGEClick(Sender: TObject);
begin
  var lCmd := NewRedisCommand('XRANGE');
  lCmd.Add('mystream');

  // XRANGE key start end [COUNT count]
  if fLastXRANGEID.IsEmpty then
  begin
    lCmd.Add('-').Add('+');
  end
  else
  begin
    var
    lPieces := fLastXRANGEID.Split(['-']);
    lCmd.Add(lPieces[0] + '-' + (lPieces[1].ToInteger + 1).ToString).Add('+');
  end;
  var lRes: TRedisRESPArray := fRedis.ExecuteAndGetRESPArray(lCmd);
  try
    Log(lRes.ToJSON());
    if lRes.Count > 0 then
    begin
      fLastXRANGEID := lRes.Items[lRes.Count - 1].ArrayValue.Items[0].Value;
    end;
  finally
    lRes.Free;
  end;
end;

procedure TMainForm.btnXREADClick(Sender: TObject);
begin
  var lCmd := NewRedisCommand('XREAD');
  lCmd.Add('BLOCK');
  lCmd.Add('5000');
  lCmd.Add('STREAMS');
  lCmd.Add('mystream');

  // XRANGE key start end [COUNT count]
  if fLastXREADID.IsEmpty then
  begin
    lCmd.Add('$');
  end
  else
  begin
    lCmd.Add(fLastXREADID);
  end;
  var lRes: TRedisRESPArray := fRedis.ExecuteAndGetRESPArray(lCmd);
  if not Assigned(lRes) then
  begin
    Log('Timeout');
    Exit;
  end;
  try
    Log(lRes.ToJSON());
    if lRes.Count > 0 then
    begin
      var lSizeOfMyStreamArray := lRes
        .Items[0].ArrayValue
        .Items[1].ArrayValue
        .Count;

      fLastXREADID := lRes
        .Items[0].ArrayValue
        .Items[1].ArrayValue
        .Items[lSizeOfMyStreamArray-1].ArrayValue
        .Items[0].Value;
    end;
  finally
    lRes.Free;
  end;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if Assigned(fTask) then
  begin
    fTask.Cancel;
    fTask := nil;
  end;
end;

procedure TMainForm.Log(const MSG: String);
var
  lValue: String;
begin
  lValue := MSG;
  var lThreadID := TThread.CurrentThread.ThreadID;
  TThread.Queue(nil,
    procedure
    begin
      if Assigned(Memo1) then
      begin
        Memo1.Lines.Add(Format('[TID %d] %s', [lThreadID, lValue]));
      end;
    end);
end;

end.
