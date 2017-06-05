(function () {
    "use strict";

    angular
        .module('Learn')
        .controller('newClassifiedCtrl', function ($scope, $state, $timeout, $mdSidenav, $mdDialog, classifiedFactory) {

            var vm = this;

            var editing;
            vm.closeSidebar = closeSidebar;
            vm.saveClassified = saveClassified;

            vm.editing = false;
            $timeout(function () {
                $mdSidenav('left').open();
            });

            $scope.$watch('vm.sidenavOpen', function (sidenav) {
                if (sidenav === false) {
                    $mdSidenav('left')
                        .close()
                        .then(function () {
                            $state.go('classifieds');
                        });
                }
            });

            function closeSidebar() {
                vm.sidenavOpen = false;
            };

            function saveClassified(classified) {
                if (classified) {
                    classified.contact = {
                        name: "Rahul R",
                        phone: "+919768937920",
                        email: "rahulhellboyz@gmail.com"
                    };

                    $scope.$emit('newClassified', classified);
                    vm.sidenavOpen = false;
                }
            };

        });
})();