#ifndef WHEELTEST_MICROCHIP
#define WHEELTEST_MICROCHIP

#include "Streaming.h"
#include "SparkFunMLX90614.h"

//PINS
#define TACH_IN       53  //Digital Pin (Configured with PULL_UP: 20 to 50 kΩ on board resistors)
#define THERMISTOR_IN A2  //Analog Pin  (10kΩ pull up resistor on board)

//I2C ADDRESSES
#define WHEEL   0x5A  //Address of the wheel thermometer
#define BEARING 0x5B  //Address of the bearing thermometer

//COMMANDS
#define START 0xF
#define STOP  0x1
#define PING  0xA
#define PONG  0xB

//TYPES:
typedef unsigned long Time;

//VARIABLES:
double RPM;               //RPM of the wheel
float tempBearing;        //Temperature of the bearing (IR)
float tempWheel;          //Temperature of the wheel (IR)
float tempAxle;           //Temperature of the Axle (Thermistor)

Time startTime;       //used to store the time at the start of recording
Time lastRevolution;  //used to store the previous time, so that we can tell the difference
boolean lastTachRead; //used to store the last reading from the tach (0 or 1)
boolean recording;

IRTherm thermWheel;        //used to get the temperatures from the IR thermometers
IRTherm thermBearing;

double getTempAxle(void);  //Retrieves the temperature from the thermistor on the axle
void reset(void);          //Resets the variables

#endif
