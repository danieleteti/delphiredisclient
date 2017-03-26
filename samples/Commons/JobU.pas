// *************************************************************************** }
//
// Delphi REDIS Client
//
// Copyright (c) 2015-2017 Daniele Teti
//
// https://github.com/danieleteti/delphiredisclient
//
// ***************************************************************************
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// ***************************************************************************

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
