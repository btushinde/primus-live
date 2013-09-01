ng = angular.module 'view2', []

ng.config [
  '$stateProvider',
  ($stateProvider) ->
    $stateProvider
      .state 'view2',
        url: '/view2'
        templateUrl: 'view2/view.html'
        controller: 'MyCtrl2'
]

ng.controller 'MyCtrl2', [
  ->
]

ng.filter 'interpolate', [
  'version',
  (version) ->
    (text) ->
      String(text).replace '%VERSION%', version
]

ng.value 'version', '0.1'
