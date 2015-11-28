require! {
  nodulator: N
  \prelude-ls
  \./Queue
}

global import prelude-ls

class BuildingRoute extends N.Route
  Config: ->
    @All ~> it.SetInstance @resource.Fetch playerId: it.user?.id
    @Get (.instance)
    @Get \/levelup (.instance.LevelUp!)

class Building extends N \building BuildingRoute, abstract: true schema: \strict

  _LevelUpCost: -> ...

  LevelUp: @_WrapPromise @_WrapResolvePromise (done) ->
    @Player.Fetch!
      .Then !~> throw new Error 'Queue already on progress' if it.Queue?
      .Then ~> it.Buy @levelUpCost
      .Then ~> N.Queue.Timeout do
        playerId: @playerId
        event: \level_up_finish
        data: {id: @id, type: capitalize @_type}
        delay: @levelUpCost.delay
      .Then ~> @Fetch done
      .Catch done

Building.Field \level       \int    .Default 1
Building.Field \levelUpCost \object .Virtual -> @_LevelUpCost!
Building.Field \playerId    \int    .Internal!

N.bus.on \level_up_finish ->
  N[it.type].Fetch it.id .Set (.level++)
