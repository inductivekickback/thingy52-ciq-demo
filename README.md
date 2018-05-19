A simple [Connect IQ](https://developer.garmin.com/connect-iq/what-you-can-build/) app for interacting with a [Nordic Thingy:52](https://www.nordicsemi.com/eng/Products/Nordic-Thingy-52) using the [ANT wireless protocol](https://www.thisisant.com/developer/ant/ant-basics/).

<img src="https://user-images.githubusercontent.com/6494431/40264613-d6acbe10-5adc-11e8-8881-54a4692570c5.png" width="168" height="284">

### Features
The application consists of a simple GUI that allows the user to scan for devices running the ANT version of the Thingy:52 firmware, display a Thingy's sensor data, and set the color of the Thingy's LED.

### Building the app
Download version 2.4.4 of the [CIQ SDK](https://developer.garmin.com/connect-iq/sdk/) and then clone the project into the "Samples" directory. Generate a developer key and place it in the root of the SDK directory. Then compile the app for the Forerunner 645:

```
$ monkeyc -o ./THINGY_FR645.PRG -f ./monkey.jungle -y ../../developer_key.der -d fr645
```

To run the app in the simulator start the simulator in one terminal:

```
$ connectiq
```

and then launch the app in the simulator:

```
$ monkeydo ./THINGY_FR645.PRG fr645
```

The firmware for the Thingy can be downloaded and compiled from the ANT branch of the [Thingy repository](https://github.com/NordicSemiconductor/Nordic-Thingy52-FW).
