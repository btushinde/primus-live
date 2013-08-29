ng = angular.module 'myApp', ['ui.state', 'primus']
  
ng.config [
  '$stateProvider', '$urlRouterProvider', '$locationProvider',
  ($stateProvider, $urlRouterProvider, $locationProvider) ->
    $locationProvider.html5Mode true
    $urlRouterProvider.otherwise '/'

    $stateProvider
      .state 'view1',
        url: '/'
        templateUrl: 'partial1.html'
        controller: 'MyCtrl1'
      .state 'view2',
        url: '/view2'
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
