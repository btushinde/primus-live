ng = angular.module "myApp", []
  
ng.config [
  "$routeProvider",
  ($routeProvider) ->
    $routeProvider.when "/view1",
      templateUrl: "partial1.html"
      controller: "MyCtrl1"

    $routeProvider.when "/view2",
      templateUrl: "partial2.html"
      controller: "MyCtrl2"

    $routeProvider.otherwise redirectTo: "/view1"
]

ng.controller "MyCtrl1", [
  ->
]

ng.controller "MyCtrl2", [
  ->
]

ng.directive "appVersion", [
  "version",
  (version) ->
    (scope, elm, attrs) ->
      elm.text version
]

ng.filter "interpolate", [
  "version",
  (version) ->
    (text) ->
      String(text).replace /\%VERSION\%/g, version
]

ng.value "version", "0.1"
