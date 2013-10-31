#ifndef PORTRUNNER_H
#define PORTRUNNER_H

#include "Arduino.h"
#include <stdlib.h>

#define SETUP          B10000000
#define PARALLEL_WRITE B00000000
#define PWM_WRITE      B01000000
#define WRITE          B00000000
#define VIRT_OUT_NUM   B00011111
#define LENGTH         B01100000
#define PULL_UP        B00100000
#define PULL_DOWN      B00000000
#define VIRTUAL_PORTS  32
#define PHYSICAL_PORTS 8

#define waitForRise(pin) while (!(PIND & (1 << pin))) {}
#define waitForFall(pin) while (PIND & (1 << pin)) {}
//#define waitForData(bytes)    while ((bytesreceived - index) < bytes) {}

//#define PORTRUNNER_DEBUG

#ifdef PORTRUNNER_DEBUG
  #define PRINT(VALUE, FORMAT...) Serial.print(VALUE, ##FORMAT)
  #define PRINTLN(VALUE, FORMAT...) Serial.println(VALUE, ##FORMAT)
#else
  #define PRINT(VALUE, FORMAT...)
  #define PRINTLN(VALUE, FORMAT...)
#endif

class VirtualPort {
  public:
    VirtualPort();                 // initialize new virtual port
    void registerPin(int pin);     // assign pin to next slot in virtual port
    int getPin(int index);         // get pin at index 
    int getIndex(int pin);         // return first index that pin appears; -1 if not present
    void removeIndex(int index);   // removes the index from the virtual port
    void removePin(int pin);       // removes the first occurence of the pin from the port
    byte pinsUsed();               // get number of pins used by virtual port
    byte *pins();                  // returns a pointer to the pin array
  private:
    volatile byte _pins[PHYSICAL_PORTS];  // array of pins 
    volatile byte _pins_used;             // count of pins used
};

class Master {
  public:
    Master(int interrupt_num, int clock_pin, int first_data_pin, int data_pin_count);  // initialize new master object
    void process();                                      // function to process next command
    void recv();                                         // interrupt function called to receive next command
    void waitForData(byte b);                            // busy wait until we receive the total number of bytes needed for the command we're processing
  private:
    void writeCommand();                                 // called from process function; does both PWM and parallel writes
    void setCommand();                                   // called from process function; sets up a virtual port
    volatile VirtualPort **_vports;                      // pointer to virtual ports
    volatile byte bitsreceived, bytesreceived, bytebuffer, cmdbuffer[256];  // variables used for receiving commands since it may not be received in whole bytes
    volatile byte basepin, pincount, datamask, intpin, index;               // variables containing info about the interrupt pin, data pins, etc. 
};

#endif
