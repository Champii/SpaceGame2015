require! {
  nodulator: N
  \prelude-ls
  \./Queue
  \./Player
  \./Log
}

global import prelude-ls

class AttackRoute extends N.Route
  Config: ->
    @Post \/:id ~> @resource.Attack N.Player.Fetch(it.user?.id), N.Player.Fetch(+it.params.id), +it.body.troops

class Attack extends N.Queue.Extend \attack AttackRoute, schema: \strict maxDepth: 3

  @Attack = @_WrapPromise @_WrapResolveArgPromise (attacker, defender, troops, done) ->
    return done new Error 'Not enought troops' if troops > attacker.Factory.troops
    distance = N.Player.GetDistance attacker, defender
    @Timeout do
      attackerId: attacker.id
      defenderId: defender.id
      event: \battle
      data: attackerId: attacker.id, defenderId: defender.id, troops: troops
      delay: Math.floor distance * 10 * (attacker.Factory.level * 0.9)
      (err, attack) ->
        return done err if err?

        attacker.Factory.Set (.troops -= troops)
          .Then -> attacker.Fetch done
          .Catch done

  Battle: @_WrapPromise (done) ->
    startTroops = JSON.parse @data .troops
    specs =
      attacker:
        power: @Attacking.Factory.level * startTroops * 0.8
        health: @Attacking.Factory.level * startTroops
      defender:
        power: @Attacking.Factory.level * @Defending.Factory.troops * 0.8
        health: @Defending.Factory.level * @Defending.Factory.troops

    afterBattle =
      attacker: specs.attacker.health - specs.defender.power
      defender: specs.defender.health - specs.attacker.power

    troops =
      attacker: Math.ceil(startTroops * (afterBattle.attacker / specs.attacker.health)) >? 0
      defender: Math.ceil(@Defending.Factory.troops * (afterBattle.defender / specs.defender.health)) >? 0

    loot = null
    if afterBattle.attacker <= afterBattle.defender
      N.Log.Create do
        playerId: @Attacking.id
        title: "[Attack]You loose against #{@Defending.username}"
        body: "Opponent troops: At start: #{@Defending.Factory.troops} At end: #{troops.defender} with level #{@Defending.Factory.level}. Troops left: #{troops.attacker}"
      N.Log.Create do
        playerId: @Defending.id
        title: "[Defend]You won against #{@Attacking.username}"
        body: "Opponent troops: At start: #{startTroops} At end: #{troops.attacker} with level #{@Attacking.Factory.level}. Troops left: #{troops.defender}"
      loot =
        metal: 0
        crystal: 0
    else
      loot =
        metal: @Defending.resources.metal <? Math.floor troops.attacker / 2 * 10 * (1.1 ^ @Attacking.Factory.level)
        crystal: @Defending.resources.crystal <? Math.floor troops.attacker / 2.5 * 10 * (1.1 ^ @Attacking.Factory.level)
      N.Log.Create do
        playerId: @Attacking.id
        title: "[Attack]You won against #{@Defending.username}"
        body: "Opponent troops: At start: #{@Defending.Factory.troops} At end: #{troops.defender} with level #{@Defending.Factory.level}. Troops left: #{troops.attacker}. Loot: metal: #{loot.metal} crystal: #{loot.crystal}"
      N.Log.Create do
        playerId: @Defending.id
        title: "[Defend]You loose against #{@Attacking.username}"
        body: "Opponent troops: At start: #{startTroops} At end: #{troops.attacker} with level #{@Attacking.Factory.level}. Troops left: #{troops.defender}. You lost: metal: #{loot.metal} crystal: #{loot.crystal}"

      @Defending.Metalmine.Set (.amount -= loot.metal)
      @Defending.Crystalmine.Set (.amount -= loot.crystal)

    @Defending.Factory.Set troops: troops.defender
    if troops.attacker > 0
      distance = N.Player.GetDistance @Attacking, @Defending
      Attack.Timeout do
        attackerId: @Attacking.id
        event: \troops_back
        data: attackerId: @Attacking.id, troops: troops.attacker, loot: loot
        delay: Math.floor distance * 10 * (@Attacking.Factory.level * 0.9)
        done
    else
      done null @Attacking

N.Player.MayHasMany Attack, \Attacking \attackerId
N.Player.MayHasMany Attack, \Defending \defenderId

N.bus.on \battle ->
  Attack.List attackerId: it.attackerId, defenderId: it.defenderId
    .Then ->
      minimum-by (.id), it .Battle!
    .Catch console.error

N.bus.on \troops_back ->
  res = it
  N.Player.Fetch it.attackerId
    .Then !-> it.Factory.Set (.troops += res.troops)
    .Then !-> it.Metalmine.Set (.amount += res.loot.metal)
    .Then -> it.Crystalmine.Set (.amount += res.loot.crystal)
    .Catch console.error
