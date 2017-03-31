#
# Cloudant brain for Hubot.
#
# (optional) HUBOT_CLOUDANT_PREFIX set this to change document ID to use, default is the botname.
# (optional) HUBOT_CLOUDANT_DATABASE set this to change the dabase name, defailt is hubot
#
# Use VCAP_SERVICES:
#   Set the environment variable HUBOT_CLOUDANT_VCAP_INSTANCE_NAME to the instance name.
# Set a url
#   Set the environment variable HUBOT_CLOUDANT_URL to a cloudant URL.
#
Cloudant = require('cloudant');
hash = require('object-hash');

module.exports = (robot) ->
  cloudant = null
  db = null
  currentHash = null

  prefix = process.env.HUBOT_CLOUDANT_PREFIX ? robot.name
  dbName = process.env.HUBOT_CLOUDANT_DATABASE ? "hubot"
  if (process.env.VCAP_SERVICES)

    vcap = JSON.parse(process.env.VCAP_SERVICES)
    robot.logger.debug 'VCAP: %s', JSON.stringify(process.env.VCAP_SERVICES)
    if not vcap.cloudantNoSQLDB
      if vcap["cloudantNoSQLDB Dedicated"]
        vcap.cloudantNoSQLDB = vcap["cloudantNoSQLDB Dedicated"]

    robot.logger.debug 'VCAP: %s', JSON.stringify(process.env.VCAP_SERVICES)

    instanceName = null
    if process.env.HUBOT_CLOUDANT_VCAP_INSTANCE_NAME
      instanceName = process.env.HUBOT_CLOUDANT_VCAP_INSTANCE_NAME
      robot.logger.info "Instance found %s", instanceName

    cloudant = Cloudant {instanceName: instanceName, vcapServices: vcap}, (er, cloudant, reply) ->
      if (er)
        robot.logger.error 'Connection to cloudant via VCAP failed.'
        throw er
      robot.logger.info 'Connected with vcapServices: %s', reply.userCtx.name
      initDb()

  else if (process.env.HUBOT_CLOUDANT_URL)
    cloudant = Cloudant {url: process.env.HUBOT_CLOUDANT_URL}, (er, cloudant, reply) ->
      if (er)
        robot.logger.error 'Connection to cloudant URL failed.'
        throw er
      robot.logger.info 'Connected with username: %s', reply.userCtx.name
      initDb()
  else
    robot.logger.warning 'No cloudant parameters configured...'

  robot.brain.setAutoSave false

  initDb = ->
    cloudant.db.list (err, body) ->
      if err
        throw err
      console.log(body + dbName in body)
      if not (dbName in body)
        robot.logger.info "Creating new db: #{dbName}"
        cloudant.db.create dbName, () ->
          initDb()
      else
        db = cloudant.db.use dbName
        robot.logger.info "Using db #{dbName}"
        getData()

  getData = ->
      db.get "#{prefix}:hubot", (err, reply) ->
        if err
          if err.statusCode == 404
            robot.logger.info "hubot-cloudant-brain: Initializing new data for #{prefix} brain"
            robot.brain.mergeData {}
          else
            robot.logger.error "Error getting data: %s", JSON.stringify err
            throw err
        else if reply
          robot.logger.info "hubot-cloudant-brain: Data for #{prefix} brain retrieved from Cloudant"
          robot.brain.mergeData reply.brain ? {}
          currentHash = reply.hash
        robot.brain.setAutoSave true

  robot.brain.on 'save', (data = {}) ->
    dataHash = hash(data);
    if not (dataHash is currentHash)
      currentHash = dataHash
      db.get "#{prefix}:hubot", (err, reply) ->
        if err and (err.statusCode != 404)
            robot.logger.error "Error getting data: %s", JSON.stringify err
            throw err
        db.insert {_rev: reply.rev, brain: data, hash: hash}, "#{prefix}:hubot", (er, body, header) ->
            if er
              robot.logger.info 'Brain save failed.', err.message
            else
              robot.logger.debug 'Brain saved. %s', JSON.stringify body
    else
      logger.debug "No change to data, ignored save."
