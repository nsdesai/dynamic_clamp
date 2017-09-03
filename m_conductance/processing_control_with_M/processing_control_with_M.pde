// This Processing sketch opens a GUI in which users can specify the
// conductance parameters used by the Teensy microcontroller. There are eight of 
// them at present: shunt conductance (g_shunt, nS), maximum HCN conductance (g_hcn, nS),
// maximum sodium conductance (g_Na, nS), mean excitatory Ornstein-Uhlenbeck
// conductance (m_OU_exc, nS), diffusion constant of excitatory Ornstein-Uhlenbeck
// conductance (D_OU_exc, nS^2/ms), mean inhibitory Ornstein-Uhlenbeck conductance
// (m_OU_inh, nS), diffusion constant of inhibitory Ornstein-Uhlenbeck conductance
// (D_OU_inh, nS^2/ms), maximum EPSC conductance (g_epsc, nS), and maximum M
// conductance (g_M, nS).
//
// The numbers can be adjusted using the sliders.
//
// Pressing "upload" will send the numbers in the GUI to the microcontroller.
// Pressing "zero" will set all the numbers to zero and send zeros to the microcontroller.
//
// The sketch requires the ControlP5 library.
//
// PROCESSING CONTROL WITH M


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

// initialize the variables set by the GUI
float g_shunt = 0;
float g_hcn = 0;
float g_Na = 0;
float m_OU_exc = 0;
float D_OU_exc = 0;
float m_OU_inh = 0;
float D_OU_inh = 0;
float g_epsc = 0;
float g_M = 0;


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
    dcControl.addSlider("g_epsc", 0, 10, 0, 100, 400, 200, 30);
    dcControl.addSlider("g_M", 0, 10, 0, 100, 450, 200, 30);
    PFont pfont = createFont("Arial", 8, true);
    ControlFont font = new ControlFont(pfont, 18);
    dcControl.setFont(font);
    dcControl.addBang("upload").setPosition(125,500).setSize(60,50).setColorForeground(color(100,100,100));
    dcControl.addBang("zero").setPosition(250,500).setSize(60,50).setColorForeground(color(100,100,100));
    
    // create the serial port used to communicate with the microcontroller
    myPort = new Serial(this,"COM7",115200);
    myPort.clear();
    
}



void draw(){
  // nothing to see here: the Processing language requires every sketch to contain a draw() function
}


// Upload the numbers in the GUI to the microcontroller.
void upload(){
      writetoteensy(g_shunt);
      writetoteensy(g_hcn);
      writetoteensy(g_Na);
      writetoteensy(m_OU_exc);
      writetoteensy(D_OU_exc);
      writetoteensy(m_OU_inh);
      writetoteensy(D_OU_inh);
      writetoteensy(g_epsc);
      writetoteensy(g_M);
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
    dcControl.getController("g_epsc").setValue(0.0);
    dcControl.getController("g_M").setValue(0.0);
    upload();
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
    myPort.clear();
    myPort.stop();
    println("Stopping ...");
}  
