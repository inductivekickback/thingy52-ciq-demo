using Toybox.Application as App;

class ThingyApp extends App.AppBase {

    function initialize() {

        AppBase.initialize();
        System.println("ThingyApp.initialize().");
    }

    function onStart(state) {

        System.println("ThingyApp.onStart().");
    }

    function onStop(state) {

        System.println("ThingyApp.onStop().");
    }

    function getInitialView() {

        var view = new ThingyView();
        System.println("ThingyApp.getInitialView()");
        return [ view, new ThingyViewDelegate(view) ];
    }
}
