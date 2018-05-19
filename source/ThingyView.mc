using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Timer as Timer;

class ThingyView extends Ui.View {

    hidden var _scanner;
    hidden var _thingyDevice;

    hidden var _scanning;
    hidden var _scanningRestarting;

    hidden var _progressBar;
    hidden var _timer;
    hidden var _progress;
    hidden var _progressIncrement;

    hidden var _sensorView;
    hidden var _sensorViewDelegate;
    hidden var _sensorViewShown;

    hidden var _colorView;
    hidden var _colorViewDelegate;
    hidden var _colorViewShown;
    hidden var _colorOperationPending;

    function initialize() {

        self._scanning = false;
        self._scanningRestarting = false;

        self._sensorViewShown = false;
        self._colorViewShown = false;
        self._colorOperationPending = false;

        View.initialize();

        System.println( "ThingyView.initialize()" );
    }

    function onLayout( dc ) {

        self._scanner = new Scanner();
        self._thingyDevice = new ThingyDevice();

        self._sensorView = new SensorView();
        self._sensorViewDelegate = new SensorViewDelegate( self );

        self._colorView = new ColorView( self );
        self._colorViewDelegate = new ColorViewDelegate( self, self._colorView );

        self._timer = new Timer.Timer();

        setLayout(Rez.Layouts.MainLayout(dc));

        System.println("ThingyView.onLayout()");
    }

    function onShow() {

        // There doesn't seem to be a nice way to detect that the user closed
        // the progress bar so a state variable is used as a hack.
        if ( !self._scanningRestarting && self._scanning ) {

            System.println( "ThingyView -- user closed the progress bar?" );
            self.scanCancelled();
        } else if ( self._scanningRestarting ) {

            System.println( "ThingyView: scanningRestarting.");
        } else if ( !self._sensorViewShown && !self._colorViewShown ) {

            self._timer.stop();
            System.println( "ThingyView.onShow stopped the timer." );
        } else if ( self._thingyDevice.isOpen() ) {

            self._thingyDevice.disconnect();
            self._timer.stop();
            System.println( "Disconnecting the Thingy and stopping the timer." );
        }

        self._scanningRestarting = false;

        System.println( "ThingyView.onShow()" );
    }

    function onUpdate(dc) {

        View.onUpdate(dc);
        System.println( "ThingyView.onUpdate()" );
    }

    function onHide() {

        System.println( "ThingyView.onHide()" );
    }

    function timerCallback() {

        if (self._scanning) {

            if ( !self._scanner.isScanning() ) {

                scanFinished();
            } else {

                var count = self._scanner.getDeviceCount();

                self._progress += self._progressIncrement;

                if ( 100 <= self._progress ) {

                    self._progressBar.setProgress( 100 );
                } else {

                    self._progressBar.setProgress( self._progress );
                }

                if ( 0 < count ) {

                    if ( 1 == count ) {
                        self._progressBar.setDisplayString( "Found: 1" );
                    } else {
                        self._progressBar.setDisplayString( "Found: " + count.format( "%d" ) );
                    }
                }

                Ui.requestUpdate();
            }
        } else {

            var isConnected = self._thingyDevice.isConnected();

            if ( !isConnected ) {

                if ( self._sensorViewShown ) {

                    self._sensorView.channelClosed();
                } else if ( self._colorViewShown ) {

                    self._colorView.channelClosed();
                }
            } else {

                if ( self._sensorViewShown ) {

                    System.println( "Polling thingy data." );
                    self._sensorView.update( self._thingyDevice.getTemperature(),
                                             self._thingyDevice.getBatteryLevel(),
                                             self._thingyDevice.getHumidity() );
                } else if ( self._colorViewShown ) {

                    self._colorView.channelOpen();
                }
            }
        }

        System.println( "ThingyView.timerCallback()" );
    }

    function setColor( color ) {

        if ( self._colorOperationPending ) {

            System.println( "ThingyView: setColor aborted due to pending." );
            return false;
        }

        var result = self._thingyDevice.setColor( color,
                                                  self.method( :onColorSet ) );
        self._colorOperationPending = result;

        System.println( "ThingyView setColor()." );
        return result;
    }

    function onColorSet( succeeded ) {

        System.println( "Entering ThingyView.onColorSet...");

        self._colorOperationPending = false;

        if ( succeeded ) {

            if ( self._colorViewShown ) {

                self._colorView.setColor( self._thingyDevice.getColor() );
            }

            System.println( "ThingyView: LED color set." );
        } else {

            if ( self._colorViewShown ) {

                self._colorView.setColor( null );
            }

            System.println( "ThingyView: LED color failed." );
        }
    }

    hidden function scanFinished() {

        var devices = self._scanner.getDevices();
        var keys = devices.keys();
        var count = keys.size();

        self._scanning = false;
        self._scanningRestarting = false;

        // Remove the progress bar.
        Ui.popView( Ui.SLIDE_IMMEDIATE );

        if (0 < count) {

            var menu = new Ui.Menu();
            menu.setTitle( "Devices:" );

            if ( menu.MAX_SIZE < count ) {
                System.println( "More than WatchUI::Menu.MAX_SIZE ANT devices found: " + count.format("%d") );
                count = menu.MAX_SIZE;
            }

            for( var i = 0; i < count; i++ ) {

                var deviceNum = keys[i];
                menu.addItem( deviceNum.toString(), deviceNum );
            }

            self._sensorViewShown = true;

            self._timer.start( method(:timerCallback), 1000, true );
            System.println( "ThingyView.scanTimedOut()" );

            Ui.pushView( menu,
                         new ScanMenuDelegate( self ),
                         Ui.SLIDE_LEFT );
        } else {

            System.println( "No devices found." );

            var message = "Scan again?";
            var dialog = new Ui.Confirmation( message );
            Ui.pushView( dialog,
                         new ScanConfirmationDelegate( self ),
                         Ui.SLIDE_LEFT );
        }
    }

    function scanCancelled() {

        self._timer.stop();
        self._scanner.stopScan();

        System.println( "ThingyView.scanCancelled()" );

        System.exit();
    }

    function scanStart() {

        self._progressBar = new Ui.ProgressBar( "Found: 0", 0 );
        Ui.pushView( self._progressBar,
                     new ProgressDelegate( self ),
                     Ui.SLIDE_IMMEDIATE );

        self._progressIncrement = ( ( 100 / self._scanner.getScanLenSeconds() ) + 1);

        self.resetProgressBar();

        self._scanner.startScan();

        System.println( "ThingyView.scanStart()" );
    }

    function connectToDevice( deviceNumber ) {

        self._thingyDevice.connectToDevice( deviceNumber );

        Ui.switchToView( self._sensorView,
                             self._sensorViewDelegate,
                             Ui.SLIDE_LEFT );
    }

    function switchToColorView( slideUp ) {

        self._colorViewShown = true;
        self._sensorViewShown = false;
        if( slideUp ) {

            Ui.switchToView( self._colorView,
                             self._colorViewDelegate,
                             Ui.SLIDE_UP );
        } else {

            Ui.switchToView( self._colorView,
                             self._colorViewDelegate,
                             Ui.SLIDE_DOWN );
        }
    }

    function switchToSensorView( slideUp ) {

        self._colorViewShown = false;
        self._sensorViewShown = true;
        if( slideUp ) {

            Ui.switchToView( self._sensorView,
                             self._sensorViewDelegate,
                             Ui.SLIDE_UP );
        } else {

            Ui.switchToView( self._sensorView,
                             self._sensorViewDelegate,
                             Ui.SLIDE_DOWN );
        }
        self._sensorView.update( self._thingyDevice.getTemperature(),
                                 self._thingyDevice.getBatteryLevel(),
                                 self._thingyDevice.getHumidity() );                         
    }

    function thingyViewExit() {

        self._thingyDevice.release();
        System.println( "ThingyView.thingyViewExit()" );
    }

    hidden function resetProgressBar() {

        self._scanning = true;
        self._scanningRestarting = true;
        self._progress = 0;
        self._progressBar.setProgress( self._progress );
        self._timer.start( method(:timerCallback), 1000, true );

        System.println( "ThingyView progress bar reset." );
    }
}

class ThingyViewDelegate extends Ui.BehaviorDelegate {

    hidden var _weakThingyViewRef;

    function initialize( thingyView ) {

        self._weakThingyViewRef = thingyView.weak();
        BehaviorDelegate.initialize();
    }

    function onMenu() {

        System.println( "ThingyViewDelegate.onMenu()" );
    }

    function onNextPage() {

        System.println( "ThingyViewDelegate.onNextPage()" );
    }

    function onPreviousPage() {

        System.println( "ThingyViewDelegate.onPreviousPage()" );
    }

    function onTap( clickEvent ) {

        startScan();
        System.println( "ThingyViewDelegate.onTap()." );
    }

    function onKey(keyEvent) {

        switch ( keyEvent.getKey() ) {
        case Ui.KEY_ENTER:
            startScan();
            break;
        default:
            break;
        }

        System.println( "ThingyViewDelegate.onKey(" + keyEvent.getKey() + ")" ); // e.g. KEY_MENU = 7
    }

    hidden function startScan() {

        var thingyView = self._weakThingyViewRef.get();
        if (null != thingyView) {
    
            thingyView.scanStart();
        }
    }
}

class ProgressDelegate extends Ui.BehaviorDelegate {

    hidden var _weakThingyViewRef;

    function initialize( thingyView ) {

        self._weakThingyViewRef = thingyView.weak();
        BehaviorDelegate.initialize();
        System.println( "ProgressDelegate.initialized()" );
    }

    function onBack() {

        System.println( "ProgressDelegate.onBack()" );

        var thingyView = self._weakThingyViewRef.get();
        if (null != thingyView) {
    
            thingyView.scanCancelled();
        }

        return true;
    }
}

class ScanConfirmationDelegate extends Ui.ConfirmationDelegate {

    hidden var _weakThingyViewRef;

    function initialize( thingyView ) {

        self._weakThingyViewRef = thingyView.weak();

        ConfirmationDelegate.initialize();
        System.println( "ScanConfirmationDelegate.initialized()" );
    }

    function onResponse( response ) {

        if ( Ui.CONFIRM_NO == response ) {
            // Do nothing and go back to the title page.
        } else {

            var thingyView = self._weakThingyViewRef.get();
            if (null != thingyView) {
    
                thingyView.scanStart();
            }
        }
    }
}

class ScanMenuDelegate extends Ui.BehaviorDelegate {

    hidden var _weakThingyViewRef;

    function initialize( thingyView ) {

        self._weakThingyViewRef = thingyView.weak();

        MenuInputDelegate.initialize();

        System.println( "ScanMenuDelegate.initialize()" );
    }

    function onMenuItem( item ) {

        var thingyView = self._weakThingyViewRef.get();
        if (null != thingyView) {
    
            thingyView.connectToDevice( item );
        }

        System.println( "ScanMenuDelegate.onMenuItem(" + item.toString() + ")" );
    }
}
