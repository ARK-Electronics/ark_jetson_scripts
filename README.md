# Getting started
This repository contains scripts and services for use with ARK Electronics companion computer hardware. You can safely run this script multiple times.
```
./setup.sh
```

#### Supported targets
- **ARK Jetson Carrier** <br> https://arkelectron.com/product/ark-jetson-pab-carrier/
- **ARK Pi6X Flow** <br> https://arkelectron.com/product/ark-pi6x-flow/


## Services

#### Common -- *installed at ~/.config/systemd/user*

**mavlink-router.service** <br>
This service enables mavlink-router to route mavlink packets between endpoints. The **platform/`target`/main.conf** file defines these endpoints and is installed at **/etc/mavlink-router/**. The USB on the FMU is connected directly to the companion for a reliable high speed chip to chip connection.

**dds-agent.service** <br>
Bridges PX4 uORB pub/sub with ROS2. This service starts the DDS agent which connects with the PX4 uXRCE-DDS-Client. The FMU `Telem1` port is connected directly to the Jetson UART. This service depends on the `systemd-timesyncd` service to synchronize system time with an accurate remote reference time source.

**logloader.service** <br>
This service downloads log files from the SD card of the flight controller via MAVLink and optionally uploads them to [PX4 Flight Review](https://review.px4.io/). <br>

**rtsp-server.service** <br>
This service provides an RTSP server via gstreamer using a Pi cam at **rtsp://`target`.local:8554/fpv** <br>

**polaris.service** <br>
This service receives RTCM corrections from the PointOne GNSS Corrections service and publishes them via MAVLink.

**ark-ui-backend.service** <br>
This service provides an express backend for the ark-ui configuration UI. The ARK UI is hosted via nginx at **`target`.local** and provides tools such as firmware updating, wifi hotspot configuration, log viewing (coming soon), and more.

**hotspot-control.service** <br>
This service creates a hotspot after booting if the device is unable to auto connect to a network. You can then use the ARK UI to configure your network.

#### Jetson only -- *installed at /etc/systemd/system*


**jetson-can.service** <br>
This service enables the Jetson CAN interface.

**jetson-clocks.service** <br>
This service sets the Jetson clocks to their maximum rate.

## Scripts
All installed scripts are placed at **/usr/local/bin**.
