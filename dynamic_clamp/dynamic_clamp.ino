// teensy 3.6 sketch to implement dynamic clamp
//
// The sketch includes a main file (this one) and other files (which appear as tabs) that define the conductances.
// The main file is organized like this:
//      (i)   global variables are declared first. gain_INPUT and gain_OUTPUT are properties of the patch
//            clamp amplifier (a user should specify these for their own amplifier). The calibration parameters
//            are properties of the components on the breadboard (and are usually set by the calibration sketch).
//            The dynamic clamp parameters will be specified by the Processing GUI or by some other program (Matlab,
//            Igor Pro, Python, etc.) the user chooses. dt and t0 are used to keep time. Hardware connections
//            are chosen by the user.
//      (ii)  setup(). Every Arduino-like sketch includes a setup() function which is run when the sketch is 
//            uploaded to the microcontroller. Serial communication is established with the host computer (for use
//            by Processing, Matlab, Igor Pro, Python, or whatever). 12-bit resolution is specified for analog
//            read and write. Any numbers that should be pre-calculated and stored in global variables (e.g.,
//            the lookup table numbers for sodium activation/inactivation) are calculated by calling the function
//            (in one of the tabbed files) that defines them. The trigger pin for EPSCs is established.
//      (iii) loop(). The loop() function is run continuously (i.e., once per time step). The first part checks
//            whether the microcontroller has received any serial communication instructing it to change the
//            dynamic clamp parameters (e.g., shunt conductance or OU excitatory diffusion constant). The second 
//            part reads the signal from the patch clamp amplifier's output (which has already been buffered,
//            shifted, and scaled by the breadboard electronics), converts this signal into membrane potential v
//            in millivolts (using the calibration parameters), and sends v out to the functions (in the tabbed files)
//            that calculate the dynamic clamp current in picoamps for the various conductances. All of these currents
//            are summed. The third and last part converts the summed current (in picoamps) into the output to 
//            be sent (0-4095) from the analog output pin. This output will be shifted, scaled, and added to the 
//            DAQ board's current clamp command by breadboard electronics. The total signal will then be fed to 
//            the patch clamp amplifier's command input. 
// Each dynamic clamp conductance is defined by one of the tabbed files. These files can contain multiple functions
//            and their own global variables (accessible to the functions of the tabbed file). For example, the file Sodium
//            contains declarations for the activation/inactivation lookup variables, a function that calculates the activation
//            and inactivation numbers for a range of membrane potentials and stores them in the lookup table variables,
//            and the function called at every time step to calculate the sodium current to be injected. 
//
// Last revised 05/20/2018, 7:00 pm - ND, CR


#include <math.h>

// Scaling for the patch clamp amplifier
const float gain_INPUT = 100.0;                   // number of millivolts sent out by amplifier for each millivolt of membrane potential
                                                  // e.g., with a scaling of 50, if the membrane potential is -65 mV, the amplifier outputs -3.25 V
const float gain_OUTPUT = 400.0;                  // number of picoamps injected for every volt at the amplifier's command input
                                                  // e.g., if the DAC or the Teensy outputs -0.5 V, this is interpreted as -200 pA by the amplifier
                                                  // when the scaling is 400


// Calibrating the input/output numbers given the resistor values and power supply values of the breadboard
// n.b., these parameters (numerators) are properties of the components on the breadboard;
// they are independent of the amplifier and DAQ board
const float inputSlope = 5.0375/gain_INPUT;      
const float inputIntercept = -10312.50/gain_INPUT;    
const float outputSlope = 753/gain_OUTPUT;       
const float outputIntercept = 2386;

// Conductance parameters are sent by the host computer over the USB port
const int nPars = 8;              // number of adjustable parameters
float gShunt = 0.0;               // nS, shunting conductance
float gH = 0.0;                   // nS, maximal H (HCN) conductance
float gNa = 0.0;                  // nS, maximal fast, transient sodium conductance
float OU1_mean = 0.0;             // nS, excitatory Ornstein-Uhlenbeck (OU) mean conductance
float OU1_D = 0.0;                // nS^2/msec, excitatory OU diffusion constant
float OU2_mean = 0.0;             // nS, inhibitory OU mean conductance
float OU2_D = 0.0;                // nS^2/msec, inhibitory OU diffusion constant
float gEPSC = 0.0;                // nS, maximal conductance of EPSCs

// Common global variables
float dt = 0.01;                  // msec, the time step -- on a Teensy/Arduino dt will be variable
elapsedMicros t0;                 // microsec, t0 is used to calculate dt on every iteration
elapsedMillis epscTime;           // msec, time since last EPSC was triggered

// Timing parameters for serial port communication
const int pollInterval = 100;     // msec, polling interval for serial port communication
elapsedMillis p0 = 0;             // msec, time since last polling interval ended

// Hardware connections
const int analogInPin = 0;        // ADC pin used to read membrane potential
const int analogOutPin = A21;     // DAC pin used to output current
const int epscTriggerPin = 2;     // pin used to trigger EPSC train 




void setup() {      
  Serial.begin(115200);
  analogWriteResolution(12);
  analogReadResolution(12);
  while (Serial.available()>0) {                // make sure serial buffer is clear  
    char foo = Serial.read();
  }
  GenerateGaussianNumbers();                    // generate a pool of Gaussian numbers for use by the OU processes  
  GenerateSodiumLUT();                          // generate sodium activation/inactivation lookup table
  GenerateHcnLUT();                             // generate HCN activation lookup table
  pinMode(epscTriggerPin,INPUT);                // define the pin that receives a trigger when an EPSC should be injected
}




void loop() {

  // Part 1:    Serial Communication & Parameter Setting
  // The host computer tells the Teensy when the dynamic clamp parameters should change.
  // To do this, it sends 4-byte-long numbers, one for each parameter. So if there are 
  // 8 adjustable parameters, it will send 32 bytes. At present, the adjustable parameters
  // are the shunt conductance (nS), maximal HCN conductance (nS), maximal Na conductance (nS),
  // excitatory OU conductance (OU1) mean (nS), excitatory OU conductance diffusion constant (nS^2/ms),
  // inhibitory OU conductance (OU2) mean (nS), inhibitory OU conductance (OU2) diffusion
  // constant (nS^2/ms), and maximal EPSC conductance (nS).
  if (p0 > pollInterval) {                                            // check for conductance updates frequently
    union {
      byte asByte[4];
      float asFloat;
    } data1;
    static float dataTemp[nPars] = {0.0};
    static byte parNo = 0;
    if (Serial.available()>3) {
      for (int x=0; x<4; x++) data1.asByte[x] = Serial.read();
      dataTemp[parNo] = data1.asFloat;
      parNo++;
      if (parNo==nPars) {
        gShunt = dataTemp[0];
        gH = dataTemp[1];
        gNa = dataTemp[2];
        OU1_mean = dataTemp[3];
        OU1_D = dataTemp[4];
        OU2_mean = dataTemp[5];
        OU2_D = dataTemp[6];
        gEPSC = dataTemp[7];
        parNo = 0;
        for (int n=0; n<nPars; n++) Serial.println(dataTemp[n]);      // (prepare) data echo to sender
        Serial.send_now();                                            // schedule immediate transmission
      }
    }
    p0 = 0;
  }



  // Part 2:    Read membrane potential & calculate dynamic clamp currents 
  float v = inputSlope * analogRead(analogInPin) + inputIntercept;    // mV, given amplifier settings 
  float injectionCurrent = 0.0;                                       // pA
  dt = 0.001*(float)t0;                                               // msec, time step
  t0 = 0;                                                             // set elapsed time back to zero
  
  if (gShunt>0) {
    injectionCurrent += Shunting(v);
  }
  
  injectionCurrent += HCN(v, gH);                                     // allows for the reset of a current after its initial run
  
  if (gNa>0) {
    injectionCurrent += Sodium(v);
  }  
  if (OU1_mean>0 || OU2_mean>0) {
    injectionCurrent += OrnsteinUhlenbeck(v);
  }
  if (gEPSC>0) {
    if ((digitalReadFast(epscTriggerPin)==HIGH)&&(epscTime>2)) {      // poll epscTriggerPin to see if a trigger has arrived
      UpdateEpscTrain();
      epscTime = 0;
    }
    injectionCurrent += EPSC(v);
  }

 
  
  // Part 3:      Send out the calculated dynamic clamp current
  injectionCurrent = outputSlope * injectionCurrent + outputIntercept;  // pA converted into analog output integers
  int outputSignal = constrain((int)injectionCurrent,0,4095);           // make sure the output is an integer between 0 and 4095 (12 bits)
  analogWrite(analogOutPin,outputSignal);                               // send the output to the patch clamp or summing amplifier

}

