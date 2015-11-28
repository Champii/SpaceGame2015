require! {
  nodulator: N
}

class Queue extends N \queue schema: \strict

  @Timeout = @_WrapPromise (item, done) ->
    delay = item.delay
    newDone = (err, queue) ->
      return done err if err?
      queue.data = JSON.parse queue.data

      setTimeout ->
        N.bus.emit queue.event, queue.data
        queue.Delete!
      , delay * 1000
      done null queue

    item.data = JSON.stringify(item.data)
    item.delay = new Date!getTime! + item.delay * 1000
    @Create item, newDone

  @Resurect = -> ...

Queue.Field \event \string
Queue.Field \data  \string
Queue.Field \delay \int
