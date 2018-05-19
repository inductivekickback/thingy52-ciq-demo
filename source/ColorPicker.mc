using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;

class ColorPicker extends Ui.Picker {

    var factory;
    var title;

    const COLOR_RED_INDEX = 0;
    const COLOR_GREEN_INDEX = 1;
    const COLOR_BLUE_INDEX = 2;

    function initialize( defaultColorIndex ) {

        title = new Ui.Text( { :text=>"Choose color:",
                               :locX=>Ui.LAYOUT_HALIGN_CENTER,
                               :locY=>Ui.LAYOUT_VALIGN_BOTTOM,
                               :color=>Gfx.COLOR_WHITE } );
        factory = new ColorFactory([Gfx.COLOR_RED, Gfx.COLOR_GREEN, Gfx.COLOR_DK_BLUE]);

        var nextArrow = new Ui.Bitmap( { :rezId=>Rez.Drawables.nextArrow,
                                         :locX => Ui.LAYOUT_HALIGN_CENTER,
                                         :locY => Ui.LAYOUT_VALIGN_CENTER } );
        var previousArrow = new Ui.Bitmap( { :rezId=>Rez.Drawables.previousArrow,
                                             :locX => Ui.LAYOUT_HALIGN_CENTER,
                                             :locY => Ui.LAYOUT_VALIGN_CENTER } );
        Picker.initialize( { :title=>title,
                             :pattern=>[factory],
                             :defaults=>null,
                             :nextArrow=>nextArrow,
                             :previousArrow=>previousArrow,
                             :defaults=>[defaultColorIndex] } );
    }

    function onUpdate(dc) {

        dc.setColor( Gfx.COLOR_BLACK, Gfx.COLOR_BLACK );
        dc.clear();
        Picker.onUpdate(dc);
    }
}

class ColorPickerDelegate extends Ui.PickerDelegate {

    hidden var _colorPickedCB;

    function initialize( colorPickedCB ) {

        self._colorPickedCB = colorPickedCB;
        PickerDelegate.initialize();

        System.println( "ColorPickerDelegate.initialize()." );
    }

    function onCancel() {

        System.println( "ColorPickerDelegate.onCancel is about to popView." );
        Ui.popView(Ui.SLIDE_IMMEDIATE);
    }

    function onAccept( values ) {

        System.println( "ColorPickerDelegate.onAccept is about to popView." );
        Ui.popView(Ui.SLIDE_IMMEDIATE);
        System.println( "ColorPickerDelegate.onAccept has popped the Picker." );
        self._colorPickedCB.invoke( values[0] );
    }
}
