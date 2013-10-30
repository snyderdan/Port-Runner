'
' VirtualPort object
' Essentially a container for the pins used in a virtual port

CON

  PIN_COUNT = 8                ' Pins per virtual port

VAR

  byte pinMap[PIN_COUNT]
  byte nextIndex
  
PUB registerPin(pin)

  if nextIndex == PIN_COUNT
    nextIndex := 0

  pinMap[nextIndex++] := pin

PUB getPin(index)

  return pinMap[index]

PUB clearPins | index


  repeat index from 0 to nextIndex - 1
    pinMap[index] := 0

  nextIndex := 0

PUB pinsUsed

  return nextIndex
  