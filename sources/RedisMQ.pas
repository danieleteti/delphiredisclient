unit RedisMQ;

interface

uses
  Redis.Commons, Redis.Client, IdHashMessageDigest;

type
  TRMQTopicPair = record
    Topic: String;
    Value: String;
  end;

  TRMQAckMode = (AutoAck, ManualAck);

  TRedisMQ = class
  private
    FRedisClient: IRedisClient;
    FID: string;
    FHashMessageDigest5: TIdHashMessageDigest5;
    function GenerateMessageID(const aTopicName, aMessage: String): String;
  public
    const
    PREFIX = 'RMQ::';
    constructor Create(aRedisClient: IRedisClient; aUniqueID: String); virtual;
    destructor Destroy; override;
    procedure SubscribeTopic(const TopicName: String);
    procedure UnsubscribeTopic(const TopicName: String);
    procedure PublishToTopic(const TopicName, Value: String);
    function ConsumeTopic(const TopicName: String; out Value: String; out MessageID: String;
      Timeout: UInt64;
      const AckMode: TRMQAckMode = TRMQAckMode.AutoAck)
      : Boolean; overload;
    function ConsumeTopic(const TopicName: String; out Value: String; out MessageID: String;
      const AckMode: TRMQAckMode = TRMQAckMode.AutoAck): Boolean; overload;
    function Ack(const TopicName, MessageID: String): Boolean;
    // function ConsumeTopics(const TopicNames: array of String; out Pair: TRMQTopicPair;
    // Timeout: UInt64): Boolean;
    function DecorateTopicNameWithClientID(const PlainTopicName: String): String;
    function UnDecorateTopicNameWithClientID(const DecoratedTopicName: String): String;
    function DecorateProcessingTopicNameWithClientID(const PlainTopicName: String): String;
    function UnDecorateProcessingTopicNameWithClientID(const DecoratedTopicName: String): String;
  end;

implementation

{ TRedisMQ }

uses RedisMQ.Commands, System.SysUtils, IdGlobal, IdHash;

function TRedisMQ.ConsumeTopic(const TopicName: String; out Value: String; out MessageID: String;
  Timeout: UInt64;
  const AckMode: TRMQAckMode)
  : Boolean;
var
  lValues: TArray<String>;
  lProcessingTopicNameWithClientID: string;
  lTopicNameWithClientID: string;
begin
  case AckMode of
    AutoAck:
      begin
        Result := FRedisClient.BRPOP(
          DecorateTopicNameWithClientID(TopicName),
          Timeout,
          lValues);
        if Result then
          Value := lValues[1]
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

function TRedisMQ.Ack(const TopicName, MessageID: String): Boolean;
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

function TRedisMQ.ConsumeTopic(const TopicName: String;
  out Value: String; out MessageID: String; const AckMode: TRMQAckMode): Boolean;
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

constructor TRedisMQ.Create(aRedisClient: IRedisClient; aUniqueID: String);
begin
  inherited Create;
  FRedisClient := aRedisClient;
  FID := aUniqueID;
  FHashMessageDigest5 := TIdHashMessageDigest5.Create;
end;

function TRedisMQ.DecorateProcessingTopicNameWithClientID(
  const PlainTopicName: String): String;
begin
  Result := PREFIX + FID + '::processing::' + PlainTopicName;
end;

function TRedisMQ.DecorateTopicNameWithClientID(const PlainTopicName: String): String;
begin
  Result := PREFIX + FID + '::' + PlainTopicName;
end;

destructor TRedisMQ.Destroy;
begin
  FHashMessageDigest5.Free;
  inherited;
end;

function TRedisMQ.GenerateMessageID(const aTopicName, aMessage: String): String;
begin
  Result := IntToStr(FRedisClient.INCR(PREFIX + aTopicName + '::uuid'));
end;

procedure TRedisMQ.PublishToTopic(const TopicName, Value: String);
begin
  FRedisClient.LPUSH(PREFIX + TopicName, [Value]);
  FRedisClient.EVAL(LUA_DISTRIBUTE_ITEM, [PREFIX + TopicName, PREFIX + 'subs::' + TopicName], []);
end;

procedure TRedisMQ.SubscribeTopic(const TopicName: String);
begin
  FRedisClient.SADD(PREFIX + 'subs::' + TopicName, DecorateTopicNameWithClientID(TopicName));
end;

function TRedisMQ.UnDecorateProcessingTopicNameWithClientID(
  const DecoratedTopicName: String): String;
begin
  Result := DecoratedTopicName.Remove(0, PREFIX.LEngth + LEngth(FID) + LEngth('::processing::'));
end;

function TRedisMQ.UnDecorateTopicNameWithClientID(const DecoratedTopicName: String): String;
begin
  Result := DecoratedTopicName.Remove(0, PREFIX.LEngth + LEngth(FID) + 2);
end;

procedure TRedisMQ.UnsubscribeTopic(const TopicName: String);
var
  lKeyName: string;
begin
  lKeyName := PREFIX + 'subs::' + TopicName;
  FRedisClient.SREM(lKeyName, DecorateTopicNameWithClientID(TopicName));
end;

end.
