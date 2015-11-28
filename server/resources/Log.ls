require! {
  nodulator: N
}

class LogRoute extends N.Route
  Config: ->
    @Get ~> @resource.List playerId: it.user?.id

class Log extends N \log LogRoute, schema: \strict

Log.Field \title \string
Log.Field \body  \string
