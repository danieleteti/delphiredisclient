unit RedisMQ;

interface

uses
  Redis.Commons, Redis.Client;

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
  public
    const
    PREFIX = 'RMQ::';
    constructor Create(aRedisClient: IRedisClient; aUniqueID: String); virtual;
    procedure SubscribeTopic(const TopicName: String);
    procedure UnsubscribeTopic(const TopicName: String);
    procedure PublishToTopic(const TopicName, Value: String);
    function ConsumeTopic(const TopicName: String; out Value: String; Timeout: UInt64;
      const AckMode: TRMQAckMode = TRMQAckMode.AutoAck)
      : Boolean; overload;
    function ConsumeTopic(const TopicName: String; out Value: String;
      const AckMode: TRMQAckMode = TRMQAckMode.AutoAck): Boolean; overload;
    function Ack(const TopicName: String; const Value: String): Boolean;
    // function ConsumeTopics(const TopicNames: array of String; out Pair: TRMQTopicPair;
    // Timeout: UInt64): Boolean;
    function DecorateTopicNameWithClientID(const PlainTopicName: String): String;
    function UnDecorateTopicNameWithClientID(const DecoratedTopicName: String): String;
    function DecorateProcessingTopicNameWithClientID(const PlainTopicName: String): String;
    function UnDecorateProcessingTopicNameWithClientID(const DecoratedTopicName: String): String;
  end;

implementation

{ TRedisMQ }

uses RedisMQ.Commands, System.SysUtils;

// function TRedisMQ.ConsumeTopic(const TopicName: String; out Value: String; Timeout: UInt64)
// : Boolean;
// var
// lValues: TArray<string>;
// lRMQPair: TRMQTopicPair;
// begin
// Result := ConsumeTopics([TopicName], lRMQPair, Timeout);
// if Result then
// Value := lRMQPair.Value;
// end;

function TRedisMQ.ConsumeTopic(const TopicName: String; out Value: String; Timeout: UInt64;
  const AckMode: TRMQAckMode)
  : Boolean;
var
  lValues: TArray<String>;
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
        Result := FRedisClient.BRPOPLPUSH(
          DecorateTopicNameWithClientID(TopicName),
          DecorateProcessingTopicNameWithClientID(TopicName),
          Value, Timeout);
      end;
  else
    raise ERedisException.Create('Invalid AckMode');
  end;
end;

function TRedisMQ.Ack(const TopicName, Value: String): Boolean;
begin
  Result := FRedisClient.LREM(DecorateProcessingTopicNameWithClientID(TopicName), 1, Value) = 1;
end;

function TRedisMQ.ConsumeTopic(const TopicName: String;
  out Value: String; const AckMode: TRMQAckMode): Boolean;
begin
  case AckMode of
    TRMQAckMode.AutoAck:
      begin
        Result := FRedisClient.RPOP(
          DecorateTopicNameWithClientID(TopicName),
          Value);
      end;
    TRMQAckMode.ManualAck:
      begin
        Result := FRedisClient.RPOPLPUSH(
          DecorateTopicNameWithClientID(TopicName),
          DecorateProcessingTopicNameWithClientID(TopicName),
          Value);
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
begin
  FRedisClient.SREM(PREFIX + 'subs::' + TopicName, DecorateTopicNameWithClientID(TopicName));
end;

end.
