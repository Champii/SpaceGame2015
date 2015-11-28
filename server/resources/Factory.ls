require! {
  nodulator: N
  async
  \prelude-ls
  \./Building
  \./Queue
}
global import prelude-ls

class FactoryRoute extends N.Building.Route
  Config: ->
    super!
    @Get ~> it.instance
    @Get \/buydroid/:amount ~> it.instance.BuyDroids +it.params.amount

class Factory extends N.Building.Extend \factory FactoryRoute, schema: \strict

  _DroidCost: ->
    metal: Math.floor 2 * (1.5 ^ @level)
    crystal: Math.floor 3 * (1.5 ^ @level)
    delay: Math.floor 5 * (2 ^ @level)

  _LevelUpCost: ->
    metal: Math.floor 400 * (1.9 ^ @level)
    crystal: Math.floor 350 * (1.9 ^ @level)
    delay: Math.floor 60 * (1.6 ^ @level)

  BuyDroids: @_WrapPromise @_WrapResolvePromise (amount = 1, done) ->
    cost = Obj.map (* amount), @droidCost
    @Player.Fetch!Buy cost
      .Then ~>
        async.map [1 to amount], (i, done) ~>
          N.Queue.Timeout do
            factoryId: @id
            event: \droid_finish
            data: {id: @id, type: capitalize @_type}
            delay: @droidCost.delay * i
            done
        , (err, results) ~>
          return done err if err?

          @Fetch done
      .Catch done

Factory.Field \troops    \int    .Default 0
Factory.Field \droidCost \object .Virtual -> @_DroidCost!

Factory.MayHasMany N.Queue

N.bus.on \droid_finish ->
  N[it.type].Fetch it.id .Set (.troops++)
