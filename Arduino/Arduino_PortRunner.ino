
#include "PortRunner.h"

Master *m;

void setup() {
#ifdef PORTRUNNER_DEBUG
  Serial.begin(9600);
#endif
  //Serial.println("SERIAL");
  //delay(30);
  pinMode(12, OUTPUT);
  digitalWrite(12, HIGH);
  pinMode(3,INPUT);
  pinMode(13,OUTPUT);
  m = new Master(1,3,4,4);
  //Serial.println("INIT");
  //delay(30);
  //analogWrite(9, 255);
  //delay(1000);
  //analogWrite(10,255);
  //delay(1000);
  //analogWrite(11, 255);
  //delay(1000);
}

void loop() {
}

