require! {
  nodulator: N
  \./Mine
}

class CrystalMine extends N.Mine.Extend \crystalmine N.Mine.Route

  _Production: -> 7 * @level * (1.1 ^ @level)

  _LevelUpCost: ->
    metal: Math.floor 48 * (1.6 ^ @level)
    crystal: Math.floor 36 * (1.6 ^ @level)
    delay: Math.floor 15 * (2.5 ^ @level)

CrystalMine.Init!
