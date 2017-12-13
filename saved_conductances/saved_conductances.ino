// Dynamic clamp sketch for an EPSC train where each EPSC is calculated as a difference of exponentials.
//
// The rise time, decay time, inter-event interval, number of events, and scaling factor can be varied below. They are global variables.
// The calculation of the EPSCs is made in the tabbed file EPSC.ino. Each train is triggered by a TTL pulse to epscTriggerPin.
//
// The gain, slope, and intercept values are the same as for the main dynamic clamp sketch, as these are properties of the amplifier
// and the breadboard, not the conductance simulation.
// 
// The update rate is fixed at 20 kHz. A 1-second-long train uses up 32% of RAM.
//
// Last updated 12/12/17.

#include <ADC.h>
#include <math.h>


// EPSC train parameters
// Each individual EPSC equals gEPSC*(exp(-t/epscDecay)-exp(-t/epscRise)), where is time. A total of number of epscNum EPSCs is
// injected with a spacing of epscInterval. 
const float gEPSC = 1;                  // nS, EPSC scaling factor
const float epscInterval = 20;          // msec, interval between EPSCs
const float epscNum = 5;                // number of EPSCs
const float epscRise = 1;               // msec, EPSC rise time
const float epscDecay = 10;             // msec, EPSC decay time


// Scaling for the patch clamp amplifier
const float gain_INPUT = 50.0;                    // number of millivolts sent out by amplifier for each millivolt of membrane potential
                                                  // e.g., with a scaling of 50, if the membrane potential is -65 mV, the amplifier outputs -3.25 V
const float gain_OUTPUT = 400.0;                  // number of picoamps injected for every volt at the amplifier's command input
                                                  // e.g., if the DAC or the Teensy outputs -0.5 V, this is interpreted as -200 pA by the amplifier
                                                  // when the scaling is 400


// Calibrating the input/output numbers given the resistor values and power supply values of the breadboard
// n.b., these parameters (numerators) are properties of the components on the breadboard;
// they are independent of the amplifier and DAQ board
const float inputSlope = 5.5010 / gain_INPUT;
const float inputIntercept = -10922.73 / gain_INPUT;
const float outputSlope = 753 / gain_OUTPUT;
const float outputIntercept = 2386;


// Common global variables
const int freq = 20000;                 // Hz, update rate. If you increase the update rate, you should decrease the number of averages -- this is set
                                        // by the variable averagingNum in the function setup(). For example, an update rate of 50 kHz probably limits
                                        // the number of averages to 8. Also keep track of how much memory is being used: a duration of 1 second at
                                        // 20 kHz uses 32% of RAM; increasing the rate to 50 kHz should probably be accompanied by a decrease in
                                        // duration.
const int duration = 1000;              // msec, total duration of train
int dt = int(1E6 / freq);               // usec, time step


// Hardware connections
const int analogInPin = A0;             // ADC pin used to read membrane potential
const int analogOutPin = A21;           // DAC pin used to output current
const int epscTriggerPin = 2;           // pin used to trigger EPSC train




void setup() {
  Serial.begin(115200);
  analogWriteResolution(12);
  analogReadResolution(12);
  int averagingNum = 16;
  CreateEpscTrain();                            // creates the EPSC train that will be read out every time a trigger is received
  analogReadAveraging(averagingNum);
  while (Serial.available() > 0) {              // make sure serial buffer is clear
    char foo = Serial.read();
  }
  delay(500);
}




elapsedMicros usec;
elapsedMicros t0;
void loop() {
  t0 = 0;
  float v = inputSlope * analogRead(analogInPin) + inputIntercept;        // mV, given amplifier settings
  float injectionCurrent = 0.0;
  if ((digitalReadFast(epscTriggerPin)==HIGH)&&(usec>=2000)) {            // poll epscTriggerPin to see if a trigger has arrived
    usec = 0;
  }
  if (usec < (1000*duration)) {
    injectionCurrent = EPSC(v, usec);
  }
  injectionCurrent = outputSlope * injectionCurrent + outputIntercept;    // pA converted into analog output integers
  int outputSignal = constrain((int)injectionCurrent, 0, 4095);           // make sure the output is an integer between 0 and 4095 (12 bits)
  analogWrite(analogOutPin, outputSignal);                                // send the output to the patch clamp or summing amplifier
  while (t0 < dt) {};
}


