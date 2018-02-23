// Processing sketch for CALIBRATING the dynamic clamp system.
//
// The output of running this sketch should be four numbers: the slope and intercept describing how a measurement at the Teensy's
// analog input pin (0-4095, ADC, the x value) maps onto the membrane potential (in mV, V_m, the y value), and the slope and
// intercept describing how a current command (in pA, I, the x value) relates to an output (0-4095, DAC, the y value) sent
// to the Teensy's analog output pin. 
// 
// This sketch assumes that a model cell is attached to the amplifier headstage and that the experimenter can switch the amplifier
// between I=0 mode (current clamp with the current command disabled) and current clamp (I) mode. When in I=0 mode, the experimenter
// should be able to control the membrane potential through the amplifier's pipette offset control. 
//
// The model cell may consist of both capacitors and resistors, but the resistors in SERIES should sum to a value entered below as 
// model_cell_R (in MOhms). For example, the Axon Patch 1-U model cell (Molecular Devices) has, in cell mode, a resistor representing
// the membrane of 500 MOhms and a resistor representing the series resistance of 10 MOhms. In this case, model_cell_R = 510.
//
// The parts of the sketch include global variables, the setup function, the draw function (which does nothing but is expected in
// a Processing sketch), functions used for Vm calibration (how the Teensy converts the input it measures at its analog input pin
// into the neuron's membrane potential), functions used for I calibration (how the Teensy determines what number to send to its
// analog output pin to inject a given current into the neuron), a function that displays the results in the GUI window, 
// a function that writes the output from the Teensy to text files on the hard drive, and a function that cleans up when
// the Processing applet is clicked closed. Each function is marked in the comments accordingly.
//
// Last modified 01/21/18.




//////////////////////////////
////// GLOBAL VARIABLES //////
//////////////////////////////

// import libraries
import controlP5.*;
import processing.serial.*;
import java.text.*;
import java.io.*;
import java.nio.*;
import grafica.*;

// create GUI and serial objects
ControlP5 cp5;
Serial myPort;
Textarea myTextarea1;
Textarea myTextarea2;
GPlot plot1;
GPlot plot2;


// enter model cell total resistance (in MOhms)
float model_cell_R = 510.0;

// global variables to calibrate how AI pin input (0-4095) is interpreted as membrane potential (mV)
float[] amp_vals = new float[100];
float[] micro_vals = new float[100];
int numVals = 0;
float V_m = 0.0;
float V_m_slope = 1.0;
float V_m_intercept = 1.0;

// global variables to calibrate how the desired current injection (pA) is mapped onto AO pin output (0-4095)
final int nOutputs = 13;
float[] output_vals = new float[nOutputs];
float[] input_vals = new float[nOutputs];
float I_slope = 1.0;
float I_intercept = 1.0;





//////////////////////////////
////// /// SET UP ////////////
//////////////////////////////


// setup() is run once when the Processing sketch is first started.
// It opens the GUI window.
void setup() {

  // The window is this big.
  size(900,850);
  background(150);
  Label.setUpperCaseDefault(false);
  
  // Add controls to direct the Teensy's actions.
  cp5 = new ControlP5(this);
  cp5.addSlider("V_m",-90, 90, 0, 75, 50, 275, 30);
  PFont pfont = createFont("Arial", 8, true);
  ControlFont font = new ControlFont(pfont, 18);
  cp5.setFont(font);
  cp5.addBang("zero").setPosition(50,150).setSize(60,50).setColorForeground(color(100,100,100));
  cp5.addBang("measure").setPosition(200,150).setSize(60,50).setColorForeground(color(100,100,100));
  cp5.addBang("fit").setPosition(350,150).setSize(60,50).setColorForeground(color(100,100,100));
  cp5.addBang("current").setPosition(200,500).setSize(60,50).setColorForeground(color(100,100,100));
  myTextarea1 = cp5.addTextarea("txt1").setPosition(50,250).setSize(400,150).setLineHeight(32)
        .setColorBackground(150).setColorForeground(0)
        .scroll(1).hideScrollbar();
  myTextarea2 = cp5.addTextarea("txt2").setPosition(50,600).setSize(400,400).setLineHeight(32)
        .setColorBackground(150).setColorForeground(0)
        .scroll(1).hideScrollbar();
  display_fitted_values();

  // Establish serial communication with the Teensy.
  myPort = new Serial(this,"COM6",115200);
  myPort.bufferUntil('\n');
  myPort.clear();
  myPort.write(0);
  myPort.write(0);
  println("Ready ...");

  // A line to separate the membrane potential calibration (upper part) from the current calibration (lower part).
  stroke(255);
  line(25,425,875,425);
  
  // Set up graph in which to plot V_m vs ADC data
  plot1 = new GPlot(this, 475, 25, 400, 375);
  plot1.setXLim(0,4095);
  plot1.setYLim(-90,90);
  plot1.setTitleText("Vm vs ADC measurements");
  plot1.getXAxis().setAxisLabelText("ADC");
  plot1.getYAxis().setAxisLabelText("Vm (mV)");
  plot1.defaultDraw();
  
  // Set up graph in which to plot DAC vs I data
  plot2 = new GPlot(this, 475, 450, 400, 375);
  plot2.setXLim(-3300,3300);
  plot2.setYLim(0,4095);
  plot2.setTitleText("DAC vs I measurements");
  plot2.getXAxis().setAxisLabelText("I (pA)");
  plot2.getYAxis().setAxisLabelText("DAC");
  plot2.defaultDraw();
  
}





//////////////////////////////
/////////// DRAW /////////////
//////////////////////////////


// Processing sketches nearly always have a draw() function. Though in this case, it does nothing.
void draw(){
}





//////////////////////////////
////// Vm CALIBRATION// //////
//////////////////////////////

// Vm calibration: "zero" clears all the saved values, so that we can start fresh. 
void zero(){
    numVals = 0;
    for (int x=0; x<100; x++) {
      amp_vals[x] = 0.0;
      micro_vals[x] = 0.0;
    }
    GPointsArray myPoints1 = new GPointsArray(numVals);
    for (int ii=0; ii<=numVals; ii++) {
      myPoints1.add(micro_vals[ii],amp_vals[ii]);
    }
    plot1.setPoints(myPoints1);
    plot1.defaultDraw();  
}


// Vm calibration: Set the amplifer to I=0 mode and the membrane potential it outputs to some value V_1. 
// Use the slider at the top to set the V_m value equal to V_1 and then press measure. The amplifier
// value of Vm (amp_vals) and the microcontroller input value (micro_vals) are recorded. These will later
// be used, together with all the other amp_vals and micro_vals pairs, to extract the slope and intercept
// of the Vm calibration line.
void measure(){
  amp_vals[numVals] = V_m;
  myPort.clear();
  delay(50);
  myPort.write(1);
  delay(200);
  micro_vals[numVals] = float(myPort.readStringUntil('\n'));  
  GPointsArray myPoints1 = new GPointsArray(numVals);
  for (int ii=0; ii<=numVals; ii++) {
    myPoints1.add(micro_vals[ii],amp_vals[ii]);
  }
  plot1.setPoints(myPoints1);
  plot1.defaultDraw();  
  numVals++;
  println(micro_vals[numVals-1]);
}


// Vm calibration: Fit the stored amp_vals / micro_vals pairs to a straight line and extract the slope
// and intercept.
void fit(){
   float xbar=0;
   float ybar=0;
   float xybar=0;
   float xsqbar=0;

   if (numVals>1){
       for (int i=0; i<numVals; i++){
           xbar=xbar+micro_vals[i];
           ybar=ybar+amp_vals[i];
           xybar=xybar+micro_vals[i]*amp_vals[i];
           xsqbar=xsqbar+micro_vals[i]*micro_vals[i];
       }
      xbar=xbar/numVals;
      ybar=ybar/numVals;
      xybar=xybar/numVals;
      xsqbar=xsqbar/numVals; 
      V_m_slope = (xybar-xbar*ybar)/(xsqbar-xbar*xbar);
      V_m_intercept = ybar-V_m_slope*xbar;
      display_fitted_values();      
    }
}





//////////////////////////////
///////. I CALIBRATION ///////
//////////////////////////////

// I calibration:  Instruct the Teensy to inject a family of current steps and measure the steady-state
// values of the analog input pin. These will be used to calibrate the Teensy's output: map a desired
// current injection (in pA) to an output fed to the analog output pin (0-4095).
void current() {
    String msg, raw_data;
    float values[] = {0.0f};
    myPort.clear();
    delay(50);
    myPort.write(2); // instruction to Teensy
    delay(200);
    for (int x=0; x<10; x++) {                      // give the Teensy 10 sec to finish routine  
        msg = "Wait " + str(x) + " of 10";
        println(msg);
        delay(1000);
    }
    GPointsArray myPoints2 = new GPointsArray(nOutputs);
    try {
        for (int y=0; y<nOutputs; y++) {
            raw_data = trim(myPort.readStringUntil('\n'));
            values = float(trim(split(raw_data, ',')));
            output_vals[y] = values[0];
            input_vals[y] = values[1];
            print(str(values[0]));
            print(" , ");
            println(str(values[1]));
        }
        fit_current();
        for (int jj=0; jj<nOutputs; jj++) {
          myPoints2.add(input_vals[jj],output_vals[jj]);
        }
        plot2.setPoints(myPoints2);
        plot2.defaultDraw(); 
    } catch (Exception e) {
      println("Keep working ...");
    }         
}



// I calibration:   Fit a straight line to the pairs measured by current() and use these to calculate the
// slope and intercept relating the desired current injection (in pA) to the output fed to the Teensy's
// analog output pin (0-4095). This function makes use of the slope/intercept for Vm calibration -- determined
// by the function fit() -- and the model cell's total resistance (model_cell_R). 
void fit_current() {
   float xbar=0;
   float ybar=0;
   float xybar=0;
   float xsqbar=0;

   for (int i=0; i<nOutputs; i++){
       xbar=xbar+input_vals[i];
       ybar=ybar+output_vals[i];
       xybar=xybar+input_vals[i]*output_vals[i];
       xsqbar=xsqbar+input_vals[i]*input_vals[i];
   }
   xbar=xbar/nOutputs;
   ybar=ybar/nOutputs;
   xybar=xybar/nOutputs;
   xsqbar=xsqbar/nOutputs; 
   float slope = (xybar-xbar*ybar)/(xsqbar-xbar*xbar);
   float intercept = ybar-slope*xbar; 
   if (V_m_slope>0) {   
     I_slope = (slope * model_cell_R/1000)/V_m_slope;
     I_intercept = intercept - (slope/V_m_slope)*V_m_intercept;
     display_fitted_values();
   }     
}





//////////////////////////////
////// DISPLAY RESULTS ///////
//////////////////////////////

// Display the fitted values (Vm calibration and I calibration) in the GUI window.
void display_fitted_values() {
   String s1 = "Vm slope is " + str(V_m_slope) + "\n";
   s1 += "Vm intercept is " + str(V_m_intercept) + "\n";
   s1 += "REMEMBER TO DIVIDE OUT gain_INPUT" + "\n";
   myTextarea1.setText(s1);
   String s2 = "I slope is " + str(I_slope) + "\n";
   s2 += "I intercept is " + str(I_intercept) + "\n";
   s2 += "REMEMBER TO DIVIDE OUT gain_OUTPUT" + "\n";
   myTextarea2.setText(s2);
   save_data();
}





///////////////////////////////
////////// SAVE DATA //////////
///////////////////////////////
void save_data() {
   String file_name_Vm = sketchPath("");
   String file_name_I = sketchPath("");
   DateFormat formatter = new SimpleDateFormat("yyyy_MM_dd_hh_mm_ss");
   long now = System.currentTimeMillis();
   String data;
   
   println(now);
   file_name_Vm += "Vm_" + formatter.format(now) + ".txt";
   for (int x=0; x<numVals; x++) {
     data = str(amp_vals[x]) + " , " + str(micro_vals[x]);
     save_to_file(file_name_Vm,data,true);
   }
   file_name_I += "I_" + formatter.format(now) + ".txt";
   float model_cell_I = 0.0;
   for (int y=0; y<nOutputs; y++) {
     model_cell_I = (input_vals[y]*V_m_slope + V_m_intercept)/(model_cell_R/1000);   // convert input_vals into current (pA) using V_m_slope, V_m_intercept, and model_cell_R
     data = str(output_vals[y]) + " , " + str(model_cell_I);
     save_to_file(file_name_I,data,true);
   }
}





//////////////////////////////////
////////// SAVE TO FILE //////////
////////////////////////////./////
void save_to_file(String fileName, String newData, boolean appendData){
    BufferedWriter bw = null;
    try {  
      FileWriter fw = new FileWriter(fileName, appendData);
      bw = new BufferedWriter(fw);
      bw.write(newData + System.getProperty("line.separator"));
    } catch (IOException e) {
    } finally {
      if (bw != null){
        try { 
          bw.close(); 
        } catch (IOException e) {}  
      }
    }
}
    





//////////////////////////////
////////// CLEAN UP //////////
//////////////////////////////

// Clean up when the window is clicked closed.
void dispose() {
    myPort.clear();
    myPort.stop();
    println("Stopping ...");
}  
