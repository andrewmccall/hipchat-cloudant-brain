# hubot-cloudant-brain

A hubot script to persist hubot's brain using cloudant. Based on the
hubot-redis-brain script.

See [`src/cloudat.coffee`](src/cloudant.coffee) for full documentation.

## Installation

In hubot project repo, run:

`npm install hubot-cloudant-brain --save`

Then add **hubot-cloudant-brain** to your `external-scripts.json`:

```json
[
  "hubot-cloudant-brain"
]
```

## Configuration

hubot-cloudant-brain requires a cloudant server to work. It uses the `HUBOT_CLOUDANT_URL` environment variable for determining
where to connect.

### Cloudfoundry VCAP SERVICES

Set the environment variable `HUBOT_CLOUDANT_VCAP_INSTANCE_NAME` to the instance name.
