angular.module("Learn",["ngMaterial","ui.router"])
.config(function($mdThemingProvider,$stateProvider) {
  $mdThemingProvider.theme('default')
    .primaryPalette('teal')
    .accentPalette('orange');

    $stateProvider
    .state('classifieds',{
        url:'/classifieds',
        templateUrl:'components/classifieds/classifiedstpl.html',
        controller:"classifiedCtrl",
        controllerAs:"vm"
    })
    .state('classifieds.new',{
        url:'/new',
        templateUrl:'components/classifieds/new/newClassifiedstpl.html',
        controller:"newClassifiedCtrl",
        controllerAs:"vm"
    })
});

