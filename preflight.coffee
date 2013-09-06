# This logic installs npm and bower packages mentioned in subdirs of './app'.
# As a result, everything needed is there when the app starts, nicely collected
# in the top-level 'node_modules' and 'bower_components' directories.

fs = require 'fs'
path = require 'path'
{execFile} = require 'child_process'

addDependenciesTo = (results, filename) ->
  if fs.existsSync filename
    json = JSON.parse fs.readFileSync filename
    for name, version of json.dependencies or {}
      results[name] = version

collectNpmPackages = (dir) ->
  addDependenciesTo npmPackages, path.join dir, 'package.json'

collectBowerPackages = (dir) ->
  addDependenciesTo bowerPackages, path.join dir, 'bower.json'

lookForPackageFiles = (dir) ->
  for file in fs.readdirSync dir
    subdir = path.join dir, file
    collectNpmPackages subdir
    collectBowerPackages subdir

installNpmPackages = (packages, done) ->
  args = []
  for name, version of packages
    unless fs.existsSync path.join 'node_modules', name
      args.push name
  if args.length
    console.log 'npm', args
    execFile 'npm', ['install', args...], {}, (err, stdout, stderr) ->
      throw err  if err
      console.log stderr
      done()
  else
    process.nextTick done

installBowerPackages = (packages, done) ->
  args = []
  for name, version of packages
    unless fs.existsSync path.join 'bower_components', name
      args.push name
  if args.length
    console.log 'bower', args
    bower = require 'bower'
    # unless fs.existsSync 'bower.json'
    #   fs.writeFileSync 'bower.json', "#{JSON.stringify name: 'main'}\n"
    bower.commands.install(args)
      .on 'log', (info) ->
        if info.level is 'info'
          console.log '   ', info.message
      .on 'end', ->
        done()
  else
    process.nextTick done

npmPackages = {}
bowerPackages = []

module.exports = (done) ->
  collectBowerPackages '.'
  lookForPackageFiles 'app'

  # if bowerPackages.length
  #   npmPackages.bower ?= '*'

  console.log 'npm', Object.keys npmPackages
  console.log 'bower', bowerPackages

  installNpmPackages npmPackages, ->
    installBowerPackages bowerPackages, done
