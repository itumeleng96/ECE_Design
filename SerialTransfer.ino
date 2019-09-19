//Transmit chirp pulse on DAC output and recieve through the ADC pins
//chirp pulse at 40Khz will be amplified and the recieved will also be amplified. 

int led=13;               //Led PIN on the teensy board to show that it is working 
char chirp [12001];
char buf [12001];
void setup() {
  // initialize serial communications at 9600 bps:
  Serial.begin(9600);
  pinMode(led,OUTPUT);
}

void loop() {
  //digitalWrite(led,LOW);         //just an indicator for reading and writing operation
  digitalWrite(led,HIGH);
  for(int n=0;n<12001;n++){ 
  while(Serial.available()== false){}  
    //char input = Serial.read();  // read the command 
    char lo = Serial.read();       // read the command 
    chirp[n]=lo;
    //Serial.write(lo);
  }

  for(int i=0;i<1;i++){
    for(int n=0;n<12001;n++){ 
      analogWrite(A21,chirp[n]);
   }
  }
  for(int i=0;i<1;i++){
    for(int n=0;n<12001;n++){ 
    buf[n]=analogRead(A0);
    Serial.write(buf[n]);
   }
  }
  digitalWrite(led,LOW);
}
