unit RedisMQ.Commands;

interface

const
  LUA_DISTRIBUTE_ITEM =
    'local queues, newitem, i, count ' +
    'count = 0 ' +
    'while true do ' +
    '  newitem = redis.call("RPOP",KEYS[1]) ' + // topic name
    '  if not newitem then ' +
    '    break ' +
    '  end ' +
    '  queues = redis.call("SMEMBERS",KEYS[2]) ' + // set with the subscribers
    '  for i = 1, #queues, 1 do ' +
    '    count = count + 1 ' +
    '    redis.call("LPUSH",queues[i],newitem) ' +
    '  end ' +
    'end ' +
    'return count';

implementation

end.
