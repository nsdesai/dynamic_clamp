// Use this sketch to adjust the gain and offset trim potentiometers so that VAMP reads
// from +3.3V to -3.3V (or slightly under) on an oscilloscope.
// IMPORTANT: VDAQ must be at 0V (not disconnected), either connect some instrument or
//            use a 50 Ohm termination cap.

// Credit: MartinL
// https://forum.arduino.cc/t/samd51-dac-using-dma-seems-too-fast/678418/4

// Use SAMD51's DMAC to generate a 1kHz sine wave 0 to 3.3V amplitude on A0 using DAC0
#define SAMPLE_NO 1000

uint16_t sintable[SAMPLE_NO];                                             // Sine table

typedef struct                                                            // DMAC descriptor structure
{
  uint16_t btctrl;
  uint16_t btcnt;
  uint32_t srcaddr;
  uint32_t dstaddr;
  uint32_t descaddr;
} dmacdescriptor ;

volatile dmacdescriptor wrb[DMAC_CH_NUM] __attribute__ ((aligned (16)));          // Write-back DMAC descriptors
dmacdescriptor descriptor_section[DMAC_CH_NUM] __attribute__ ((aligned (16)));    // DMAC channel descriptors
dmacdescriptor descriptor __attribute__ ((aligned (16)));                         // Place holder descriptor

void setup() {
  DMAC->BASEADDR.reg = (uint32_t)descriptor_section;                      // Specify the location of the descriptors
  DMAC->WRBADDR.reg = (uint32_t)wrb;                                      // Specify the location of the write back descriptors
  DMAC->CTRL.reg = DMAC_CTRL_DMAENABLE | DMAC_CTRL_LVLEN(0xf);            // Enable the DMAC peripheral

  for (uint16_t i = 0; i < SAMPLE_NO; i++)                                // Calculate the sine table with 1000 entries
  {
    sintable[i] = (uint16_t)((sinf(2 * PI * (float)i / SAMPLE_NO) * 2047.0f) + 2048.0f);    // 12-bit resolution with +1.63V offset
  }
  
  DAC->DACCTRL[0].bit.CCTRL = 1;                                          // Set the DAC's current control to allow output to operate at 1MSPS
  analogWriteResolution(12);                                              // Set the DAC's resolution to 12-bits
  analogWrite(A0, 0);                                                     // Initialise DAC0
 
  DMAC->Channel[5].CHCTRLA.reg = DMAC_CHCTRLA_TRIGSRC(TC0_DMAC_ID_OVF) |  // Set DMAC to trigger when TC0 timer overflows
                                 DMAC_CHCTRLA_TRIGACT_BURST;              // DMAC burst transfer
  descriptor.descaddr = (uint32_t)&descriptor_section[5];                 // Set up a circular descriptor
  descriptor.srcaddr = (uint32_t)&sintable[0] + SAMPLE_NO * sizeof(uint16_t);  // Read the current value in the sine table
  descriptor.dstaddr = (uint32_t)&DAC->DATA[0].reg;                       // Copy it into the DAC data register
  descriptor.btcnt = SAMPLE_NO;                                           // This takes the number of sine table entries = 1000 beats
  descriptor.btctrl = DMAC_BTCTRL_BEATSIZE_HWORD |                        // Set the beat size to 16-bits (Half Word)
                      DMAC_BTCTRL_SRCINC |                                // Increment the source address every beat
                      DMAC_BTCTRL_VALID;                                  // Flag the descriptor as valid
  memcpy((void*)&descriptor_section[5], &descriptor, sizeof(dmacdescriptor));  // Copy to the channel 5 descriptor 

  GCLK->PCHCTRL[TC0_GCLK_ID].reg = GCLK_PCHCTRL_CHEN |                    // Enable perhipheral channel for TC0
                                   GCLK_PCHCTRL_GEN_GCLK1;                // Connect generic clock 1 at 48MHz
 
  TC0->COUNT16.WAVE.reg = TC_WAVE_WAVEGEN_MFRQ;                           // Set TC0 to Match Frequency (MFRQ) mode
  TC0->COUNT16.CC[0].reg = 47;                                            // Set the sine wave frequency to 1kHz: 48MHz / (f * n) - 1
  while (TC0->COUNT16.SYNCBUSY.bit.CC0);                                  // Wait for synchronization

  TC0->COUNT16.CTRLA.bit.ENABLE = 1;                                      // Enable the TC0 timer
  while (TC0->COUNT16.SYNCBUSY.bit.ENABLE);                               // Wait for synchronization
 
  DMAC->Channel[5].CHCTRLA.bit.ENABLE = 1;                                // Enable DMAC on channel 5
}

void loop(){}