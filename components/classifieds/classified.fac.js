(function(){
    "use strict";

    angular.module("Learn")
    .factory("classifiedFactory",function($http){

        function getClassifieds(){
            return $http.get("data/classifed.json");
        };        

        return {
        getClassifieds:getClassifieds
    }
    });

})();