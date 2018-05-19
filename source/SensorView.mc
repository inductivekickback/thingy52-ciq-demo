using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;

class SensorView extends Toybox.WatchUi.View
{

	const DEFAULT_VALUE = "   - -   ";
	const TEMP_UNITS_SUFFIX = "°C";
	const PERCENT_UNITS_SUFFIX = "%";
    const V_UNITS_SUFFIX = "V";

    const MAX_BATTERY_V = 4.2;
    const MIN_BATTERY_V = 3.7;

    const BATTERY_ICON_X = 52;
    const BATTERY_ICON_Y = 163;
    const MAX_BATTERY_RECT_WIDTH_PX = 27;
    const BATTERY_RECT_HEIGHT_PX = 13;

    hidden var _batteryLevel;
    hidden var _channelClosed;

    function initialize() {

    	self._batteryLevel = 0;
        self._channelClosed = true;
        View.initialize();
        System.println( "ColorView.initialize()" );
    }

    function onLayout( dc ){

        setLayout( Rez.Layouts.SensorLayout( dc ) );
    }

    function onShow() {

        System.println( "SensorView.onShow()" );
    }

    function onUpdate( dc ) {

    	var batteryRectWidth = MAX_BATTERY_RECT_WIDTH_PX;
    	batteryRectWidth *= calcBatteryPercentage( self._batteryLevel );

        View.onUpdate( dc );

    	dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_BLACK );
    	dc.fillRectangle( BATTERY_ICON_X,
    	                  BATTERY_ICON_Y,
    	                  batteryRectWidth,
    	                  BATTERY_RECT_HEIGHT_PX );

        System.println("SensorView.onUpdate()");
    }

    hidden function calcBatteryPercentage( value ) {

        if ( null == value )
        {
            return 0;
        }

    	if ( MIN_BATTERY_V >= value ) {
    		return 0;
    	}

    	if ( MAX_BATTERY_V <= value ) {
    		return 1.0;
    	}

    	return ( ( value - MIN_BATTERY_V ) / ( MAX_BATTERY_V - MIN_BATTERY_V ) );
    }

    function onHide() {

        View.onHide();
        System.println("SensorView.onHide()");
    }

    hidden function setDrawableValue( nameStr, value ) {

        var view = View.findDrawableById( nameStr );

        if ( null == view ) {
            return;
        }

        if (null != value) {

            if ( DEFAULT_VALUE == value ) {

                view.setText( DEFAULT_VALUE );
            } else {

                view.setText( value.format( "%.1f" ) );
            }
        }
    }

    function update( tempValue, batteryValue, humidityValue ) {

        self._channelClosed = false;
        self._batteryLevel = batteryValue;
        setDrawableValue( "TemperatureValue", tempValue );    
        setDrawableValue( "BatteryValue", batteryValue );
        setDrawableValue( "HumidityValue", humidityValue );

        Ui.requestUpdate();
    }

    function channelClosed() {

        if ( self._channelClosed ) {
            return;
        }

        self._channelClosed = true;
    	self._batteryLevel = 0;

        setDrawableValue( "TemperatureValue", DEFAULT_VALUE );
    	setDrawableValue( "BatteryValue", DEFAULT_VALUE );
    	setDrawableValue( "HumidityValue", DEFAULT_VALUE );

        Ui.requestUpdate();

      	System.println( "SensorView.channelClosed()." );
    }
}

class SensorViewDelegate extends Ui.BehaviorDelegate {

    hidden var _weakThingyViewRef;

    function initialize( thingyView ) {

    	self._weakThingyViewRef = thingyView.weak();
    	System.println( "SensorViewDelegate.initialize()" );
        BehaviorDelegate.initialize();
    }

    function onMenu() {

        System.println( "SensorViewDelegate.onMenu()" );
        return true;
    }

    function onNextPage() {

        changePage( true );

        System.println( "SensorViewDelegate.onNextPage()" );
    }

    function onPreviousPage() {

        changePage( false );

    	// This is swiping down.
        System.println( "SensorViewDelegate.onPreviousPage()" );
    }

    function onTap( clickEvent ) {

        System.println( "SensorViewDelegate.onTap()." );
    }

    function onKey(keyEvent) {

    	if ( Ui.KEY_ESC == keyEvent.getKey() ) {

    		// If the user swipes right on the page it registers as KEY_ESC
    		// and pops the view.
            
            var thingyView = self._weakThingyViewRef.get();
            if (null != thingyView) {
    
                thingyView.thingyViewExit();
            }
    	}

    	if ( Ui.KEY_ENTER == keyEvent.getKey() ) {

    		// If the user presses the side button on the VVA3 it registers as KEY_ENTER
    		// and pops the view. Prevent this.
    		return true;
    	}

        System.println( "SensorViewDelegate.onKey( " + keyEvent.getKey().toString() + " )" );
    }

    hidden function changePage( slideUp ) {

        var thingyView = self._weakThingyViewRef.get();
        if (null != thingyView) {
    
            thingyView.switchToColorView( slideUp );
        }
    }
}
