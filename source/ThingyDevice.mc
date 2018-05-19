using Toybox.Ant;

class ThingyDevice extends Ant.GenericChannel {

    const MAX_LOW_PRIORITY_SEARCH_30S = 12; // In 2.5s increments, 30s max.
    const MAX_HIGH_PRIORITY_SEARCH_5S = 2; // In 2.5s increments, 5s max.

    const PAGE_BATTERY_LEVEL = 0;
    const PAGE_TEMPERATURE = 1;
    const PAGE_HUMIDITY = 2;
    const PAGE_LED_CMD = 55;

    const COLOR_RED = 0xFE;
    const COLOR_GREEN = 0xFD;
    const COLOR_BLUE = 0xFB;
    const COLOR_WHITE = 0xF8;

    hidden var _deviceNumber;
    hidden var _open;
    hidden var _connected;

    hidden var _batteryLevel = null;
    hidden var _temperature = null;
    hidden var _humidity = null;

    hidden var _color = null;
    hidden var _colorFinishedCB = null;
    hidden var _colorMessage = null;
    hidden var _desiredColor = null;

    function initialize() {

        self._deviceNumber = null;
        self._open = false;
        self._connected = false;
    }

    function connectToDevice( deviceNumber ) {

        if (self._open) {

            self.release();
            self._open = false;

            self._batteryLevel = null;
            self._temperature = null;
            self._humidity = null;
            self._color = null;
            self._colorFinishedCB = null;
            self._desiredColor = null;
        }

        var chanAssign = new Ant.ChannelAssignment( Ant.CHANNEL_TYPE_RX_NOT_TX,
                                                    Ant.NETWORK_PUBLIC );
        GenericChannel.initialize( method(:onMessage), chanAssign );

        self._deviceNumber = deviceNumber;

        var deviceConfig = new Ant.DeviceConfig( {
            :radioFrequency => ANTConstants.FREQ,
            :messagePeriod => ANTConstants.PERIOD_4HZ,
            :deviceType => ANTConstants.DEVICE_TYPE,
            :deviceNumber => deviceNumber,
            :transmissionType => ANTConstants.TRANSMISSION_TYPE,
            :searchTimeoutLowPriority => self.MAX_LOW_PRIORITY_SEARCH_30S,
            :searchTimeoutHighPriority => self.MAX_HIGH_PRIORITY_SEARCH_5S
        } );

        GenericChannel.setDeviceConfig( deviceConfig );
        GenericChannel.open();

        self._open = true;
        self._connected = false;

        System.println( "ThingyDevice: Connecting to device: " + deviceNumber.toString() );
    }

    function getBatteryLevel() {

        return self._batteryLevel;
    }

    function getTemperature() {

        return self._temperature;
    }

    function getHumidity() {

        return self._humidity;
    }

    function getColor() {

        return self._color;
    }

    function isOpen() {

        return self._open;
    }

    function isConnected() {

        return self._connected;
    }

    function disconnect() {

        if ( ( null != self._desiredColor ) && ( null != self._colorFinishedCB ) ) {

            self._desiredColor = null;
            self._colorFinishedCB.invoke( false );
            System.println( "ThingyDevice: Giving up on setting the LED color." );
        }

        self.release();
        self._open = false;
        self._connected = false;
        self._batteryLevel = null;
        self._temperature = null;
        self._humidity = null;
        self._color = null;
        self._colorFinishedCB = null;

    }

    function setColor( color, finishedCallback ) {

        if ( !self._connected || ( null != self._desiredColor )) {

            return false;
        }

        switch( color ) {
        case COLOR_RED:
        case COLOR_GREEN:
        case COLOR_BLUE:
        case COLOR_WHITE:
            break;
        default:
            return false;
        }

        var data = new[8];

        data[0] = PAGE_LED_CMD;
        data[1] = 0xFF;
        data[2] = 0xFF;
        data[3] = 0xFF;
        data[4] = 0xFF;
        data[5] = 0xFF;
        data[6] = 0xFF;
        data[7] = color;

        self._colorMessage = new Ant.Message();
        self._colorMessage.setPayload(data);

        self._colorFinishedCB = finishedCallback;
        self._desiredColor = color;

        GenericChannel.sendAcknowledge( self._colorMessage );
        System.println( "ThingyDevice: color command sent." );

        return true;
    }

    function onMessage( message ) {

        System.println( "Entering ThingyDevice.onMessage..." );

        if( Ant.MSG_ID_BROADCAST_DATA == message.messageId ) {

        	var payload = message.getPayload();

            if ( !self._connected ) {

                self._connected = true;
                System.println( "ThingyDevice: connected." );
            }

            switch ( payload[0] & 0xFF ) {
            case PAGE_BATTERY_LEVEL:
                parseBatteryLevel( payload );
                break;
            case PAGE_TEMPERATURE:
                parseTemperature( payload );
                break;
            case PAGE_HUMIDITY:
                parseHumidity( payload );
                break;
            default:
                System.println( "Message with unknown page index received: " + payload[0].format( "%d" ) );
                break;
            }
        } else if( Ant.MSG_ID_CHANNEL_RESPONSE_EVENT == message.messageId ) {

        	var payload = message.getPayload();

        	if( Ant.MSG_ID_RF_EVENT == (payload[0] & 0xFF) ) {

            	if( Ant.MSG_CODE_EVENT_RX_FAIL_GO_TO_SEARCH == ( payload[1] & 0xFF ) ) {

                    // The device went away.
                    if ( ( null != self._desiredColor ) && ( null != self._colorFinishedCB ) ) {

                        self._desiredColor = null;
                        self._colorFinishedCB.invoke( false );
                    }

	                System.println( "Lost connection to device. Reconnecting." );
                    connectToDevice( self._deviceNumber );
            	}  else if( Ant.MSG_CODE_EVENT_CHANNEL_CLOSED == ( payload[1] & 0xFF ) ) {

                    if( self._open ) {

                        if ( ( null != self._desiredColor ) && ( null != self._colorFinishedCB ) ) {

                            self._desiredColor = null;
                            self._colorFinishedCB.invoke( false );
                        }

                        System.println( "Ant.MSG_CODE_EVENT_CHANNEL_CLOSED -- opening again." );
                        connectToDevice ( self._deviceNumber );
                    } else {

                		System.println( "Ant.MSG_CODE_EVENT_CHANNEL_CLOSED" );
                    }
            	} else if( Ant.MSG_CODE_EVENT_TRANSFER_TX_COMPLETED == ( payload[1] & 0xFF ) ) {

                    System.println( "ThingyDevice: ACK'd message completed." );
                    if ( ( null != self._desiredColor ) && ( null != self._colorFinishedCB ) ) {

                        self._color = self._desiredColor;
                        self._desiredColor = null;
                        self._colorFinishedCB.invoke( true );
                    }
                } else if( Ant.MSG_CODE_EVENT_TRANSFER_TX_FAILED == ( payload[1] & 0xFF ) ) {

                    System.println( "ThingyDevice: ACK'd message failed." );
                    if ( null != self._desiredColor ) {
                        GenericChannel.sendAcknowledge( self._colorMessage );
                        System.println( "ThingyDevice: Retrying ACK'd color command." );
                    }
                }
        	}
        }

        System.println( "Exiting ThingyDevice.onMessage..." );
    }

    hidden function parseBatteryLevel( payload ) {

        var level = ( payload[1] + ( payload[2] << 8 ) );
        self._batteryLevel = ( level / 1000.0 );
    }

    hidden function parseTemperature( payload ) {

        var temp_mag_times_100 = ( payload[2] + ( payload[3] << 8 ) );
        if( 0 == payload[1] ) {
            self._temperature = ( temp_mag_times_100 / 100.0 );
        } else {
            self._temperature = ( temp_mag_times_100 / -100.0 );
        }
    }

    hidden function parseHumidity( payload ) {

        var humidMag = ( payload[2] + ( payload[3] << 8 ) );
        if( 0 == payload[1] ) {
            self._humidity = humidMag ;
        }
        else {
            self._humidity = ( humidMag * -1 );
        }
    }
}
