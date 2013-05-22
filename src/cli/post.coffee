async = require 'async'
util = require 'util'
fs = require 'fs'
{logger, extend} = require '../common' # lib common
{getOptions, commonUsage, commonOptions} = require './common' # cli common

usage = """

  usage: wintersmith preview [options]

  options:

    -p, --port [port]             port to run server on (defaults to 8080)
    -d, --domain [domain]         host to run server on (defaults to localhost)
    #{ commonUsage }

    all options can also be set in the config file

  examples:

    preview using a config file (assuming config.json is found in working directory):
    $ wintersmith preview

"""

options =
  port:
    alias: 'p'
    default: 8080
  domain:
    alias: 'd'
    default: 'localhost'
    


extend options, commonOptions
preview = (argv) ->
  async.waterfall [async.apply(getOptions, argv), (options, callback) ->
    if typeof argv._[1] is "undefined"
      logger.error "Enter Name for the Post "
      return
    else
      callback null, options
  , (options, callback) ->
    index_header options.config, argv, (indexmd) ->
      callback null, options, indexmd

  , (options, indexmd, callback) ->
    post_dir = options.contents + "\\articles\\" + argv._[1]
    fs.mkdir post_dir, (e) ->
      if not e or (e and e.code isnt "EEXIST")
        fs.writeFile post_dir + "\\index.md", indexmd, (err) ->
          if err
            logger.error argv._[1] + " Post index.md already exists"
          else
            logger.info "Post has been created"

      else
        logger.error argv._[1] + " Post name already exists"

    callback null, ""
  ], (error) ->
    logger.error error.message, error  if error

index_header = (config, argv, callback) ->
  indexmd = undefined
  unless typeof argv._[2] is "undefined"
    indexmd = "--- \ntitle: " + argv._[2] + " \n"
  else
    indexmd = "--- \ntitle: Title \n"
  co = _ref.readJSON(config, (e, o) ->
    unless e is "null"
      indexmd += "author: " + o.locals.owner + " \n"
    else
      indexmd += "author: author name \n"
    now = new Date()
    now = now.getFullYear() + "-" + now.getMonth() + "-" + now.getDate() + " " + now.getHours() + ":" + now.getMinutes()
    indexmd += "date : " + now + " \n"
    indexmd += "template : article.jade \n ---"
    callback indexmd
  )

module.exports = preview
module.exports.usage = usage
module.exports.options = options