ng = angular.module 'myApp', [
  'ui.state'
  'ng-primus'
  'admin'
  'view1'
  'view2'
]
  
ng.config [
  '$stateProvider', '$urlRouterProvider',
  ($stateProvider, $urlRouterProvider) ->
    $urlRouterProvider.otherwise '/'
]

ng.directive 'appVersion', [
  'version',
  (version) ->
    (scope, elm, attrs) ->
      elm.text version
]
