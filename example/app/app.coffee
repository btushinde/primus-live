ng = angular.module 'myApp', ['ngRoute']
  
ng.config [
  '$routeProvider',
  ($routeProvider) ->
    $routeProvider.when '/view1',
      templateUrl: 'partial1.html'
      controller: 'MyCtrl1'

    $routeProvider.when '/view2',
      templateUrl: 'partial2.html'
      controller: 'MyCtrl2'

    $routeProvider.otherwise redirectTo: '/view1'
]

ng.run [
  '$rootScope',
  ($rootScope) ->

    # only report the first error, but do it very disruptively!
    primus.once 'error', alert

    # TODO the 'open' event fails regularly in 1.4.0, use private event for now
    primus.on 'incoming::open', (arg) ->
      $rootScope.$apply -> $rootScope.serverConnection = 'open'
    primus.on 'end', (arg) ->
      $rootScope.$apply -> $rootScope.serverConnection = 'closed'
    primus.on 'reconnect', (arg) ->
      $rootScope.$apply -> $rootScope.serverConnection = 'lost'

    primus.on 'data', (arg) ->
      $rootScope.$apply ->
        switch
          when arg.constructor is String
            $rootScope.serverMessage = arg
          when typeof arg is 'number'
            $rootScope.serverTick = arg
          when Array.isArray arg
            $rootScope.$broadcast arg...
          when arg instanceof Object
            $rootScope.$broadcast 'server', arg
]

ng.controller 'MyCtrl1', [
  ->
]

ng.controller 'MyCtrl2', [
  ->
]

ng.directive 'appVersion', [
  'version',
  (version) ->
    (scope, elm, attrs) ->
      elm.text version
]

ng.filter 'interpolate', [
  'version',
  (version) ->
    (text) ->
      String(text).replace '%VERSION%', version
]

ng.value 'version', '0.1'
