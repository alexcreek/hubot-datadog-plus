# Description:
#   Hubot script for interacting with Datadog
#
# Dependencies:
#   node-dogapi
#
# Configuration:
#   HUBOT_DATADOG_API_KEY - Datadog API Key
#   HUBOT_DATADOG_APP_KEY - Datadog Application Key
#
# Commands:
#   hubot datadog monitor me - returns a list of monitors not in an 'OK' state
#   hubot datadog monitor [me] <id> - returns a list of hosts triggering monitor <id> along with their state
#   hubot datadog monitor mute <id> - mutes a monitor with <id>
#   hubot datadog monitor unmute <id> - unmutes a monitor with <id>
#   hubot datadog monitor mute all - mute all monitors
#   hubot datadog monitor unmute all - unmute all monitors
#   hubot datadog host [me] <pattern> - returns all hosts that match <pattern> 
#   hubot datadog host mute <name> - mute a host
#   hubot datadog host unmute <name> - unmute a host
#   hubot datadog graph <1h|4h|12h|1d|1w> <memory|cpu|load|iowait|disk|disk-util> <host=foo|tag=foo:bar> - generates graph of metrics for a host or a tag
#
# Notes:
#   HUBOT_DATADOG_API_KEY and HUBOT_DATADOG_APP_KEY can be managed at 
#   https://app.datadoghq.com/account/settings#api
#
#   <name> for 'datadog host mute/unmute' must match the full hostname in Datadog
#
# Author:
#   alexcreek
#

dogapi = require 'dogapi'

module.exports = (robot) ->
  api_key = process.env.HUBOT_DATADOG_APIKEY
  app_key = process.env.HUBOT_DATADOG_APPKEY

  unless api_key?
    robot.logger.error "HUBOT_DATADOG_APIKEY not set"
    process.exit(1)

  unless app_key?
    robot.logger.error "HUBOT_DATADOG_APPKEY not set"
    process.exit(1)

  options =
    api_key: api_key
    app_key: app_key

  dogapi.initialize(options)

  robot.respond /datadog monitor me$/i, (res) ->
    output = ''
    dogapi.monitor.getAll (err, response) ->
      i = 0
      while i < response.length
        if response[i].overall_state != 'OK'
          if Object.keys(response[i].options['silenced']).length >= 1
            status = '**MUTED**'
          output += response[i].id + ' : ' + response[i].name + ' - ' + response[i].overall_state + " #{status}\n"
        i++
        status = ''
      res.send "#{output}"

  robot.respond /datadog monitor (?:me )?([0-9]+)/i, (res) ->
    output = ''
    state = ['alert', 'warn', 'no data']
    dogapi.monitor.get res.match[1], state, (err, response) ->
      if err
        res.send "An error occured. Failed to enumerate hosts for monitor #{res.match[1]}"
        return
      hosts = response.state.groups
      if Object.keys(hosts).length == 0
        res.send 'No hosts found triggering this monitor'
      else
        for k in Object.keys(hosts)
          output += hosts[k].name.replace(/host:/,'') + ' - ' + hosts[k].status + '\n'
        res.send "Hosts triggering [#{response.name}]:\n#{output}"

  robot.respond /datadog monitor mute ([0-9]+)/i, (res) ->
    monitor_id = res.match[1]
    scope = scope: "*"
    dogapi.monitor.mute monitor_id, scope, (err, response) ->
      if response == null
        # make another request to get monitor status
        dogapi.monitor.get monitor_id, (err, response) ->
          if Object.keys(response.options['silenced']).length == 0
            res.send "An error occured. Failed to mute monitor #{monitor_id}"
          else if Object.keys(response.options['silenced']).length >= 1
            res.send "Monitor #{monitor_id} is already muted"
      else if Object.keys(response.options['silenced']).length >= 1
        res.send "Muted monitor #{monitor_id}"

  robot.respond /datadog monitor unmute ([0-9]+)/i, (res) ->
    monitor_id = res.match[1]
    scope = "*"
    dogapi.monitor.unmute monitor_id, scope, (err, response) ->
      if response == null
        # make another request to get monitor status
        dogapi.monitor.get monitor_id, (err, response) ->
          if Object.keys(response.options['silenced']).length >= 1
            res.send "An error occured. Failed to unmute monitor #{monitor_id}"
          else if Object.keys(response.options['silenced']).length == 0
            res.send "Monitor #{monitor_id} is already unmuted"
      if Object.keys(response.options['silenced']).length == 0
        res.send "Unmuted monitor #{monitor_id}"

  robot.respond /datadog monitor mute all/i, (res) ->
    dogapi.monitor.muteAll (err, response) ->
      if err
        res.send "An error occured.  Failed to mute all monitors"
      else
        if Object.keys(response['scope']).length >= 1
          res.send "Muted all monitors"

  robot.respond /datadog monitor unmute all/i, (res) ->
    dogapi.monitor.unmuteAll (err, response) ->
      if err
        res.send "An error occured.  Failed to unmute all monitors"
      else
        # DD api returns nothing for this so we can't validate unmuted monitors
        res.send "Unmuted all monitors"

  robot.respond /datadog host mute ([a-z0-9-_\.]+)/i, (res) ->
    hostname = res.match[1]
    dogapi.host.mute hostname, (err, response) ->
      if err
        # fragile but the builtin error message sucks
        if err[0].search("already") == -1
          res.send "An error occured. Failed to mute host #{hostname}"
        else
          res.send "Host #{hostname} is already muted"
      else if Object.keys(response['action']).length >= 1
        res.send "Muted host #{hostname}"

  robot.respond /datadog host unmute ([a-z0-9-_\.]+)/i, (res) ->
    hostname = res.match[1]
    dogapi.host.unmute hostname, (err, response) ->
      if err
        # more fragility
        if err[0].search("is not muted") == -1
          res.send "An error occured. Failed to unmute host #{hostname}"
        else
          res.send "host #{hostname} is already unmuted"
        return
      else if Object.keys(response['action']).length >= 1
        res.send "Unmuted host #{hostname}"

  robot.respond /datadog host (?:me )?([a-z0-9-_\.]+)/i, (res) ->
    pattern = 'hosts:' + res.match[1]
    dogapi.search.query pattern, (err, response) ->
      if err
        res.send "An error occured. Search for #{pattern} failed"
        return
      else if Object.keys(response.results.hosts).length < 1
        res.send "No results found for #{res.match[1]}"
      else
        output = ''
        i = 0
        while i < response.results.hosts.length
          output += response.results.hosts[i] + '\n'
          i++
        res.send "#{output}"

  robot.respond /datadog graph (1h|4h|12h|1d|1w) (memory|cpu|load|iowait|disk|disk-util) (host=.*|tag=.*)/i, (res) ->
    # set time vars
    end =  dogapi.now()
    switch res.match[1]
      when "1h" then duration = 3600
      when "4h" then duration = 14400
      when "12h" then duration = 43200
      when "1d" then duration = 86400
      when "1w" then duration = 604800
      else duration = 86400
    beginning = end - duration

    # set target vars
    if res.match[3].search('host=') != -1
      target = 'host:' + res.match[3].replace('host=', '')
    else if res.match[3].search('tag=') != -1
      target = res.match[3].replace('tag=', '')

    # set query vars
    switch res.match[2]
      when 'memory' then query = "avg:system.mem.total{#{target}} - ( avg:system.mem.total{#{target}} - avg:system.mem.free{#{target}} - avg:system.mem.cached{#{target}} )"
      when 'cpu' then query = "avg:system.cpu.user{#{target}} + avg:system.cpu.system{#{target}}"
      when 'load' then query = "avg:system.load.1{#{target}}"
      when 'iowait' then query = "avg:system.cpu.iowait{#{target}}"
      when 'disk' then query = "max:system.disk.in_use{#{target}}"
      when 'disk-util' then query = "max:system.io.util{#{target}}"

    dogapi.graph.snapshot query, beginning, end, (err, response) ->
      ## shamlessly lifted from the hubot-datadog module ##
      # graphs are generated on the fly
      # without a pause, hubot returns the links before the graphs are ready :[
      setTimeout ->
        res.send response.snapshot_url
      , 4000
