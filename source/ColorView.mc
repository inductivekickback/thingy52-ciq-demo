using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;

class ColorView extends Toybox.WatchUi.View
{

    hidden var _promptStr;

    hidden var _weakThingyViewRef;
    hidden var _channelClosed;
    hidden var _color;
    hidden var _colorOperationPending;
    hidden var _isVisible;

    function initialize( thingyView ) {

        self._weakThingyViewRef = thingyView.weak();
        self._channelClosed = false;
        self._color = null;
        self._colorOperationPending = false;
        View.initialize();
        System.println( "ColorView.initialize()" );
    }

    function onLayout( dc ) {

        self._promptStr = new Ui.Text( { :text=>"",
                                        :color=>Graphics.COLOR_WHITE,
                                        :font=>Graphics.FONT_MEDIUM,
                                        :locX=>Ui.LAYOUT_HALIGN_CENTER,
                                        :locY=>Ui.LAYOUT_VALIGN_CENTER } );

        System.println( "ColorView.onLayout()" );
    }

    function onShow() {

        self._isVisible = true;
        System.println( "ColorView.onShow()" );
    }

    function onUpdate( dc ) {

        if ( self._channelClosed ) {

            self._promptStr.setText( "Attempting to\nreconnect..." );
            dc.setColor( Gfx.COLOR_BLACK, Gfx.COLOR_WHITE );
        } else {

            // TODO: This is MENU on the VVA3. Maybe TAP instead?
            self._promptStr.setText( "Press START to\nselect color..." );

            if ( null == self._color ) {

                dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_BLACK );
            } else {

                switch( self._color ) {
                case ThingyDevice.COLOR_RED:
                     dc.setColor( Gfx.COLOR_WHITE,
                                  Gfx.COLOR_DK_RED );
                     break;
                case ThingyDevice.COLOR_GREEN:
                     dc.setColor( Gfx.COLOR_WHITE,
                                  Gfx.COLOR_DK_GREEN );
                     break;
                case ThingyDevice.COLOR_BLUE:
                     dc.setColor( Gfx.COLOR_WHITE,
                                  Gfx.COLOR_DK_BLUE );
                     break;
                default:
                     dc.setColor( Gfx.COLOR_WHITE,
                                  Gfx.COLOR_BLACK );
                     break;
                }
            }
        }

        dc.clear();
        self._promptStr.draw( dc );

        System.println("ColorView.onUpdate()");
    }

    function onHide() {

        self._isVisible = false;
        View.onHide();
        System.println("ColorView.onHide()");
    }

    function setColor( color ) {

        System.println( "Entering ColorView.setColor..." );

        if ( self._colorOperationPending ) {

            System.println( "Popping progress bar..." );
            Ui.popView( Ui.SLIDE_IMMEDIATE );
            self._colorOperationPending = false;
        }

        if ( null != color ) {

            self._color = color;
        }

        System.println( "Exiting ColorView.setColor." );
    }

    function onColorPicked( color ) {

        var thingyColor = ThingyDevice.COLOR_WHITE;

        switch( color ) {
        case Gfx.COLOR_RED:
            thingyColor = ThingyDevice.COLOR_RED;
            System.println( "ColorView.colorPicked: RED." );
            break;
        case Gfx.COLOR_GREEN:
            thingyColor = ThingyDevice.COLOR_GREEN;
            System.println( "ColorView.colorPicked: GREEN." );
            break;
        case Gfx.COLOR_BLUE:
            thingyColor = ThingyDevice.COLOR_BLUE;
            System.println( "ColorView.colorPicked: BLUE." );
            break;
        default:
            System.println( "ColorView.colorPicked: ERROR." );
            break;
        }

        var thingyView = self._weakThingyViewRef.get();
        if (null != thingyView) {
    
            self._colorOperationPending = thingyView.setColor( thingyColor );

            if( self._colorOperationPending ) {

                Ui.pushView( new Ui.ProgressBar( "Sending command...", null ),
                             new ColorProgressDelegate( self ),
                             Ui.SLIDE_IMMEDIATE );
                System.println( "Color command progress bar pushed." );
            }
        }

        System.println( "ColorView.colorPicked()." );
    }

    function channelOpen() {

        if ( self._channelClosed ) {

            self._channelClosed = false;
            Ui.requestUpdate();
        }
    }

    function channelClosed() {

        if ( !self._colorOperationPending && !self._isVisible ) {

            System.println( "ColorView: Popping ColorPicker." );
            Ui.popView( Ui.SLIDE_IMMEDIATE );
        }

        if ( self._channelClosed ) {

            return;
        }

        self._channelClosed = true;

        Ui.requestUpdate();

        System.println( "ColorView.channelClosed()." );
    }

    function getDefaultColorPickerIndex() {
        return lookupPickerIndex( self._color );
    }

    function getChannelClosed() {

        return self._channelClosed;
    }

    function commandCancelled() {

        System.println( "ColorView: commandCancelled." );
        var thingyView = self._weakThingyViewRef.get();
        if (null != thingyView) {
    
            thingyView.thingyViewExit();
        }
    }

    hidden function lookupPickerIndex( thingyColor ) {

        if ( null == thingyColor ) {

            return ColorPicker.COLOR_RED_INDEX;
        }

        switch( thingyColor ) {
        case ThingyDevice.COLOR_BLUE:
            return ColorPicker.COLOR_BLUE_INDEX;
        case ThingyDevice.COLOR_GREEN:
            return ColorPicker.COLOR_GREEN_INDEX;
        default:
            return ColorPicker.COLOR_RED_INDEX;
        }
    }
}

class ColorViewDelegate extends Ui.BehaviorDelegate {

    hidden var _weakThingyViewRef;
    hidden var _weakColorViewRef;

    function initialize( thingyView, colorView ) {

    	self._weakThingyViewRef = thingyView.weak();
        self._weakColorViewRef = colorView.weak();
        BehaviorDelegate.initialize();
        System.println( "ColorViewDelegate.initialize()" );
    }

    function onMenu() {

        System.println( "ColorViewDelegate.onMenu()" );
        return true;
    }

    function onNextPage() {

        changePage( true );

        System.println( "ColorViewDelegate.onNextPage()" );
    }

    function onPreviousPage() {

        changePage( false );

    	// This is swiping down.
        System.println( "ColorViewDelegate.onPreviousPage()" );
    }

    function onTap( clickEvent ) {

        System.println( "ColorViewDelegate.onTap()." );
    }

    function onKey(keyEvent) {

        System.println( "ColorViewDelegate.onKey( " + keyEvent.getKey().toString() + " )" );

        if ( Ui.KEY_ESC == keyEvent.getKey() ) {

    		// If the user swipes right on the page it registers as KEY_ESC
    		// and pops the view.
            System.println( "ESC from ColorView." );

            var thingyView = self._weakThingyViewRef.get();
            if (null != thingyView) {
    
                thingyView.thingyViewExit();
            }
    	}

    	if ( Ui.KEY_ENTER == keyEvent.getKey() ) {

            var defaultIndex = 0;
            var channelClosed = true;

            var colorView = self._weakColorViewRef.get();
            if (null != colorView) {
    
                defaultIndex = colorView.getDefaultColorPickerIndex();
                channelClosed = colorView.getChannelClosed();
            }

            if( !channelClosed ) {
                Ui.pushView( new ColorPicker( defaultIndex ),
                             new ColorPickerDelegate( method(:onColorPicked) ),
                             Ui.SLIDE_IMMEDIATE );
            }

            // If the user presses the side button on the VVA3 it registers as KEY_ENTER
            // and pops the view. Prevent this.

    		return true;
    	}
    }

    function onColorPicked( color ) {

        var colorView = self._weakColorViewRef.get();
        if (null != colorView) {
    
            colorView.onColorPicked( color );
        }

        System.println( "ColorViewDelegate.onColorPicked: " + color.toString() );
        return true;
    }

    hidden function changePage( slideUp ) {

        var thingyView = self._weakThingyViewRef.get();
        if (null != thingyView) {
    
            thingyView.switchToSensorView( slideUp );
        }
    }
}

class ColorProgressDelegate extends Ui.BehaviorDelegate {

    hidden var _weakColorViewRef;

    function initialize( colorView ) {

        self._weakColorViewRef = colorView.weak();
        BehaviorDelegate.initialize();
        System.println( "ColorProgressDelegate.initialized()" );
    }

    function onBack() {

        System.println( "ColorProgressDelegate.onBack()" );

        var colorView = self._weakColorViewRef.get();
        if (null != colorView) {
    
            colorView.commandCancelled();
        }

        return true;
    }
}
