unit JobU;

interface

type
  TJob = class
  private
    FReplyTo: String;
    procedure SetReplyTo(const Value: String);
  public
    property ReplyTo: String read FReplyTo write SetReplyTo;
  end;

  TEvalJob = class(TJob)
  private
    FExpression: String;
    procedure SetExpression(const Value: String);
  public
    property Expression: String read FExpression write SetExpression;
  end;

  TDatabaseJob = class(TJob)
  private
    FProcedureName: String;
    procedure SetProcedureName(const Value: String);
  public
    property ProcedureName: String read FProcedureName
      write SetProcedureName;
  end;

implementation

{ TJob }

procedure TJob.SetReplyTo(const Value: String);
begin
  FReplyTo := Value;
end;

{ TEvalJob }

procedure TEvalJob.SetExpression(const Value: String);
begin
  FExpression := Value;
end;

{ TDatabaseJob }

procedure TDatabaseJob.SetProcedureName(const Value: String);
begin
  FProcedureName := Value;
end;

end.
