#include <Wire.h>
#include <math.h>
#include "wheeltest_microchip.h"

void setup() {
  Serial.begin(9600);

  //Initialize pins
  pinMode(TACH_IN, INPUT_PULLUP); //TODO: Check if INPUT_PULLUP matters here.
  pinMode(THERMISTOR_IN, INPUT);

  //Begin communication with the thermometers (setting addresses on the I2C bus)
  thermWheel.begin(WHEEL);
  thermBearing.begin(BEARING);
  
  //Set temperature of thermometers to deg F
  thermWheel.setUnit(TEMP_F);
  thermBearing.setUnit(TEMP_F);

  //Initialize Variables
  reset();
  recording = false;
}

void loop() {
  //--------------------------------------------------
  //  COMMANDS
  //--------------------------------------------------
  //Process commands first
  if (Serial.available()) {
    int input = Serial.read(); //Read command

    switch (input) {
      case START: //Start recording command
        Serial.end();       //Clears all of the data in the cache
        Serial.begin(9600); //Restarts the Serial communication

        //Print header for the CSV file
        Serial.println("Time,RPM,Bearing Temperature,Wheel Temperature,Axle Temperature");

        //Re-initialize and turn recorder on
        reset();
        recording = true;
        break;
      case PING: //Handshake command, reply with pong
        Serial.write(PONG);
        break;
      default: //Turn the recorder off
        recording = false;
        break;
    }
  }

  //Don't do anything until we are recording
  if (!recording) return;


  //--------------------------------------------------
  //  PARSE SENSOR INFORMATION
  //--------------------------------------------------
  //Input the current reading from the tachometer
  boolean currentTachRead = digitalRead(TACH_IN);

  //A revolution is when the tachometer reading goes from HIGH to LOW (because of the pullup resistor)
  if (currentTachRead == HIGH && lastTachRead == LOW) {
    Time difference = millis() - lastRevolution; //Time of one revolution
    lastRevolution = millis();                   //Update time of last revolution
    
    RPM = 1 / ((double) difference) / 1000 * 60;   //RPM calculation
  }
  
  //Read values from thermometers
  if (thermWheel.read())
    tempWheel   = thermWheel.object();
  if (thermBearing.read())
    tempBearing = thermBearing.object();
  
  //Get the temperature from the thermistor on the axel
  tempAxle = getTempAxle();
  
  //Print to file
  //                 Time              |     RPM     | Bearing Temperature | Wheel Temperature | Axle Temperature
  Serial << (millis() - startTime) << "," << RPM << "," << tempBearing << "," << tempWheel << "," << tempAxle << endl;

  //Update the last tachometer reading
  lastTachRead = currentTachRead;
}

//Retrieves the temperature from the thermistor on the axle in deg F
double getTempAxle() {
  double reading = analogRead(THERMISTOR_IN);
  double RoverR25 = 1 / (1023 / reading - 1);
  
  if (RoverR25 <= 0) return 0;
  double x = log(RoverR25);
  
  return (1 / (0.003354016 + 0.0002565236 * x + 2.605970E-6 * x * x + 6.329261E-8 * x * x * x) - 273.15) * 1.8 + 32;
}

//Resets the variables
void reset() {
  RPM = 0;
  tempBearing = (thermBearing.read() ? thermBearing.object() : 0);
  tempWheel = (thermWheel.read() ? thermWheel.object() : 0);
  tempAxle = getTempAxle();
  lastTachRead = digitalRead(TACH_IN);
  lastRevolution = millis();
  startTime = millis();
}
