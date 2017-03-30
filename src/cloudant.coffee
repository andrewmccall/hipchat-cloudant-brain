#
# Cloudant brain for Hubot.
#
# Use VCAP_SERVICES:
#   Set the environment variable HUBOT_CLOUDANT_VCAP_INSTANCE_NAME to the instance name.
# Set a url
#   Set the environment variable HUBOT_CLOUDANT_URL to a cloudant URL.
#
Cloudant = require('cloudant');

module.exports = (robot) ->
  cloudant = null;
  if (process.env.HUBOT_CLOUDANT_VCAP_INSTANCE_NAME
    cloudant = Cloudant({instanceName: process.env.HUBOT_CLOUDANT_VCAP_INSTANCE_NAME, vcapServices: JSON.parse(process.env.VCAP_SERVICES)}, (er, cloudant, reply) {
      if (er)
        throw er;
      console.log('Connected with vcapServices: %s', reply.userCtx.name);
      getData();
    })
  else if (process.env.HUBOT_CLOUDANT_URL)
    cloudant = Cloudant({url: process.env.HUBOT_CLOUDANT_URL}, (er, cloudant, reply) {
      if (er)
        throw er;
      console.log('Connected with username: %s', reply.userCtx.name);
      getData()
    });
  else
    console.log('No cloudant parameters configured...')

  robot.brain.setAutoSave false

  getData = ->
    cloudant.get "hubot", (err, reply) ->
      if err
        throw err
      else if reply
        robot.logger.info "hubot-cloudant-brain: Data for #{prefix} brain retrieved from Cloudant"
        robot.brain.mergeData reply
      else
        robot.logger.info "hubot-cloudant-brain: Initializing new data for #{prefix} brain"
        robot.brain.mergeData {}

      robot.brain.setAutoSave true

  robot.brain.on 'save', (data = {}) ->
    data._id = "hubot"
    cloudant.insert data
