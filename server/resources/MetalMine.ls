require! {
  nodulator: N
  \./Mine
}

class MetalMine extends N.Mine.Extend \metalmine N.Mine.Route

  _Production: -> 10 * @level * (1.1 ^ @level)

  _LevelUpCost: ->
    metal: Math.floor 60 * (1.5 ^ @level)
    crystal: Math.floor 50 * (1.5 ^ @level)
    delay: Math.floor 10 * (2 ^ @level)

MetalMine.Init!
