// This Processing sketch opens a GUI in which users can specify the
// conductance parameters used by the Teensy microcontroller.
//
// There are eight of them at present:
//     - shunt conductance (g_shunt, nS)
//     - maximum HCN conductance (g_hcn, nS)
//     - maximum sodium conductance (g_Na, nS)
//     - mean excitatory Ornstein-Uhlenbeck conductance (m_OU_exc, nS)
//     - diffusion constant of excitatory Ornstein-Uhlenbeck conductance (D_OU_exc, nS^2/ms)
//     - mean inhibitory Ornstein-Uhlenbeck conductance (m_OU_inh, nS)
//     - diffusion constant of inhibitory Ornstein-Uhlenbeck conductance (D_OU_inh, nS^2/ms)
//     - maximum EPSC conductance (g_epsc, nS)
//
// The numbers can be adjusted using the sliders.
//
// Pressing "connect" will connect to the microcontroller via the serial port.
// Pressing "upload" will send the numbers in the GUI to the microcontroller.
// Pressing "zero" will set all the numbers to zero and send zeros to the microcontroller.
//
// The sketch requires the ControlP5 library.
//

import controlP5.*;
import processing.serial.Serial;
import java.text.*;
import java.io.*;
import java.nio.*;

// ---
// a serial object (the port to communicate with the microcontroller)
// change port if needed in the UI
String DEFAULT_SERIAL_PORT = System.getProperty("os.name").startsWith("Windows")
  ? " COM3"                    // usual windows default
  : " /dev/cu.usbmodem101";    // usual posix default
Serial mcuPort;

// ---
// define variables for the ControlP5 object (the GUI)
ControlP5 cp5;

color textColor = color(100, 100, 100);
color inputColor = color(64, 64, 64);
color disabledColor = color(200, 200, 200);
color buttonColor = color(0, 45, 95);
color okColor = color(64, 200, 64);
color failColor = color(200, 64, 64);

Button connectButton;
Button uploadButton;
Button zeroButton;
Textfield connectTextfield;
Textfield g_epsc_textfield;

// ---
// storage vars
String[] echo = new String[8];

// initialize the variables set by the GUI
float g_shunt = 0;
float g_hcn = 0;
float g_Na = 0;
float m_OU_exc = 0;
float D_OU_exc = 0;
float m_OU_inh = 0;
float D_OU_inh = 0;


void setup() {
  int offsetX = 100;
  int offsetY = 50;

  // specify GUI window size, color, and text case
  size(450, 650);
  Label.setUpperCaseDefault(false);

  // create the ControlP5 object, add sliders, specify the font, and add buttons
  cp5 = new ControlP5(this);

  PFont pfont = createFont("Arial", 8, true);
  ControlFont font = new ControlFont(pfont, 18);
  cp5.setFont(font);

  connectTextfield = cp5.addTextfield("Serial Port", offsetX, offsetY, 200, 30)
    .setText(DEFAULT_SERIAL_PORT)
    .setColorBackground(inputColor);
  connectButton = cp5.addButton("connect");
  connectButton.setPosition(offsetX + 220, offsetY)
    .setSize(80, 30)
    .setColorBackground(buttonColor)
    .setColorForeground(textColor);

  offsetY+=75;
  cp5.addSlider("g_shunt", 0, 10, 0, offsetX, offsetY, 200, 30)
    .setColorBackground(inputColor);
  offsetY+=50;
  cp5.addSlider("g_hcn", 0, 10, 0, offsetX, offsetY, 200, 30)
    .setColorBackground(inputColor);
  offsetY+=50;
  cp5.addSlider("g_Na", 0, 200, 0, offsetX, offsetY, 200, 30)
    .setColorBackground(inputColor);
  offsetY+=50;
  cp5.addSlider("m_OU_exc", 0, 10, 0, offsetX, offsetY, 200, 30)
    .setColorBackground(inputColor);
  offsetY+=50;
  cp5.addSlider("D_OU_exc", 0, 10, 0, offsetX, offsetY, 200, 30)
    .setColorBackground(inputColor);
  offsetY+=50;
  cp5.addSlider("m_OU_inh", 0, 10, 0, offsetX, offsetY, 200, 30)
    .setColorBackground(inputColor);
  offsetY+=50;
  cp5.addSlider("D_OU_inh", 0, 10, 0, offsetX, offsetY, 200, 30)
    .setColorBackground(inputColor);
  offsetY+=50;
  g_epsc_textfield = cp5.addTextfield("g_epsc", offsetX, offsetY, 200, 30)
    .setText(" 0.00")
    .setColorBackground(inputColor);

  offsetY+=75;

  uploadButton = cp5.addButton("upload");
  uploadButton.setPosition(offsetX+25, offsetY)
    .setSize(80, 50)
    .setColorBackground(disabledColor)
    .setColorForeground(textColor)
    .setLock(true);

  zeroButton = cp5.addButton("zero");
  zeroButton.setPosition(offsetX+150, offsetY)
    .setSize(80, 50)
    .setColorBackground(disabledColor)
    .setColorForeground(textColor)
    .setLock(true);
    
}


void draw() {
  // draw a background so fonts are antialiased
  background(color(150, 150, 150));
}


// connect to desired com port
void connect() {
  println("connecting...");

  // create the serial port used to communicate with the microcontroller
  try {
    mcuPort = new Serial(this, connectTextfield.getText().trim(), 115200);
  }
  catch(Exception e) {
    println("connect to serial port failed");
    connectTextfield.setColorBackground(failColor);
    uploadButton.setColorBackground(disabledColor).setLock(true);
    zeroButton.setColorBackground(disabledColor).setLock(true);
    return;
  }
  mcuPort.clear();

  connectTextfield.setColorBackground(okColor);
  uploadButton.setColorBackground(textColor).setLock(false);
  zeroButton.setColorBackground(textColor).setLock(false);

  println("connected!");
}


boolean isConnected() {
  return mcuPort != null;
}


// Upload the numbers in the GUI to the microcontroller.
void upload() {
  if (! isConnected()) {
    return;
  }

  print("Updating ...");
  writeToMcu(g_shunt);
  writeToMcu(g_hcn);
  writeToMcu(g_Na);
  writeToMcu(m_OU_exc);
  writeToMcu(D_OU_exc);
  writeToMcu(m_OU_inh);
  writeToMcu(D_OU_inh);
  writeToMcu(Float.parseFloat(g_epsc_textfield.getText()));

  println(" response from MCU:");
  if (confirmed()) {         // conductance values shown in GUI and interpreted by Teensy are identical
    cp5.getController("upload").setColorForeground(okColor);
  } else {                   // conductance values differ: rounding artifacts or transmission errors
    cp5.getController("upload").setColorForeground(failColor);
  }
}



// Zero all the numbers in the GUI and transmit zeros to the microcontroller.
void zero() {
  if (! isConnected()) {
    return;
  }

  cp5.getController("g_shunt").setValue(0.0);
  cp5.getController("g_hcn").setValue(0.0);
  cp5.getController("g_Na").setValue(0.0);
  cp5.getController("m_OU_exc").setValue(0.0);
  cp5.getController("D_OU_exc").setValue(0.0);
  cp5.getController("m_OU_inh").setValue(0.0);
  cp5.getController("D_OU_inh").setValue(0.0);
  g_epsc_textfield.setText(" 0.00");

  upload();
}


// Compares all numbers from the GUI with the echo from the microcontroller and
// highlights individual values depending on the success of the transmission.
// In addition, the Upload button is colored depending on the update success.
boolean confirmed() {
  boolean valid = true;

  // estimated maximum delay for USB buffer transmission from Teensy to GUI
  delay(500);

  // receive values at once, but convert individually to avoid problems with GUI delay
  readFromMcu();

  if (Float.parseFloat(echo[0]) != g_shunt) {
    cp5.getController("g_shunt").setValue(Float.parseFloat(echo[0]));
    cp5.getController("g_shunt").setColorValueLabel(failColor);
    valid = false;
  } else {
    cp5.getController("g_shunt").setColorValueLabel(okColor);
  }

  if (Float.parseFloat(echo[1]) != g_hcn) {
    cp5.getController("g_hcn").setValue(Float.parseFloat(echo[1]));
    cp5.getController("g_hcn").setColorValueLabel(failColor);
    valid = false;
  } else {
    cp5.getController("g_hcn").setColorValueLabel(okColor);
  }

  if (Float.parseFloat(echo[2]) != g_Na) {
    cp5.getController("g_Na").setValue(Float.parseFloat(echo[2]));
    cp5.getController("g_Na").setColorValueLabel(failColor);
    valid = false;
  } else {
    cp5.getController("g_Na").setColorValueLabel(okColor);
  }

  if (Float.parseFloat(echo[3]) != m_OU_exc) {
    cp5.getController("m_OU_exc").setValue(Float.parseFloat(echo[3]));
    cp5.getController("m_OU_exc").setColorValueLabel(failColor);
    valid = false;
  } else {
    cp5.getController("m_OU_exc").setColorValueLabel(okColor);
  }

  if (Float.parseFloat(echo[4]) != D_OU_exc) {
    cp5.getController("D_OU_exc").setValue(Float.parseFloat(echo[4]));
    cp5.getController("D_OU_exc").setColorValueLabel(failColor);
    valid = false;
  } else {
    cp5.getController("D_OU_exc").setColorValueLabel(okColor);
  }

  if (Float.parseFloat(echo[5]) != m_OU_inh) {
    cp5.getController("m_OU_inh").setValue(Float.parseFloat(echo[5]));
    cp5.getController("m_OU_inh").setColorValueLabel(failColor);
    valid = false;
  } else {
    cp5.getController("m_OU_inh").setColorValueLabel(okColor);
  }

  if (Float.parseFloat(echo[6]) != D_OU_inh) {
    cp5.getController("D_OU_inh").setValue(Float.parseFloat(echo[6]));
    cp5.getController("D_OU_inh").setColorValueLabel(failColor);
    valid = false;
  } else {
    cp5.getController("D_OU_inh").setColorValueLabel(okColor);
  }

  if (Float.parseFloat(echo[7]) != Float.parseFloat(g_epsc_textfield.getText())) {
    g_epsc_textfield.setValue(echo[7]);
    g_epsc_textfield.setColorValueLabel(failColor);
    valid = false;
  } else {
    g_epsc_textfield.setColorValueLabel(okColor);
  }

  return valid;
}


// The numbers sent to the Teensy as unsigned bytes are echoed
// by the device as strings followed by a newline character
void readFromMcu() {
  if (! isConnected()) {
    return;
  }

  while (mcuPort.available() > 0) {
    println("reading...");
    String inBuffer = mcuPort.readString();
    if (inBuffer != null) {
      echo = split(inBuffer, "\n");
      for (String myString : echo) {  // iterate through values
        print(myString + " ");
      };
      println();
    } else {
      println("nothing?");
    }
  }
}


// The numbers from the GUI (floats) are converted to unsigned bytes
// and written to the Teensy.
void writeToMcu(float value) {
  if (! isConnected()) {
    return;
  }

  mcuPort.write(ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN).putFloat(value).array());
}


// dispose() is invoked when the applet window closes.
// It just cleans everything up.
void dispose() {
  if (! isConnected()) {
    return;
  }

  print("Stopping ...");
  mcuPort.stop();
  mcuPort = null;
  println("Done.");
}
