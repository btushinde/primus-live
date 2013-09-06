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

collectNpmFrom = (dir) ->
  addDependenciesTo npmPackages, path.join dir, 'package.json'

collectBowerFrom = (dir) ->
  addDependenciesTo bowerPackages, path.join dir, 'bower.json'

scanPackagesIn = (dir) ->
  for file in fs.readdirSync dir
    subdir = path.join dir, file
    collectNpmFrom subdir
    collectBowerFrom subdir

omitExistingInDir = (dir, packages) ->
  args = []
  for name, version of packages
    unless fs.existsSync path.join dir, name
      args.push name
  args.sort()

installNpmPackages = (packages, done) ->
  args = omitExistingInDir 'node_modules', packages
  if args.length
    console.log 'npm will install:', args.join ', '
    execFile 'npm', ['install', args...], {}, (err, stdout, stderr) ->
      throw err  if err
      console.log stderr
      done()
  else
    process.nextTick done

installBowerPackages = (packages, done) ->
  args = omitExistingInDir 'bower_components', packages
  if args.length
    console.log 'bower will install:', args.join ', '
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
  collectBowerFrom '.'
  scanPackagesIn 'app'

  # if bowerPackages.length
  #   npmPackages.bower ?= '*'

  console.log 'npm', Object.keys npmPackages
  console.log 'bower', Object.keys bowerPackages

  installNpmPackages npmPackages, ->
    installBowerPackages bowerPackages, done
