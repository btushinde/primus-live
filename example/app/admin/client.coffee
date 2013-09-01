# Admin module for Angular, i.e. on the client side

ng = angular.module 'admin', []

ng.config [
  '$stateProvider',
  ($stateProvider) ->
    $stateProvider
      .state 'admin',
        url: '/admin'
        templateUrl: 'admin/view.html'
        controller: 'AdminCtrl'
]

ng.controller 'AdminCtrl', [
  '$scope',
  ($scope) ->
    $scope.hello = 'bonjour'
]
