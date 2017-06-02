(function(){
    "use strict";

    angular.module("Learn")
    .controller("classifiedCtrl",function($scope,$http,$state,$mdSidenav,$mdToast,$mdDialog,classifiedFactory){

        var vm = this;

        var categories; 
        var classifieds;               
        var classified;
        var editing;
        
        vm.closeSidebar=closeSidebar;
        vm.deleteClassified=deleteClassified;
        vm.editClassified=editClassified;
        vm.getCategories=getCategories; 
        vm.openSidebar=openSidebar;
        vm.saveClassified=saveClassified;        
        vm.saveEdit=saveEdit;        
        vm.showToast=showToast;               

        var contact={
            name:"Rahul R",
            phone:"+919768937920",
            email:"rahulhellboyz@gmail.com"
        };        

        vm.editing=false;

        classifiedFactory.getClassifieds().then(function(classified){
           vm.classifieds=classified.data;  
           vm.categories=getCategories(vm.classifieds);          
        });

        $scope.$on('newClassified',function(event, classified){
            classified.id = vm.classifieds.length+1;
            vm.classifieds.push(classified);
            showToast("Classified saved!");
        });
        
        function openSidebar(){            
            $state.go('classifieds.new');
            // $mdSidenav('left').open();
        };

        function closeSidebar(){
            $mdSidenav('left').close();           
        };
        
        function saveClassified(classified){
            if(classified)
            {
                classified.contact=contact;
                vm.classifieds.push(classified);
                vm.classified={};
                closeSidebar();
                showToast("Classified Saved!!");
            }            
        };

        function editClassified (classified){  
            console.log(classified);
            vm.editing=true;
            openSidebar(); 
            vm.classified=classified;           
        };

        function saveEdit (){
            vm.editing=false;
            vm.classified={};
            closeSidebar();
            showToast("Edit Saved!!");
        };

        function deleteClassified (event,classified){            
            var confirm=$mdDialog.confirm()
                .title('Are you sure you want to delete '+classified.title+' ?')
                .ok('Yes')
                .cancel('No')
                .targetEvent(event);

            $mdDialog.show(confirm).then(function(){
                var index=vm.classifieds.indexOf(classified);
                vm.classifieds.splice(index,1);
            },function(){

            });            
        };

        function showToast(message){
             $mdToast.show(
                    $mdToast.simple()
                    .textContent(message)
                    .position('top,right')
                    .hideDelay(3000)
                );
        };

        function getCategories(classifieds){
            var categories=[];            
            angular.forEach(classifieds,function(item) {
                angular.forEach(item.categories,function(category) {
                    categories.push(category);
                });
            });

            return _.uniq(categories);
        };
    });
})();