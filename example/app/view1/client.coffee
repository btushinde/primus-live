ng = angular.module 'view1', []

ng.config [
  '$stateProvider',
  ($stateProvider) ->
    $stateProvider
      .state 'view1',
        url: '/'
        templateUrl: 'view1/view.html'
        controller: 'MyCtrl1'
]

ng.controller 'MyCtrl1', [
  ->
]
