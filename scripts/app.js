angular.module("Learn", ["ngMaterial", "ui.router"])
    .config(function ($mdThemingProvider, $stateProvider, $urlRouterProvider) {
        $mdThemingProvider.theme('default')
            .primaryPalette('teal')
            .accentPalette('orange');

        $urlRouterProvider.otherwise('/classifieds');

        $stateProvider
            .state('classifieds', {
                url: '/classifieds',
                templateUrl: 'components/classifieds/classifiedstpl.html',
                controller: "classifiedCtrl",
                controllerAs: "vm"
            })
            .state('classifieds.new', {
                url: '/new',
                templateUrl: 'components/classifieds/new/newClassifiedstpl.html',
                controller: "newClassifiedCtrl",
                controllerAs: "vm"
            })
            .state('classifieds.edit', {
                url: '/edit/:id',
                templateUrl: 'components/classifieds/edit/editClassifiedstpl.html',
                controller: "editClassifiedCtrl",
                controllerAs: "vm",
                params: {
                    classified: null
                }
            });
    });

