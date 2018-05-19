class Scanner extends Toybox.Ant.GenericChannel {

    const DEVICE_NUMBER = 0; // Wildcard, any device number works.
    const SEARCH_TIMEOUT_PRIORITY_10_S = 4; // In 2.5s increments, 30s max.

    hidden var _devices;
    hidden var _scanning;

    function initialize() {

        var chanAssign = new Toybox.Ant.ChannelAssignment( Toybox.Ant.CHANNEL_TYPE_RX_ONLY,
                                                           Toybox.Ant.NETWORK_PUBLIC );
        chanAssign.setBackgroundScan( true );

        var deviceConfig = new Toybox.Ant.DeviceConfig( {
            :radioFrequency => ANTConstants.FREQ,
            :messagePeriod => ANTConstants.PERIOD_4HZ,
            :deviceType => ANTConstants.DEVICE_TYPE,
            :deviceNumber => DEVICE_NUMBER,
            :searchThreshold => ANTConstants.NO_PROXIMITY_SEARCH,
            :transmissionType => ANTConstants.TRANSMISSION_TYPE,
            :searchTimeoutLowPriority => SEARCH_TIMEOUT_PRIORITY_10_S
        } );

        GenericChannel.initialize( method(:onMessage), chanAssign );
        GenericChannel.setDeviceConfig( deviceConfig );

        self._scanning = false;
        self._devices = {};

        System.println("Scanner.initialize()");
    }

    function onMessage( message ) {

        if( Ant.MSG_ID_BROADCAST_DATA == message.messageId ) {

            if( false == self._devices.hasKey( message.deviceNumber ) ) {

                self._devices[message.deviceNumber] = message.deviceNumber;
                System.println("Device found: " + message.deviceNumber.format("%d"));
            }

        } else if( Ant.MSG_ID_CHANNEL_RESPONSE_EVENT == message.messageId ) {

            var payload = message.getPayload();

            if ( Ant.MSG_ID_RF_EVENT == (payload[0] & 0xFF) ) {

                if ( Ant.MSG_CODE_EVENT_CHANNEL_CLOSED == (payload[1] & 0xFF) ) {

                    self.stopScan();
                    System.println( "Scanner.onMessage() found MSG_CODE_EVENT_CHANNEL_CLOSED." );
	            }
       	    }  else {

       	    	// Ignored channel response.
        	}
        }
    }

    function startScan() {

        if ( self._scanning ) {
            return false;
        }

        self._devices = {};

        self.open();
        self._scanning = true;
    }

    function stopScan() {

        if ( !self._scanning ) {
            return false;
        }

        self.close();
        self._scanning = false;
    }

    function getDeviceCount() {

        return self._devices.values().size();
    }

    function getDevices() {

        return self._devices;
    }

    function isScanning() {

        return self._scanning;
    }

    function getScanLenSeconds() {

    	return (SEARCH_TIMEOUT_PRIORITY_10_S * ANTConstants.SEARCH_TIMEOUT_UNITS_S);
    }
}
