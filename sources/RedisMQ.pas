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


unit RedisMQ;

interface

uses
  Redis.Commons, Redis.Client, IdHashMessageDigest;

type
  TRMQTopicPair = record
    Topic: string;
    Value: string;
  end;

  TRMQAckMode = (AutoAck, ManualAck);

  TRedisMQ = class
  private
    FRedisClient: IRedisClient;
    FID: string;
    FHashMessageDigest5: TIdHashMessageDigest5;
    function GenerateMessageID(const aTopicName, aMessage: string): string;
  public
    const
    PREFIX = 'RMQ::';
    constructor Create(aRedisClient: IRedisClient; aUniqueID: string); virtual;
    destructor Destroy; override;
    procedure SubscribeTopic(const TopicName: string);
    procedure UnsubscribeTopic(const TopicName: string);
    procedure PublishToTopic(const TopicName, Value: string);
    function ConsumeTopic(const TopicName: string; out Value: string; out MessageID: string;
      Timeout: UInt64;
      const AckMode: TRMQAckMode = TRMQAckMode.AutoAck)
      : Boolean; overload;
    function ConsumeTopic(const TopicName: string; out Value: string; out MessageID: string;
      const AckMode: TRMQAckMode = TRMQAckMode.AutoAck): Boolean; overload;
    function Ack(const TopicName, MessageID: string): Boolean;
    // function ConsumeTopics(const TopicNames: array of String; out Pair: TRMQTopicPair;
    // Timeout: UInt64): Boolean;
    function DecorateTopicNameWithClientID(const PlainTopicName: string): string;
    function UnDecorateTopicNameWithClientID(const DecoratedTopicName: string): string;
    function DecorateProcessingTopicNameWithClientID(const PlainTopicName: string): string;
    function UnDecorateProcessingTopicNameWithClientID(const DecoratedTopicName: string): string;
  end;

implementation

{ TRedisMQ }

uses RedisMQ.Commands, System.SysUtils, IdGlobal, IdHash, Redis.Values;

function TRedisMQ.ConsumeTopic(const TopicName: string; out Value: string; out MessageID: string;
  Timeout: UInt64;
  const AckMode: TRMQAckMode)
  : Boolean;
var
  lProcessingTopicNameWithClientID: string;
  lTopicNameWithClientID: string;
  lResArray: TRedisArray;
begin
  case AckMode of
    AutoAck:
      begin
        lResArray := FRedisClient.BRPOP(
          DecorateTopicNameWithClientID(TopicName),
          Timeout);
        Result := lResArray.HasValue;
        if Result then
          Value := lResArray.Value[1]
        else
          Value := '';
      end;

    ManualAck:
      begin
        lProcessingTopicNameWithClientID := DecorateProcessingTopicNameWithClientID(TopicName);
        lTopicNameWithClientID := DecorateTopicNameWithClientID(TopicName);
        Result := FRedisClient.BRPOPLPUSH(
          lTopicNameWithClientID,
          lProcessingTopicNameWithClientID,
          Value, Timeout);
        if Result then
        begin
          MessageID := GenerateMessageID(lTopicNameWithClientID, Value);
          FRedisClient.HSET(lProcessingTopicNameWithClientID + '::hashmap', MessageID, Value);
        end;

      end;
  else
    raise ERedisException.Create('Invalid AckMode');
  end;
end;

function TRedisMQ.Ack(const TopicName, MessageID: string): Boolean;
var
  lTopicNameWithClientID: string;
  lValue: string;
begin
  { TODO -oDaniele -cGeneral : Put this is a LUA SCRIPT }
  lTopicNameWithClientID := DecorateProcessingTopicNameWithClientID(TopicName);
  Result := FRedisClient.HGET(lTopicNameWithClientID + '::hashmap', MessageID, lValue);
  if Result then
  begin
    Result := FRedisClient.LREM(lTopicNameWithClientID, 1, lValue) = 1;
    Result := Result and (1 = FRedisClient.HDEL(lTopicNameWithClientID + '::hashmap', [MessageID]));
  end;
end;

function TRedisMQ.ConsumeTopic(const TopicName: string;
  out Value: string; out MessageID: string; const AckMode: TRMQAckMode): Boolean;
var
  lTopicNameWithClientID: string;
  lProcessingTopicNameWithClientID: string;
begin
  lTopicNameWithClientID := DecorateTopicNameWithClientID(TopicName);
  case AckMode of
    TRMQAckMode.AutoAck:
      begin
        Result := FRedisClient.RPOP(
          lTopicNameWithClientID,
          Value);
      end;
    TRMQAckMode.ManualAck:
      begin
        lProcessingTopicNameWithClientID := DecorateProcessingTopicNameWithClientID(TopicName);
        Result := FRedisClient.RPOPLPUSH(
          lTopicNameWithClientID,
          lProcessingTopicNameWithClientID,
          Value);
        if Result then
        begin
          MessageID := GenerateMessageID(lTopicNameWithClientID, Value);
          FRedisClient.HSET(lProcessingTopicNameWithClientID + '::hashmap', MessageID, Value);
        end;
      end;
  else
    raise ERedisException.Create('Invalid AckMode');
  end;

end;

// function TRedisMQ.ConsumeTopics(const TopicNames: array of String; out Pair: TRMQTopicPair;
// Timeout: UInt64): Boolean;
// var
// lTopics: array of string;
// lValues: TArray<String>;
// I: Integer;
// begin
// SetLength(lTopics, Length(TopicNames));
// for I := 0 to Length(lTopics) - 1 do
// begin
// lTopics[I] := DecorateTopicNameWithClientID(TopicNames[I]);
// end;
// Result := FRedisClient.BRPOP(lTopics, Timeout, lValues);
// if Result then
// begin
// Pair.Topic := UnDecorateTopicNameWithClientID(lValues[0]);
// Pair.Value := lValues[1];
// end;
// end;

constructor TRedisMQ.Create(aRedisClient: IRedisClient; aUniqueID: string);
begin
  inherited Create;
  FRedisClient := aRedisClient;
  FID := aUniqueID;
  FHashMessageDigest5 := TIdHashMessageDigest5.Create;
end;

function TRedisMQ.DecorateProcessingTopicNameWithClientID(
  const PlainTopicName: string): string;
begin
  Result := PREFIX + FID + '::processing::' + PlainTopicName;
end;

function TRedisMQ.DecorateTopicNameWithClientID(const PlainTopicName: string): string;
begin
  Result := PREFIX + FID + '::' + PlainTopicName;
end;

destructor TRedisMQ.Destroy;
begin
  FHashMessageDigest5.Free;
  inherited;
end;

function TRedisMQ.GenerateMessageID(const aTopicName, aMessage: string): string;
begin
  Result := IntToStr(FRedisClient.INCR(PREFIX + aTopicName + '::uuid'));
end;

procedure TRedisMQ.PublishToTopic(const TopicName, Value: string);
begin
  FRedisClient.LPUSH(PREFIX + TopicName, [Value]);
  FRedisClient.EVAL(LUA_DISTRIBUTE_ITEM, [PREFIX + TopicName, PREFIX + 'subs::' + TopicName], []);
end;

procedure TRedisMQ.SubscribeTopic(const TopicName: string);
begin
  FRedisClient.SADD(PREFIX + 'subs::' + TopicName, DecorateTopicNameWithClientID(TopicName));
end;

function TRedisMQ.UnDecorateProcessingTopicNameWithClientID(
  const DecoratedTopicName: string): string;
begin
  Result := DecoratedTopicName.Remove(0, PREFIX.LEngth + LEngth(FID) + LEngth('::processing::'));
end;

function TRedisMQ.UnDecorateTopicNameWithClientID(const DecoratedTopicName: string): string;
begin
  Result := DecoratedTopicName.Remove(0, PREFIX.LEngth + LEngth(FID) + 2);
end;

procedure TRedisMQ.UnsubscribeTopic(const TopicName: string);
var
  lKeyName: string;
begin
  lKeyName := PREFIX + 'subs::' + TopicName;
  FRedisClient.SREM(lKeyName, DecorateTopicNameWithClientID(TopicName));
end;

end.
