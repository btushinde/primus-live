##npm##

primus-live makes use of 'npm' as one of its installation processes. When run from the command line, npm uses both the command environment and command line arguments to customise its behaviour. To achieve a similar end within primus-live, you can create the a variable within the primus-live package.json file that follows the following syntax:
npm_install_flags_{PLATFORM} where {PLATFORM} is equivalent to the node 'process.platform' output.
e.g. 
npm_install_flags_darwin:--someflag  
or
npm_install_flags_win32: --msvs_version=2013

This parameter will be supplied to any npm installations carried out by primus-live.
