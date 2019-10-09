
#include <ADC.h>
#include <DMAChannel.h>

#define BUFFER_SIZE 32000                   // up to 85% of dynamic memory (65,536 bytes)
#define SAMPLE_RATE 500000                  // see below maximum values
#define SAMPLE_AVERAGING 0                  // 0, 4, 8, 16 or 32
#define SAMPLING_GAIN 1                     // 1, 2, 4, 8, 16, 32 or 64
#define SAMPLE_RESOLUTION 16                // 8, 10, 12 or 16



// Main Loop Flow
#define CHECKINPUT_INTERVAL   50000         // 20 times per second
#define DISPLAY_INTERVAL      100000        // 10 times per second
#define SERIAL_PORT_SPEED     9600          // USB is always 12 Mbit/sec on teensy
#define DEBUG                 false

unsigned long lastInAvail;       //s = string(12345, base = 16)
unsigned long lastDisplay;       //
unsigned long lastBlink;         //
unsigned long currentTime;       //
unsigned long timeTest;
unsigned long func_timer; // <<<<<<<<<<< Time execution of different functions
bool          STREAM  = false;
bool          VERBOSE =  true;
bool          BINARY = true;
// I/O-Pins
const int writePin0            = A21;
const int readPin0             = A14;
const int readPin1             = A15;

const int ledPin               = LED_BUILTIN;

//ADC & DMA Config
ADC *adc = new ADC(); //adc object
// Variables for ADC0
static uint16_t buf_a[BUFFER_SIZE]; // buffer a
static uint16_t buf_b[BUFFER_SIZE]; // buffer b

uint32_t                    freq     = SAMPLE_RATE;
uint8_t                     aver     = SAMPLE_AVERAGING;
uint8_t                      res     = SAMPLE_RESOLUTION;
uint8_t                    sgain     = SAMPLING_GAIN;
float                       Vmax     = 3.3;
ADC_REFERENCE               Vref     = ADC_REFERENCE::REF_3V3;
ADC_SAMPLING_SPEED    samp_speed     = ADC_SAMPLING_SPEED::VERY_HIGH_SPEED;
ADC_CONVERSION_SPEED  conv_speed     = ADC_CONVERSION_SPEED::VERY_HIGH_SPEED;


char chirp[12001];

void setup() { // =====================================================

  pinMode(LED_BUILTIN, OUTPUT);
  pinMode(readPin0, INPUT); // single ended
  pinMode(readPin0, INPUT); // single ended

  pinMode(writePin0,OUTPUT); //DAC write
  // Setup monitor pin
  pinMode(ledPin, OUTPUT);
  digitalWriteFast(ledPin, LOW); // LED low, setup start

  while (!Serial && millis() < 3000) ;
  Serial.begin(Serial.baud());
  Serial.println("ADC Server (Minimal)");
  Serial.println("c to start conversion, p to print buffer");

  // clear buffers
  memset((void*)buf_a, 0, sizeof(buf_a));
  memset((void*)buf_b, 0, sizeof(buf_b));

  // LED on, setup complete
  digitalWriteFast(ledPin, HIGH);

    adc->setResolution(16); // set bits of resolution
    adc->setConversionSpeed(ADC_CONVERSION_SPEED::HIGH_SPEED); // change the conversion speed
    adc->setSamplingSpeed(ADC_SAMPLING_SPEED::HIGH_SPEED); // change the sampling speed


    ////// ADC1 /////
    adc->setResolution(16, ADC_1); // set bits of resolution
    adc->setConversionSpeed(ADC_CONVERSION_SPEED::HIGH_SPEED, ADC_1); // change the conversion speed
    adc->setSamplingSpeed(ADC_SAMPLING_SPEED::HIGH_SPEED, ADC_1); // change the sampling speed


    adc->startSynchronizedSingleRead(readPin0, readPin1);
} // setup =========================================================

int          inByte   = 0;
String inNumberString = "";
long         inNumber = -1;
boolean   chunk1_sent = false;
boolean   chunk2_sent = false;
boolean   chunk3_sent = false;
ADC::Sync_result result;


void loop() { // ===================================================

  currentTime = micros();
  // Commands:
  // c initiate single conversion
  // p print buffer
  // s to recieve the chirp and transmit and DO 2 ADC conversion simultenously
  if ((currentTime-lastInAvail) >= CHECKINPUT_INTERVAL) {
    lastInAvail = currentTime;
    if (Serial.available()) {
      inByte=Serial.read();

      if(inByte == 's'){
      for(int n=0;n<12001;n++){
        while(Serial.available()== false){} //wait for chirp pulse
          char lo = Serial.read();            // read the command
          chirp[n]=lo;
      }

      //Sending Data  to DAC
      for(int i=0;i<1;i++){
        for(int n=0;n<12001;n++){
           analogWrite(writePin0,chirp[n]);
        }
      }
      for(int j=0;j<BUFFER_SIZE-1;j++){
        result = adc->readSynchronizedSingle();
        buf_a[j]=(uint16_t)result.result_adc0;
        buf_a[j]=(uint16_t)result.result_adc1;
      }
      adc->printError();


      }else if (inByte == 'p') { // print buffer
          printBuffer(buf_a, 0, BUFFER_SIZE-1);
      }else if (inByte == 'q') { // print buffer
          printBuffer(buf_b, 0, BUFFER_SIZE-1);
      }
    }
  }

  if ((currentTime-lastDisplay) >= DISPLAY_INTERVAL) {
    lastDisplay = currentTime;
    adc->printError();
    adc->resetError();
  }
} // end loop ======================================================

///ADC setup //////////////////////

////////////////////////////////////////////////////////////////////
void printBuffer(uint16_t *buffer, size_t start, size_t end) {
  size_t i;
  if (VERBOSE) {
    for (i = start; i <= end; i++) {
      Serial.println(buffer[i]);
      //Serial.println((buffer[i] >> 8) & 0xFF); // Send the upper byte first
      //Serial.println((buffer[i] & 0xFF));

      }

  } else {
    for (i = start; i <= end; i++) {
      serial16Print(buffer[i]);
      Serial.println(); }
  }
}

void print2Buffer(uint16_t *buffer1,uint16_t *buffer2, size_t start, size_t end) {
  size_t i;
  if (VERBOSE) {
    for (i = start; i <= end; i++) {
      Serial.print(buffer1[i]);
      Serial.print(",");
      Serial.println(buffer2[i]);}
  } else if (BINARY) {
    for (i = start; i <= end; i++) {
      byte* byteData1 = (byte*) buffer1[i];
      byte* byteData2 = (byte*) buffer2[i];
      byte buf[5] = {byteData1[0],byteData1[1],byteData2[0],byteData2[1],'\n'};
      Serial.write(buf,5);
    }
  } else {
    for (i = start; i <= end; i++) {
      serial16Print((buffer1[i]));
      Serial.print(",");
      serial16Print((buffer2[i]));
      Serial.println(",");
    }
  }
}

// CONVERT FLOAT TO HEX AND SEND OVER SERIAL PORT
void serialFloatPrint(float f) {
  byte * b = (byte *) &f;
  for(int i=3; i>=0; i--) {

    byte b1 = (b[i] >> 4) & 0x0f;
    byte b2 = (b[i] & 0x0f);

    char c1 = (b1 < 10) ? ('0' + b1) : 'A' + b1 - 10;
    char c2 = (b2 < 10) ? ('0' + b2) : 'A' + b2 - 10;

    Serial.print(c1);
    Serial.print(c2);
  }
}

// CONVERT Byte TO HEX AND SEND OVER SERIAL PORT
void serialBytePrint(byte b) {
  byte b1 = (b >> 4) & 0x0f;
  byte b2 = (b & 0x0f);

  char c1 = (b1 < 10) ? ('0' + b1) : 'A' + b1 - 10;
  char c2 = (b2 < 10) ? ('0' + b2) : 'A' + b2 - 10;

  Serial.print(c1);
  Serial.print(c2);
}

// CONVERT 16BITS TO HEX AND SEND OVER SERIAL PORT
void serial16Print(uint16_t u) {
  byte * b = (byte *) &u;
  for(int i=1; i>=0; i--) {

    byte b1 = (b[i] >> 4) & 0x0f;
    byte b2 = (b[i] & 0x0f);

    char c1 = (b1 < 10) ? ('0' + b1) : 'A' + b1 - 10;
    char c2 = (b2 < 10) ? ('0' + b2) : 'A' + b2 - 10;

    Serial.print(c1);
    Serial.print(c2);
  }
}

// CONVERT Long TO HEX AND SEND OVER SERIAL PORT
void serialLongPrint(unsigned long l) {
  byte * b = (byte *) &l;
  for(int i=3; i>=0; i--) {

    byte b1 = (b[i] >> 4) & 0x0f;
    byte b2 = (b[i] & 0x0f);

    char c1 = (b1 < 10) ? ('0' + b1) : 'A' + b1 - 10;
    char c2 = (b2 < 10) ? ('0' + b2) : 'A' + b2 - 10;

    Serial.print(c1);
    Serial.print(c2);
  }
}
// Debug ===========================================================

typedef struct  __attribute__((packed, aligned(4))) {
  uint32_t SADDR;
  int16_t SOFF;
  uint16_t ATTR;
  uint32_t NBYTES;
  int32_t SLAST;
  uint32_t DADDR;
  int16_t DOFF;
  uint16_t CITER;
  int32_t DLASTSGA;
  uint16_t CSR;
  uint16_t BITER;
} TCD_DEBUG;

void dumpDMA_TCD(const char *psz, DMABaseClass *dmabc)
{
  Serial.printf("%s %08x %08x:", psz, (uint32_t)dmabc, (uint32_t)dmabc->TCD);
  TCD_DEBUG *tcd = (TCD_DEBUG*)dmabc->TCD;
  Serial.printf("%08x %04x %04x %08x %08x ", tcd->SADDR, tcd->SOFF, tcd->ATTR, tcd->NBYTES, tcd->SLAST);
  Serial.printf("%08x %04x %04x %08x %04x %04x\n", tcd->DADDR, tcd->DOFF, tcd->CITER, tcd->DLASTSGA,
                tcd->CSR, tcd->BITER);

}
