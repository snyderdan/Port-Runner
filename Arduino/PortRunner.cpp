#include "PortRunner.h"

Master *_mstr;

void _recv() {
  _mstr->recv();
}

#ifdef main  
#undef main
#endif

int main(void) {
  init();
  
  pinMode(13, OUTPUT);
  setup();
  for (;;) {
    //loop();
    _mstr->process();
  }
  return 0;
} 

/*
 **********************************************************
 *
 * Master class functions
 *
 **********************************************************
 */

Master::Master(int interrupt_number, int clock_pin, int first_data_pin, int data_pin_count) {
  int i;
  
  bitsreceived = 0;        // number of bits received in the initial buffer
  bytesreceived = 0;       // number of bytes waiting in command buffer
  index = 0;               // our place in the command buffer
  basepin  = first_data_pin; // record inorder to set the base data pin back down to bit 0
  pincount = data_pin_count; // record to shift the buffer proper distances to accept new data (must be power of 2)
  intpin  = clock_pin; // clock triggers interrupt to receive data
  datamask = 0;        // mask to and with PIND in order to read all the data in one shot instead of looping
  //Serial.println(pincount, DEC);
  //Serial.println(basepin, DEC);
  for (i=first_data_pin; i<first_data_pin+data_pin_count; i++) { // loop builds up the number of 1s in the mask
    pinMode(i, INPUT);
    datamask <<= 1; 
    datamask |= 1;
  }
  
  *_vports = (volatile VirtualPort *) calloc(VIRTUAL_PORTS, sizeof(VirtualPort *));
  datamask <<= first_data_pin;   // offsets the mask by the first data pin (so pin 0 would result in the last mask bit being in position 0)
  
  for (i=0; i<VIRTUAL_PORTS; i++) {
    _vports[i] = new VirtualPort(); // sets up virtual outputs
  }
  _mstr = this; // sets global master in order to attach interrupt to a function with no args
  //interrupts();
  attachInterrupt(interrupt_number, _recv, RISING);
}

void Master::waitForData(byte b) {
    while(true){
      PRINT(F("RECV:"));
      PRINT(bytesreceived,DEC);
      PRINT(F(" IND:"));
      PRINTLN(index, DEC);
      if(bytesreceived < index){
        if((int)bytesreceived + 255 - index >= b){
          return;
        }
      } else {
        if(bytesreceived - index >= b){
          return;
        }
      }
    }
}

void Master::process() {
 //Serial.println(index, DEC);
 if (index == bytesreceived) {
    //Serial.print(6,DEC);
    return;
  }
  //Serial.print(,DEC);
  int command = cmdbuffer[index];
  PRINT(F("CMD: "));
  PRINTLN(command, BIN);
  digitalWrite(13, HIGH);
  switch (command & SETUP) {
    case WRITE:
      writeCommand();
      break;
    case SETUP:
      setCommand();
      break;
  }
  digitalWrite(13, LOW);
}

void Master::recv() {
  //PRINTLN("INTERRUPT");
  //noInterrupts();
  //digitalWrite(13, HIGH);
  
  bytebuffer <<= pincount; // make room for new data
  bytebuffer |= ((PIND & datamask) >> basepin); // read new data from bus to buffer
  bitsreceived += pincount; 
  
  //waitForFall(intpin);     // ensure that interrupt pin falls before exiting
  
  
  if (bitsreceived == 8) {
    //Serial.print(2, HEX);
    bitsreceived = 0;
    cmdbuffer[bytesreceived++] = bytebuffer;
  }
  //digitalWrite(13, LOW);
  //interrupts();
  //Serial.println(bytebuffer & 0xF, BIN);
}

void Master::writeCommand() { // function gets called when index is at least one greater than bytesreceived
  //Serial.print(4, HEX);
  /*
   * Transmission layout:
   *
   * Bits: 7 6 5 4   3 2 1 0    8-bits
   *       0 C P V   V V V V    BYTE
   *
   * C     = Command: 
   *           0 = PWM       = Write PWM to all ports in vout
   *           1 = Multi-bit = Write each bit in the byte to a port in vout
   * P     = Pull: 
   *           PWM Mode:  the state to set pins that do not support PWM
   *           Multi-bit: 1 = preserve MSB; 0 = preserve LSB
   * VVVVV = virtual output port to write to
   * BYTE  = Value to write
   */
  int i, pull, cmd, value, pin;
  VirtualPort *vport;
  
  waitForData(2); // ensure we've received the entire command
  
  /*
   * So this is what our buffer looks like at this point in the code...
   * 
   *   ____base_buffer____
   *  |_________+1________|
   *  |_________+2________|
   *  | . . . . . . . . . |
   *  |___________________|
   *  |___write_command___| <- index
   *  |___value_to_write__| 
   *  |___next_command____|
   *  | . . . . . . . . . |
   *  |___________________| <- bytesreceived
   *  | . . . . . . . . . |
   *  |_____base+255______|
   *
   */
  cmd = cmdbuffer[index++];
  value = cmdbuffer[index++];
  pull = (cmd & PULL_UP) >> 5;
  vport = (VirtualPort *) _vports[cmd & VIRT_OUT_NUM];
  
  if (cmd & PWM_WRITE) {  // Else, it's a PWM command
    PRINT(F("PWM VPORT "));
    PRINTLN(cmd & VIRT_OUT_NUM, DEC);
    for (i=0; i<vport->pinsUsed(); i++) {
      
      pin = vport->getPin(i);
      if (digitalPinToTimer(pin) == NOT_ON_TIMER){ // Check to see if it supports PWM
        digitalWrite(pin, pull);                  // If not, write the value of pull
        PRINT(F("NO CLOCK ON PIN "));
        PRINTLN(pin, DEC);
      } else {
        //Serial.print(i, DEC);
        //Serial.print(" out of ");
        PRINT(vport->pinsUsed(), DEC);
        PRINTLN(F(" pins used"));
        PRINT(pin, DEC);
        PRINT(F(" = "));
        PRINTLN(value, DEC);
        analogWrite(pin, value);        // Else, output the PWM value
      }
    }
  } else { // If bit 6 is set, it's a Multi-bit command
    PRINTLN(F("wrong"));
    for (i=0; i<vport->pinsUsed(); i++) {
      
      pin = vport->getPin(i);
      
      if (pull) { // If we're preserving the MSB
        digitalWrite(pin, 1 && (value & 0x80)); // Send the MSB to the current pin
        value = value << 1;                     // Shift up the next bit below
      } else {   // Else, we're preserving the LSB
  	digitalWrite(pin, 1 && (value & 0x1));  // Send the LSB to the current pin
  	value = value >> 1;                     // Shift down the next bit above
      }
    }
    
  } 
  //Serial.println("WR");
}

void Master::setCommand() {
  //PRINT("set");
  //Serial.print(3, HEX);
  int cmd, len, i;
  VirtualPort *vport;
  
  cmd = cmdbuffer[index];
  len = 2 * (((cmd & LENGTH) >> 5) + 1); // Calculate the number of ports assigning to the virtual port
  vport = (VirtualPort *) _vports[cmd & VIRT_OUT_NUM];
  PRINT(F("SET VPORT "));
  PRINT(cmd & VIRT_OUT_NUM, DEC);
  PRINT(": "); 
  waitForData(len+1); // Ensure we receive full command
  
  index++; // increment over the command byte 
  
  /*
   * I decided to not increment in the assignment of cmd because if we want the Arduino
   * to do it's own processing, we can change the waitForData macro to an if () statement that
   * returns if not all bytes are present. Then the command can be reprocessed during the next
   * pass of the process() function, instead of stalling in this function waiting for data.
   */
  
  for (i=0; i<len; i++) {
    PRINT(cmdbuffer[index], DEC);
    PRINT(F(" "));
    vport->registerPin(cmdbuffer[index++]);
  }
  PRINTLN(F(""));
  //Serial.println("SETUP");
}

/*
 **********************************************************
 *
 * VirtualPort Functions
 *
 **********************************************************
 */

VirtualPort::VirtualPort() {
  for (int i=0; i<PHYSICAL_PORTS; i++) 
    _pins[i] = 0;
  _pins_used = 0;
}

void VirtualPort::registerPin(int pin) {
  if (_pins_used == PHYSICAL_PORTS) {
    PRINTLN(F("WHAT?!"));
    _pins_used--;
  }
  pinMode(pin, OUTPUT);
  _pins[_pins_used++] = pin;
}

int VirtualPort::getPin(int index) {
  if (index >= _pins_used){
    return -1;
  } else {
    return _pins[index];
  }
}

int VirtualPort::getIndex(int pin) {
  for (int i=0; i<PHYSICAL_PORTS; i++) 
    if (_pins[i] == pin)
      return i;
  return -1;
}
void VirtualPort::removeIndex(int index) {
  memmove((void *) (((int) _pins)+1),(void *) (((int) _pins)+index),PHYSICAL_PORTS-1-index);
  _pins_used--;
}

void VirtualPort::removePin(int pin) {
  int i;
  while ((i=getIndex(pin)) != -1) {
    removeIndex(i);
  }
}

byte VirtualPort::pinsUsed() {
  return _pins_used;
}

byte *VirtualPort::pins() {
  return (byte *) _pins;
}

