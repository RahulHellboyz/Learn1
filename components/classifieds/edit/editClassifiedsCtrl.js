(function () {
    "use strict";

    angular
        .module('Learn')
        .controller('editClassifiedCtrl', function ($scope, $state, $timeout, $mdSidenav, $mdDialog, classifiedFactory) {

            var vm = this;

            var editing;
            vm.closeSidebar = closeSidebar;
            vm.editClassified = editClassified;
            vm.classified = $state.params.classified;           

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
                vm.classified={};
                vm.sidenavOpen = false;
            };

            function editClassified() {                          ;
                $scope.$emit('editSaved','Edit Saved');
                vm.sidenavOpen = false;
            };
        });
})();