require! {
  nodulator: N
  \prelude-ls
  \./Queue
  \./MetalMine
  \./CrystalMine
  \./Factory
  \./Log
}

global import prelude-ls

galaxies = 1
solarsystems = 1
planets = 10

galaxiesDistance = 50
solarsystemsDistance = 20
planetsDistance = 5

class PlayerRoute extends N.Route
  Config: ->
    @Get ~> @resource.Fetch it.user?.id
    @Post ~> @resource.Create it.body

class Player extends N.AccountResource \player PlayerRoute, schema: \strict maxDepth: 2

  @_GetNextPlanet = @_WrapPromise (done) ->
    @List!
      .Then -> maximum-by (.id), it
      .Then ->
        return done null {galaxy: 1, solarsystem: 1, planet: 1} if not it._table?

        planet = it.planet + 1
        solarsystem = it.solarsystem
        galaxy = it.galaxy

        if planet > planets
          planet = 1
          solarsystem = it.solarsystem + 1

          if solarsystem > solarsystems
            solarsystem = 1
            galaxy = it.galaxy + 1

            if galaxy > galaxies
              return done new Error 'Server Full'

        done null {galaxy, solarsystem, planet}

      .Catch ->

  @GetDistance = ({galaxy: galaxy1, solarsystem: solarsystem1, planet: planet1}, {galaxy: galaxy2, solarsystem: solarsystem2, planet: planet2}) ->
    ((abs galaxy2 - galaxy1) * galaxiesDistance) +
      ((abs solarsystem2 - solarsystem1) * solarsystemsDistance) +
      ((abs planet2 - planet1) * planetsDistance)

  @Create = @_WrapPromise (item, done) ->
    @_GetNextPlanet!
      .Then ~>
        item <<< it
        @_CreateUnwrapped item, done
      .Catch done

  Buy: @_WrapPromise @_WrapResolvePromise (price, done) ->
    if N.Mine.HasEnought @resources, price
      @Metalmine.Set amount: @Metalmine.amount - price.metal
        .Then ~> @Crystalmine.Set (-> @amount = @amount - price.crystal)
        .Then ~> @Fetch done
        .Catch done
    else
      done new Error 'Not enought'

Player.Field \username    \string
Player.Field \password    \string
Player.Field \galaxy      \int
Player.Field \solarsystem \int
Player.Field \planet      \int
Player.Field \resources   \object .Virtual -> {metal: @Metalmine?.ToJSON!amount, crystal: @Crystalmine?.ToJSON!amount}

Player.HasOne N.Metalmine
Player.HasOne N.Crystalmine
Player.HasOne N.Factory
Player.MayHasOne N.Queue
Player.HasMany N.Log

Player.Watch \new ->
  N.Metalmine.Create playerId: it.id, level: 10
    .Then !-> N.Crystalmine.Create playerId: it.id, level: 10
    .Then -> N.Factory.Create playerId: it.id, troops: 10000 level: 1
    .Catch console.error

Player.Create username: 't' password: 'l'
  .Then ->
    Player.Create username: 't2' password: 'l'
