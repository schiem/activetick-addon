# Copyright 2015-present Sheldon Thomas
fs = require 'fs'
release_path = __dirname + '/../build/Release/NodeActiveTickAddon.node'
debug_path = __dirname + '/../build/Debug/NodeActiveTickAddon.node'
debug_exists = fs.existsSync debug_path
if debug_exists # prefer debug
  {NodeActiveTick} = require(debug_path)
else
  {NodeActiveTick} = require(release_path)

async = require 'async'
_ = require 'underscore'
ProtoBuf = require 'protobufjs'
path = require 'path'
EventEmitter = require 'events'

{ATConstituentRequestTypes,
ATStreamRequestTypes,
ATBarHistoryType} = require './ActiveTickDefines'

noisy = yes

standard_timeout = 3000

class ActiveTick extends EventEmitter
  constructor: (readyCb) ->
    ProtoBuf.loadProtoFile path.join(__dirname, "../protobuf", "messages.proto"), (err, builder) =>
      return console.error err if err
      @api = new NodeActiveTick(@handleProtoMsg)
      @callbacks = {}
      @stream_callbacks = {}
      @messages_builder = builder
      @ATLoginResponse = @messages_builder.build "NodeActiveTickProto.ATLoginResponse"
      @ATConstituentResponse = @messages_builder.build "NodeActiveTickProto.ATConstituentResponse"
      @ATQuote = @messages_builder.build "NodeActiveTickProto.ATQuote"
      @ATQuoteStreamResponse = @messages_builder.build "NodeActiveTickProto.ATQuoteStreamResponse"
      @ATQuoteStreamTradeUpdate = @messages_builder.build "NodeActiveTickProto.ATQuoteStreamTradeUpdate"
      @ATQuoteStreamQuoteUpdate = @messages_builder.build "NodeActiveTickProto.ATQuoteStreamQuoteUpdate"
      @ATBarHistoryDbResponse = @messages_builder.build "NodeActiveTickProto.ATBarHistoryDbResponse"
      @ATQuoteDbResponse = @messages_builder.build "NodeActiveTickProto.ATQuoteDbResponse"
      
      # enums
      @ATQuoteFieldTypes = @messages_builder.build 'NodeActiveTickProto.ATQuoteFieldType'
      @ATFieldStatus = @messages_builder.build 'NodeActiveTickProto.ATQuoteDbResponseSymbolFieldData.ATFieldStatus'
      @ATDataType = @messages_builder.build 'NodeActiveTickProto.ATQuoteDbResponseSymbolFieldData.ATDataType'
      @ATQuoteDbResponseType = _.invert @messages_builder.build 'NodeActiveTickProto.ATQuoteDbResponse.ATQuoteDbResponseType'
      @ATSymbolStatus = @messages_builder.build 'NodeActiveTickProto.ATSymbolStatus'
      @ATQuoteFieldType = @messages_builder.build 'NodeActiveTickProto.ATQuoteFieldType'
      readyCb()

  barHistoryDBRequest: (symbol, barhistorytype, intradayminutecompression, startime, endtime, requestCb) =>
    request_id = @api.barHistoryDbRequest symbol, barhistorytype, intradayminutecompression, startime, endtime
    @callbacks[request_id] = requestCb if requestCb?

  quoteDBRequest: (symbol, fields, requestCb) =>
    request_id = @api.quoteDbRequest symbol, fields
    @callbacks[request_id] = requestCb if requestCb?

  beginQuoteStream: (symbols, ATStreamRequestTypeIndex, requestCb) =>
    if typeof symbols is 'object'
      if symbols.length is 1
        symbolParam = symbols[0]
        symbolCount = 1
      else
        symbolParam = symbols.join ','
        symbolCount = symbols.length
    else if typeof symbols is 'string'
      symbolParam = symbols
      symbolCount = 1
    request_id = @api.beginQuoteStream symbolParam, symbolCount, ATStreamRequestTypeIndex
    @callbacks[request_id] = requestCb if requestCb?
    
  listRequest: (listType, key, cb) ->
    request_id = @api.listRequest listType, key
    @callbacks[request_id] = cb
  
  connect: (apiKey, username, password, cb) =>
    request_id = @api.connect apiKey, username, password
    @callbacks[request_id] = cb
    
  handleProtoMsg: (msgType, msgID, msgData) =>
    if msgType is 'ATLoginResponse'
      msg = @ATLoginResponse.decode msgData
      return console.error msg if msg.loginResponseString isnt 'Success'
    else if msgType is 'ATConstituentResponse'
      msg = @ATConstituentResponse.decode msgData
    else if msgType is 'ATQuoteStreamResponse'
      msg = @ATQuoteStreamResponse.decode msgData
    else if msgType is 'ATBarHistoryDbResponse'
      msg = @ATBarHistoryDbResponse.decode msgData
    else if msgType is 'ATQuoteStreamTradeUpdate'
      msg = @ATQuoteStreamTradeUpdate.decode msgData
      @emit 'trade', msg
    else if msgType is 'ATQuoteStreamQuoteUpdate'
      msg = @ATQuoteStreamQuoteUpdate.decode msgData
      @emit 'quote', msg
    else if msgType is 'ATQuoteDbResponse'
      msg = @ATQuoteDbResponse.decode msgData      
    if (c = @callbacks[msgID])?
      c(msg)

module.exports = {ActiveTick}


