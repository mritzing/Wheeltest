import processing.serial.*;
import controlP5.*;

//CONSTANTS ------------------------------------------
//↓ GUI size
final int btnH   = 50;
final int btnL   = 300;
final int btnR   = 7;
//↓ Commands
final int START = 0xF;
final int STOP  = 0x1;
final int PING  = 0xA;
final int PONG  = 0xB;
//↓ Error message timeout (in ms)
final int  ERROR_TIMEOUT = 10000;

//GLOBALS --------------------------------------------
//↓ Serial I/O
Serial      serialIn;
PrintWriter output;
//↓ Control P5 framework        (for the input text field)
ControlP5   cp5;
//↓ Button variables
int         btnX,     btnY;
color       btnColor, baseColor;
color       btnHighlight;
//↓ Current recording state
boolean     recording;
//↓ Error message variables
String      error;
int         errorTime;


//----------------------------------------------------
//-    SETUP
//----------------------------------------------------
void setup() {
  size(500, 175);
  
  //TEXT FIELD INITIALIZATION ------------------------
  PFont font = createFont("arial",20);  //Create the font for the text
  cp5 = new ControlP5(this);            //Initialize the Control P5 library
  
  //Create the text field with the Control P5 library
  cp5.addTextfield("Input")
     .setCaptionLabel("")
     .setValue("data.csv")
     .setColorBackground(btnColor)
     .setColorForeground(btnColor)
     .setPosition(30, 30)
     .setSize(width - 60, 40)
     .setFont(font)
     .setAutoClear(false);
  
  //BUTTON INITIALIZATION ----------------------------
  btnColor = color(0);
  btnHighlight = color(51);
  baseColor = color(102);
  
  btnX = width / 2 - btnL / 2;
  btnY = 95;
  
  //ERROR INITIALIZATION -----------------------------
  error     = "";
  errorTime = 0;
  
  //RECORDER INITIALIZATION --------------------------
  recording = false;
  
  //Set the background color
  background(baseColor);
}

//----------------------------------------------------
//-    DRAW
//----------------------------------------------------
void draw() {
  //Set the background color
  background(baseColor);
  
  //TEXT FIELD ---------------------------------------
  Textfield input = cp5.get(Textfield.class, "Input");
  
  if      (!recording && input.isLock()) input.unlock();
  else if (recording && !input.isLock()) input.lock();
  
  
  //BUTTON -------------------------------------------
  //Prepare the button:
  if (overBtn()) {  //If user is hovering over the button
    fill(btnHighlight);    //Fill button with highlight color
    stroke(btnHighlight);  //Button border is same color
  } else {          //Otherwise
    fill(btnColor);    //Fill button with normal color
    stroke(btnColor);  //Button border is same color
  }
  
  //Draw the button:
  rect(btnX, btnY, btnL, btnH, btnR);
  
  //Prepare the button text:
  fill(255);                  //Set the text color to white
  stroke(255);                
  textSize(16);               //Set the text size to 16
  textAlign(CENTER, CENTER);  //Set the alignment of the text when drawing
  
  //Draw the button text:
  text(recording ? "STOP RECORDING" : "START RECORDING", width / 2, 120);
  
  
  //ERROR --------------------------------------------
  //Check to make sure there is an error message to print
  if (!error.isEmpty()) {
    //Color the error string red
    fill(255,0,0);
    stroke(255,0,0);
    textSize(16);
    textAlign(CENTER, CENTER);
    
    //Print the error message
    text(error, width / 2, 160);
  }
  
  
  //READ AND WRITE ------------------------------------
  //Check to see if there is serial data coming in
  if (serialIn != null && serialIn.available() > 0) {
    //If we are recording, store it - otherwise ignore it
    if (recording) {
      String value = serialIn.readStringUntil('\n');
      if (value != null && !value.isEmpty()) {
        output.print(value);
      }
    } else serialIn.clear();
  }
}

//----------------------------------------------------
//-    BUTTON CLICK
//----------------------------------------------------
void mousePressed() {
  //Only handle a mouse event if it's a button click
  if (!overBtn()) return;
  
  //Toggle recording
  if (!recording) {  //Turn on
    //Try to prep the serial communication
    try {
      println(serialIn == null);
      if(serialIn == null) {
        serialIn = new Serial(this, Serial.list()[0], 9600);
        delay(1000);
      }
      
      //Try to connect
      if (!handshake()) throw new Exception("Arduino couldn't connect properly.");
      
      //Create output filestream
      output = createWriter(cp5.get(Textfield.class, "Input").getText());
      
      //Write the start command and set recording to true
      serialIn.write(START);
      recording = true;
      error = "";
    } catch (Exception e) {
      //Handle all exceptions similarly
      handleError(e);
    }
  } else {          //Turn off
    try {
      //Write the stop command
      serialIn.write(STOP);
      
      //Flush the rest of the output
      output.flush();
      output.close();

      //Turn the recorder off
      recording = false;
      error = "";
    } catch (Exception e) {
      handleError(e);
    }
  }
}

//----------------------------------------------------
//-    BUTTON HOVER
//----------------------------------------------------
boolean overBtn() {
  //If the mouse is in the button area (only if the window is focused)
  if    (focused
      && mouseX >= btnX && mouseX <= btnX + btnL
      && mouseY >= btnY && mouseY <= btnY + btnH) {
    //Update the error message if it has been long enough
    if (!error.isEmpty() && (millis() - errorTime) >= ERROR_TIMEOUT) error = "";
    
    //The user is hovering
    return true;
  }
  
  //The user isn't
  return false;
}

//----------------------------------------------------
//-    HANDSHAKE HANDLER
//----------------------------------------------------
boolean handshake() {
  //If serial isn't initialized, handshake will fail
  if (serialIn == null) return false;
  
  //Write PING to the Arduino
  serialIn.write(PING);
  
  //Wait for a reply
  for (int timeout = 1000; serialIn.available() <= 0 && timeout >= 0; timeout--) delay(1);
  if (serialIn.available() > 0) {
    int msg = serialIn.read();
    if (msg == PONG) return true;  //If the reply is PONG, handshake completed
  }
  
  //Otherwise failed
  return false;
}

//----------------------------------------------------
//-    ERROR HANDLER
//----------------------------------------------------
void handleError(Exception e) {
  //Print the error and set the error timer
  println(e);
  error     = (e instanceof ArrayIndexOutOfBoundsException) ? "Cannot find Arduino." : e.toString();
  errorTime = millis();
  
  //Reset everything
  recording = false;
  if (serialIn != null) serialIn.stop();
  if (output   != null) {
    output.flush();
    output.close();
  }
  serialIn = null;
  output   = null;
}