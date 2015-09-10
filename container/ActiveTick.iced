{NodeActivetick} = require './node-activetick-addon/build/Release/NodeActivetickAddon'
config = require './config'

class ActiveTick
  constructor: () ->
    @api = new NodeActivetick()
    
  connect: () ->
    result = @api.sessionInit config.api_key, config.ip, config.port, config.username, config.password
    console.log result

main = () ->
  a = new ActiveTick()
  a.connect()

main() if not module.parent
