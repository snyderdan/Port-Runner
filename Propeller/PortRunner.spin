'
' Main class for slave-end of port runner
' Consumes 1 COG for recieving data, 1 COG for processing data,
' and 1 COG for the PWM driver. Kind of consuming, but the
' prop shouldn't be doing much else other than being a slave.
'
CON
  
  CMD_BUFFER_SIZE    = 256    ' Size of buffer for commands from master
  
  VIRTUAL_PORT_COUNT = 32     ' Number of virtual ports that will be handled

  LEDPort = 16                ' Used as a visual indicator for debugging

  CMD_MASK          = %1000_0000
  CMD_SETUP         = %1000_0000
  CMD_WRITE         = %0000_0000
  PARALLEL_WRITE    = %0000_0000
  PWM_WRITE         = %0100_0000
  VIRTUAL_PORT_MASK = %0001_1111
  SETUP_LENGTH_MASK = %0110_0000
  PULL_MASK         = %0010_0000
  PWM_PULL_UP       = %0010_0000
  PWM_PULL_DOWN     = %0000_0000

OBJ

  PWM : "PropPWM"
  
  virtualPorts[VIRTUAL_PORT_COUNT] : "VirtualPort"

  pst : "Parallax Serial Terminal"  

VAR

  long stack1[64] ' stack for process loop
  long stack2[64]
   
  byte cmdBuffer[CMD_BUFFER_SIZE], cmdIndex, bytesReceived

PUB start(clkPin, dataPin1, dataPinCount)

  PWM.start

  pst.start(115200)

  cognew(receive(clkPin,dataPin1,dataPinCount), @stack1)  

  cognew(process, @stack2)

PUB process | command

  dira~~ 
  pst.str(string("ENTERING",13))
  repeat
    if cmdIndex == bytesReceived
      next

    pst.str(STRING(13,"SOMETHING",13))
    command := cmdBuffer[cmdIndex]
    
    outa[LEDPort]~~
  
    case command & CMD_MASK
      CMD_WRITE: 
        pst.str(string("WRITE",13))
        writeCommand
      CMD_SETUP:
        pst.str(string("SETUP",13)) 
        setupCommand

    outa[LEDPort]~

PUB writeCommand | i, pull, command, value, pin, port

  waitForData(2)

  command := cmdBuffer[cmdIndex++]
  value   := cmdBuffer[cmdIndex++]

  pull    := (command & PULL_MASK) >> 5
  port    := command & VIRTUAL_PORT_MASK

  if command & PWM_WRITE
  
    repeat i from 0 to virtualPorts[port].pinsUsed - 1 
      pin := virtualPorts[port].getPin(pin)
      PWM.analogWrite(pin, value)
      
  else
  
    repeat i from 0 to virtualPorts[port].pinsUsed - 1   
      if pull
        pin       := virtualPorts[port].getPin(i)
        outa[pin] := (value & $80) >> 7
        value     <<= 1
      else  
        pin       := virtualPorts[port].getPin(i)
        outa[pin] := value & 1
        value     >>= 1 

PUB setupCommand | i, command, length, pin, port

  command := cmdBuffer[cmdIndex++]

  length  := (((command & SETUP_LENGTH_MASK) >> 5) + 1) << 1   ' Fake a multiply by 2
  port    := command & VIRTUAL_PORT_MASK

  waitForData(length)

  virtualPorts[port].clearPins
  
  repeat i from 0 to length - 1
    pin := cmdBuffer[cmdIndex++]
    virtualPorts[port].registerPin(pin)

PUB waitForData(bytesNeeded) | bytesRecv, bytes

  repeat

    bytesRecv := bytesReceived

    if bytesRecv < cmdIndex
      bytes := bytesRecv + 255 - cmdIndex
    else
      bytes := bytesRecv - cmdIndex

    if bytes => bytesNeeded
      return
            
PUB receive(clockPin, basePin, pinCount) | i,clkMask,dataMask,byteBuffer,bitCount

  clkMask :=  1
  clkMask <<= clockPin

  repeat i from 0 to pinCount-1
    dataMask <<= 1
    dataMask |=  1

  dataMask <<= basePin

  dira := dira & !dataMask
  dira := dira & !clkMask  

  repeat
  
    repeat until ina & clkMask

    pst.str(string("GOT CLK",13))

    byteBuffer <<= pinCount
    byteBuffer |=  (ina & dataMask) >> basePin
    bitCount   +=  pinCount

    if bitCount => 8

      cmdBuffer[bytesReceived++] := byteBuffer

      bitCount    -= 8
      byteBuffer >>= 8

    repeat until not ina & clkMask
    