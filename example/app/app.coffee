ng = angular.module 'myApp', ['ui.state', 'primus']
  
ng.config [
  '$stateProvider', '$urlRouterProvider',
  ($stateProvider, $urlRouterProvider) ->
    $urlRouterProvider.otherwise '/view1'

    $stateProvider.state 'view1',
      url: '/view1',
      templateUrl: 'partial1.html'
      controller: 'MyCtrl1'

    $stateProvider.state 'view2',
      url: '/view2',
      templateUrl: 'partial2.html'
      controller: 'MyCtrl2'
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
