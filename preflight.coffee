# This logic installs npm + bower packages and runs make in subdirs of './app'.
# As a result, everything needed is there when the app starts, nicely collected
# in the top-level 'node_modules' and 'bower_components' directories.

fs = require 'fs'
path = require 'path'
{execFile} = require 'child_process'
package_json = {}
npmInstallOpts = ""

try
  package_json = require './package.json'
  if package_json["npm_install_flags_" + process.platform]  
    npmInstallOpts = package_json["npm_install_flags_" + process.platform]
catch err
  #ignore
  
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
    if fs.existsSync path.join subdir, 'Makefile'
      makeDirs.push file

errorHandler = (done) ->
  (err, stdout, stderr) ->
    if err
      console.info stdout.trimRight()  if stdout
      console.error stderr.trimRight()  if stderr
      process.exit 1
    done()

omitExistingInDir = (dir, packages) ->
  args = []
  for name, version of packages
    unless fs.existsSync path.join dir, name
      args.push name
  args.sort()

installNpmPackages = (packages, done) ->
  args = omitExistingInDir 'node_modules', packages
  if args.length
    console.info "npm will install:#{npmInstallOpts} " , args.join ', '
    npmstub = if process.platform == "win32" then "npm.cmd" else "npm"
    execFile npmstub, ['install', npmInstallOpts, args...], {env:process.env}, errorHandler done
  else
    process.nextTick done

installBowerPackages = (packages, done) ->
  args = omitExistingInDir 'bower_components', packages
  if args.length
    console.info 'bower will install:', args.join ', '
    bower = require 'bower'
    # unless fs.existsSync 'bower.json'
    #   fs.writeFileSync 'bower.json', "#{JSON.stringify name: 'main'}\n"
    bower.commands.install(args)
      .on 'log', (info) ->
        if info.level is 'info'
          console.info '   ', info.message
      .on 'error', (err) ->
        errorHandler(done) err, err.toString(), 'bower: *** Error 1'
      .on 'end', ->
        done()
  else
    process.nextTick done

runMakefiles = (done) ->
  if makeDirs.length
    lines = ("cd app/#{dir} && make" for dir in makeDirs)
    lines.unshift 'all:'
    child = execFile 'make', ['-f', '-'], {env:process.env}, errorHandler done
    child.stdin.write lines.join('\n\t')
    child.stdin.end()
  else
    process.nextTick done

npmPackages = {}
bowerPackages = []
makeDirs = []

module.exports = (done) ->
  collectBowerFrom '.'
  scanPackagesIn 'app'

  # if bowerPackages.length
  #   npmPackages.bower ?= '*'

  list = Object.keys npmPackages
  console.info "npm:\t#{list}"  if list.length
  list = Object.keys bowerPackages
  console.info "bower:\t#{list}"  if list.length
  console.info "make:\t#{makeDirs}"  if makeDirs.length

  installNpmPackages npmPackages, ->
    installBowerPackages bowerPackages, ->
      runMakefiles done
