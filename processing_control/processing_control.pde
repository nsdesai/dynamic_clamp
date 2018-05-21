// This Processing sketch opens a GUI in which users can specify the
// conductance parameters used by the Teensy microcontroller. There are eight of 
// them at present: shunt conductance (g_shunt, nS), maximum HCN conductance (g_hcn, nS),
// maximum sodium conductance (g_Na, nS), mean excitatory Ornstein-Uhlenbeck
// conductance (m_OU_exc, nS), diffusion constant of excitatory Ornstein-Uhlenbeck
// conductance (D_OU_exc, nS^2/ms), mean inhibitory Ornstein-Uhlenbeck conductance
// (m_OU_inh, nS), diffusion constant of inhibitory Ornstein-Uhlenbeck conductance
// (D_OU_inh, nS^2/ms), and maximum EPSC conductance (g_epsc, nS).
//
// The numbers can be adjusted using the sliders.
//
// Pressing "upload" will send the numbers in the GUI to the microcontroller.
// Pressing "zero" will set all the numbers to zero and send zeros to the microcontroller.
//
// The sketch requires the ControlP5 library.
//
// Last updated 05/20/2018, 7:00 pm - ND, CR


// import libraries
import controlP5.*;
import processing.serial.*;
import java.text.*;
import java.io.*;
import java.nio.*;

// define variables for the ControlP5 object (the GUI) and 
// a serial object (the port to communicate with the microcontroller)
ControlP5 dcControl;
Serial myPort;
String[] echo = {};

// initialize the variables set by the GUI
float g_shunt = 0;
float g_hcn = 0;
float g_Na = 0;
float m_OU_exc = 0;
float D_OU_exc = 0;
float m_OU_inh = 0;
float D_OU_inh = 0;
Textfield g_epsc_textfield;


void setup() {
  
    // specify GUI window size, color, and text case
    size(450,600);
    background(150);
    Label.setUpperCaseDefault(false);
    
    // create the ControlP5 object, add sliders, specify the font, and add buttons
    dcControl = new ControlP5(this);
    dcControl.addSlider("g_shunt", 0, 10, 0, 100, 50, 200, 30);
    dcControl.addSlider("g_hcn", 0, 10, 0, 100, 100, 200, 30);
    dcControl.addSlider("g_Na", 0, 200, 0, 100, 150, 200, 30);
    dcControl.addSlider("m_OU_exc", 0, 10, 0, 100, 200, 200, 30);
    dcControl.addSlider("D_OU_exc", 0, 10, 0, 100, 250, 200, 30);
    dcControl.addSlider("m_OU_inh", 0, 10, 0, 100, 300, 200, 30);
    dcControl.addSlider("D_OU_inh", 0, 10, 0, 100, 350, 200, 30);
    g_epsc_textfield = dcControl.addTextfield("g_epsc", 100, 400, 200, 30).setText(" 0.00").setColorBackground(color(64,64,64));
    PFont pfont = createFont("Arial", 8, true);
    ControlFont font = new ControlFont(pfont, 18);
    dcControl.setFont(font);
    dcControl.addBang("upload").setPosition(125,500).setSize(60,50).setColorForeground(color(100,100,100));
    dcControl.addBang("zero").setPosition(250,500).setSize(60,50).setColorForeground(color(100,100,100));
    
    // create the serial port used to communicate with the microcontroller
    myPort = new Serial(this,"COM13",115200);
    myPort.clear();
    
}



void draw(){
  // nothing to see here: the Processing language requires every sketch to contain a draw() function
}


// Upload the numbers in the GUI to the microcontroller.
void upload(){
      print("Updating ...");
      writetoteensy(g_shunt);
      writetoteensy(g_hcn);
      writetoteensy(g_Na);
      writetoteensy(m_OU_exc);
      writetoteensy(D_OU_exc);
      writetoteensy(m_OU_inh);
      writetoteensy(D_OU_inh);
      writetoteensy(float(g_epsc_textfield.getText()));
      println(" response from Teensy:");
      if (confirmed()) {         // conductance values shown in GUI and interpreted by Teensy are identical
        dcControl.getController("upload").setColorForeground(color(0,255,0));
      } else {                   // conductance values differ: rounding artifacts or transmission errors
        dcControl.getController("upload").setColorForeground(color(255,0,0));
      }
}



// Zero all the numbers in the GUI and transmit zeros to the microcontroller.
void zero(){
    dcControl.getController("g_shunt").setValue(0.0);
    dcControl.getController("g_hcn").setValue(0.0);
    dcControl.getController("g_Na").setValue(0.0);
    dcControl.getController("m_OU_exc").setValue(0.0);
    dcControl.getController("D_OU_exc").setValue(0.0);
    dcControl.getController("m_OU_inh").setValue(0.0);
    dcControl.getController("D_OU_inh").setValue(0.0);
    g_epsc_textfield.setText(" 0.00");
    upload();
}


// Compares all numbers from the GUI with the echo from the microcontroller and
// highlights individual values depending on the success of the transmission.
// In addition, the Upload button is colored depending on the update success.
boolean confirmed(){
  boolean valid = true;
  delay(500);                // estimated maximum delay for USB buffer transmission from Teensy to GUI
  readfromteensy();          // receive values at once, but convert individually to avoid problems with GUI delay
  if (float(echo[0]) != g_shunt) {
    dcControl.getController("g_shunt").setValue(float(echo[0]));
    dcControl.getController("g_shunt").setColorValueLabel(color(255,0,0));
    valid = false;
  } else {
    dcControl.getController("g_shunt").setColorValueLabel(color(0,255,0));
  }
  if (float(echo[1]) != g_hcn) {
    dcControl.getController("g_hcn").setValue(float(echo[1]));
    dcControl.getController("g_hcn").setColorValueLabel(color(255,0,0));
    valid = false;
  } else {
    dcControl.getController("g_hcn").setColorValueLabel(color(0,255,0));
  }
  if (float(echo[2]) != g_Na) {
    dcControl.getController("g_Na").setValue(float(echo[2]));
    dcControl.getController("g_Na").setColorValueLabel(color(255,0,0));
    valid = false;
  } else {
    dcControl.getController("g_Na").setColorValueLabel(color(0,255,0));
  }
  if (float(echo[3]) != m_OU_exc) {
    dcControl.getController("m_OU_exc").setValue(float(echo[3]));
    dcControl.getController("m_OU_exc").setColorValueLabel(color(255,0,0));
    valid = false;
  } else {
    dcControl.getController("m_OU_exc").setColorValueLabel(color(0,255,0));
  }
  if (float(echo[4]) != D_OU_exc) {
    dcControl.getController("D_OU_exc").setValue(float(echo[4]));
    dcControl.getController("D_OU_exc").setColorValueLabel(color(255,0,0));
    valid = false;
  } else {
    dcControl.getController("D_OU_exc").setColorValueLabel(color(0,255,0));
  }
  if (float(echo[5]) != m_OU_inh) {
    dcControl.getController("m_OU_inh").setValue(float(echo[5]));
    dcControl.getController("m_OU_inh").setColorValueLabel(color(255,0,0));
    valid = false;
  } else {
    dcControl.getController("m_OU_inh").setColorValueLabel(color(0,255,0));
  }
  if (float(echo[6]) != D_OU_inh) {
    dcControl.getController("D_OU_inh").setValue(float(echo[6]));
    dcControl.getController("D_OU_inh").setColorValueLabel(color(255,0,0));
    valid = false;
  } else {
    dcControl.getController("D_OU_inh").setColorValueLabel(color(0,255,0));
  }
   if (float(echo[7]) != float(g_epsc_textfield.getText())) {
     g_epsc_textfield.setValue(echo[7]);
     g_epsc_textfield.setColorValueLabel(color(255,0,0));
    valid = false;
  } else {
    g_epsc_textfield.setColorValueLabel(color(0,255,0));
  }
  return valid;
}


// The numbers sent to the Teensy as unsigned bytes are echoed
// by the device as strings followed by a newline character
void readfromteensy() {
  while (myPort.available() > 0) {
    String inBuffer = myPort.readString();
    if (inBuffer != null) {
      echo = split(inBuffer, "\n");
      for (String myString : echo) {  // iterate through values
        print(myString + " ");
      };
      println();
    }
  }
}


// The numbers from the GUI (floats) are converted to unsigned bytes
// and written to the Teensy.
void writetoteensy(float foo) {
    byte[] b;
    ByteBuffer byteBuffer = ByteBuffer.allocate(4);
    byteBuffer.order(ByteOrder.LITTLE_ENDIAN);
    b = byteBuffer.putFloat(foo).array();
    for (int y=0; y<4; y++) {    // This is probably not necessary
      int boo = (b[y]&0xFF);     // since negative bytes get converted
      myPort.write(boo);         // when written
    }
}


// dispose() is invoked when the applet window closes.
// It just cleans everything up.
void dispose() {
    print("Stopping ...");
    myPort.clear();
    myPort.stop();
    println(" done.");
}  
