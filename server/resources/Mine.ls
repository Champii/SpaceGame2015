require! {
  nodulator: N
  \./Building
}

class Mine extends N.Building.Extend \mine N.Building.Route, abstract: true schema: \strict

  @DEFAULT_DEPTH = 3

  @_FetchUnwrapped = (...args) ->
    doneIdx = @_FindDone args
    oldDone = args[doneIdx]
    args[doneIdx] = (err, data) ->
      return oldDone err if err?

      data.Update oldDone

    _super = super
    _super.apply @, args

  Update: @_WrapPromise @_WrapResolvePromise (done) ->
    now = (new Date) .getTime!
    diff = now - @lastUpdate

    toAdd = ((@production) * (diff / 1000)) / 60

    if not toAdd
      return done null @

    @Set do
      amount : @amount + toAdd
      lastUpdate: now
      done

  ToJSON: ->
    res = super!
    res.amount = Math.floor res.amount
    res.production = Math.floor res.production
    res

  @HasEnought = (resources, price) ->
    return false if not resources? or not price?

    for type, amount of resources when type isnt \delay
      if amount < price[type]
        return false
    true

  _Production: -> ...

Mine.Field \lastUpdate \int     .Internal!Default -> (new Date) .getTime!
Mine.Field \amount     \float   .Default 20000
Mine.Field \production \float   .Virtual -> @_Production!
