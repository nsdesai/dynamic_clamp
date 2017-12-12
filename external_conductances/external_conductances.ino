// Dynamic clamp sketch when using externally-generated conductances.
//
// This sketch monitors four of the Teensy microcontroller's analog inputs. One of these reads the membrane potential (Vm); the other
// three can be used to read conductance signals sent out by the DAQ board (or by some other source). The Teensy will multiply
// each conductance by its associated driving force (difference between Vm and the conductance's reversal potential, Erev) to
// get the current through that conductance. It will then sum all the currents and send the sum through the DAC output.
// 
// The typical use case would be feeding excitatory and inhibitory conductance trains into a neuron to simulate "in vivo-like"
// conditions. The trains may, for example, have been derived from voltage clamp recordings or from a network simulation.
// 
// Before uploading this sketch, users should change the parameters at the top.
// (A) The input/output gains, slopes, and intercepts should be the same as for the original dynamic clamp sketch. The gains
//     are set by the patch clamp amplifier. The slopes and intercepts should be set using the protocol described in www.dynamicclamp.com
//     (see "Calibration"). 
// (B) sampleFrequency should be set to 10000, 20000, 25000, 40000, 50000, or 100000 Hz.
// (C) channelsInUse should be set, as should the associated reversal potentials and the scaling factors. The scaling factor (nS/V) for
//     a given analog input indicates how a voltage (0-3.3 V) received at that input should be converted into a
//     conductance (in nS).  
//
// This sketch makes use of Pedro Villaneuva's ADC library for the Teensy (https://github.com/pedvide/ADC) and a sketch for 
// sampling four ADC channels simultaneously contributed by PJRC.com forum senior member "tni" (whose real name
// I do not know). The latter sketch can be found at
// https://forum.pjrc.com/threads/45206-Pedvide-s-ADC-library-multiple-channel-simultaneous-amp-continuous-acquisition?p=147644&viewfull=1#post147644
// And, of course, no part of this project would be possible without Paul Stoffregen's introduction of and work on the Teensy.
//
// Last updated December 11, 2017 (NSD)


#include <ADC.h>
#include <array>


// Scaling for the patch clamp amplifier
const float gain_INPUT = 50.0;                    // number of millivolts sent out by amplifier for each millivolt of membrane potential
                                                  // e.g., with a scaling of 50, if the membrane potential is -65 mV, the amplifier outputs -3.25 V
const float gain_OUTPUT = 400.0;                  // number of picoamps injected for every volt at the amplifier's command input
                                                  // e.g., if the DAC or the Teensy outputs -0.5 V, this is interpreted as -200 pA by the amplifier
                                                  // when the scaling is 400


// Calibrating the input/output numbers given the resistor values and power supply values of the breadboard
// n.b., these parameters (numerators) are properties of the components on the breadboard;
// they are independent of the amplifier and DAQ board
const float inputSlope = 5.4084/gain_INPUT;      
const float inputIntercept = -11061.9349/gain_INPUT;    
const float outputSlope = 753/gain_OUTPUT;       
const float outputIntercept = 2386;


const int sampleFrequency = 100000;   // Hz (choose one: 10000, 20000, 25000, 40000, 50000, or 100000)
const bool  channelsInUse[3] = {true,true,false};   // the default, [true,true,false], means two conductance trains (e.g., excitation and inhibition) 
const float reversalPotentials[3] = {0.0,-80.0, 0.0};   // reversal potentials for channels (e.g., 0 mV for excitation, -80 mV for inhibition)
const float scalingFactors[3] = {10.0, 10.0, 1.0};    // scaling factors (nS/V)


// We adjust the time step (dt) and the number of averages the analog inputs take before reporting a measurement (nAverages) based on
// the desired sampleFrequency.
int dt = int(1E6/sampleFrequency);
int nAverages = int(100000/sampleFrequency);


// pin assignments: Teensy 3.6 has two hardware ADC channels (ADC0 and ADC1); these are multiplexed to give 25 total analog inputs.
// We use one (A0) to read Vm. The others (A1, A12, A13) can read conductance trains; these are the first, second, and third elements of
// channelsInUse, reversalPotentials, and scalingFactors as defined above.
const uint8_t adc0_pin0 = A0;     // ADC0
const uint8_t adc0_pin1 = A1;     // ADC0
const uint8_t adc1_pin0 = A12;    // ADC1
const uint8_t adc1_pin1 = A13;    // ADC1
const int dac_pin0 = A21;         // DAC0


float prefactors[3];   // will be used in loop() to scale currents correctly


constexpr std::array<uint8_t, 4> adc_pins = { adc0_pin0, adc0_pin1, adc1_pin0, adc1_pin1 };

ADC adc;
std::array<ADC_Module*, 2> adc_modules;
static_assert(ADC_NUM_ADCS == 2, "Two ADCs expected.");


struct Measurement {
    std::array<volatile uint16_t, 4> v;
};

std::array<Measurement, 100> buffer;
volatile size_t write_pos = 0;

// CMSIS PDB
#define PDB_C1_EN_MASK                           0xFFu
#define PDB_C1_EN_SHIFT                          0
#define PDB_C1_EN(x)                             (((uint32_t)(((uint32_t)(x))<<PDB_C1_EN_SHIFT))&PDB_C1_EN_MASK)
#define PDB_C1_TOS_MASK                          0xFF00u
#define PDB_C1_TOS_SHIFT                         8
#define PDB_C1_TOS(x)                            (((uint32_t)(((uint32_t)(x))<<PDB_C1_TOS_SHIFT))&PDB_C1_TOS_MASK)
#define PDB_C1_BB_MASK                           0xFF0000u
#define PDB_C1_BB_SHIFT                          16
#define PDB_C1_BB(x)                             (((uint32_t)(((uint32_t)(x))<<PDB_C1_BB_SHIFT))&PDB_C1_BB_MASK)


void setup() {

    pinMode(dac_pin0, OUTPUT);
    analogWriteResolution(12);
    for (int xx=0; xx<3; xx++) prefactors[xx]=scalingFactors[xx]*3.3/4095;  // 4095 if 12 bit
  
    for(size_t i = 0; i < adc_modules.size(); i++) adc_modules[i] = adc.adc[i];
    for(auto pin : adc_pins) pinMode(pin, INPUT);

    Serial.begin(115200);
    delay(2000);
    Serial.println("Starting");

    for(auto adc_module : adc_modules) {
        adc_module->setAveraging(nAverages);
        adc_module->setResolution(12);
        adc_module->setConversionSpeed(ADC_CONVERSION_SPEED::HIGH_SPEED);
        adc_module->setSamplingSpeed(ADC_SAMPLING_SPEED::HIGH_SPEED);
    }
    
    // perform ADC input mux setup; the ADC library doesn't handle the B-set of registers
    // so we copy the config over
    adc.adc0->analogRead(adc0_pin1);
    ADC0_SC1B = ADC0_SC1A;
    adc.adc0->analogRead(adc0_pin0);

    adc.adc1->analogRead(adc1_pin1);
    ADC1_SC1B = ADC1_SC1A;
    adc.adc1->analogRead(adc1_pin0);

    if(adc.adc0->fail_flag || adc.adc1->fail_flag) {
        Serial.printf("ADC error, ADC0: %x ADC1: %x\n", adc.adc0->fail_flag, adc.adc1->fail_flag);
    }

    for(auto adc_module : adc_modules) adc_module->stopPDB();
    // conversion will be triggered by PDB
    for(auto adc_module : adc_modules) adc_module->setHardwareTrigger();

    // enable PDB clock
    SIM_SCGC6 |= SIM_SCGC6_PDB;
    
    // Sample at the sampleFrequency declared near the top of this sketch.
    constexpr uint32_t pdb_trigger_frequency = sampleFrequency;
    constexpr uint32_t mod = (F_BUS / pdb_trigger_frequency);
    static_assert(mod <= 0x10000, "Prescaler required.");
    PDB0_MOD = (uint16_t)(mod-1);

    uint32_t pdb_ch_config = PDB_C1_EN (0b11) | // enable ADC A and B channel
                             PDB_C1_TOS(0b11) | // this enables the channel delay, which we don't really want, 
                                                // but the PDB appears to have a hardware bug and this 
                                                // needs to be set
                             PDB_C1_BB (0b10);  // back-to-back trigger; B triggered by A conversion complete
    PDB0_CH0C1 = pdb_ch_config; // ADC 0
    PDB0_CH1C1 = pdb_ch_config; // ADC 1

    // all channel delays are 0; ADC conversions are triggered as soon as possible
    PDB0_CH0DLY0 = 0;
    PDB0_CH0DLY1 = 0;
    PDB0_CH1DLY0 = 0;
    PDB0_CH1DLY1 = 0;

    // sync buffered registers
    PDB0_SC = ADC_PDB_CONFIG | PDB_SC_PRESCALER(0) | PDB_SC_MULT(0) | PDB_SC_LDOK;
   
    // enable interrupt for ADC1, second conversion (B-channel)
    ADC1_SC1B |= ADC_SC1_AIEN;
    NVIC_ENABLE_IRQ(IRQ_ADC1);

    // Kick off ADC conversion.
    PDB0_SC = ADC_PDB_CONFIG | PDB_SC_PRESCALER(0) | PDB_SC_MULT(0) | PDB_SC_SWTRIG; // start


    delay(500);
}



elapsedMicros t0;

void loop() {
    float current = 0.0;
    for(size_t i = 0; i < 100; i++) {
        t0 = 0;
        auto inputs = buffer[i].v;
        float vm = inputSlope*float(inputs[0]) + inputIntercept; // membrane potential in mV
        for (int ii=1; ii<4; ii++) {
          if (channelsInUse[ii-1]) {
            current += -prefactors[ii-1] * float(inputs[ii]) * (vm - reversalPotentials[ii-1]); // current in pA
          }
        }
        current = outputSlope*current + outputIntercept; // current in DAC units (0-4096) rather than pA
        int outputSignal = constrain(current,0,4095); // 12 bit     
        analogWrite(dac_pin0,outputSignal);
        while (t0<dt){}; // for more precise timing, wait for the specified dt to elapse (e.g., 10 usec when sampleFrequency=100 kHz)
    }
}



void adc1_isr() {
    size_t write_pos_ = write_pos;
    // reading the result clears the interrupt flag
    buffer[write_pos_] = { ADC0_RA, ADC0_RB, ADC1_RA, ADC1_RB };
    write_pos_++;
    if(write_pos_ >= buffer.size()) write_pos_ = 0;
    write_pos = write_pos_;
}

