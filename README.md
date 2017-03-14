# hubot-datadog-plus
Interact with Datadog monitors, hosts and graphs using Hubot

# Installation
    npm install hubot-datadog-plus --save

Enable the module by adding it to Hubot's external-scripts.json

    [ ...
    "hubot-datadog-plus",
    ... ]

# Configuring
Get your Datadog api and app tokens [Datadog Account Settings](https://app.datadoghq.com/account/settings#api)

Create corresponding environment variables in your Hubot's environment

    HUBOT_DATADOG_API_KEY=apikey
    HUBOT_DATADOG_APP_KEY=appkey

# Usage
### Get monitor info
     hubot datadog monitor me
     hubot datadog monitor [me] <id>

### Mute/Unmute monitors
     hubot datadog monitor mute <id>
     hubot datadog monitor mute all
     hubot datadog monitor unmute <id>
     hubot datadog monitor unmute all

### Search for hosts
     hubot datadog host [me] <pattern>

### Mute/Unmute hosts
     hubot datadog host mute <name>
     hubot datadog host unmute <name>

### Display graphs of hosts or tags
     hubot datadog graph <1h|4h|12h|1d|1w> <memory|cpu|load|iowait|disk|disk-util> <host=foo|tag=foo:bar>

# Credit
- Inspired by [hubot-datadog](https://www.npmjs.com/package/hubot-datadog)
- This module wouldn't be possible without [dogapi](https://www.npmjs.com/package/dogapi)
