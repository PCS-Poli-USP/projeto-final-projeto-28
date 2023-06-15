#include <ESP8266WiFi.h>

#define D2 4
#define D1 5
#define D6 12
#define TX D1
#define LED D6
#define LED2 D2 
#define BAUD 200
#define BAUD_T 5

char ssid[] = "PCS-Wireless";      //  your network SSID (name)
char pass[] = "a987654321";   // your network password

int status = WL_IDLE_STATUS;
WiFiServer server(80);

void setup() {
  Serial.begin(9600);      // initialize serial communication
  pinMode(LED, OUTPUT);      // set the LED pin mode
  pinMode(TX, OUTPUT);
  pinMode(LED2, OUTPUT);      // set the LED pin mode
  digitalWrite(TX, HIGH);
  delay(BAUD_T*5);
  // check for the presence of the shield:
  if (WiFi.status() == WL_NO_SHIELD) {
    while (true);       // don't continue
  }
  
  
  // attempt to connect to Wifi network:
  while (status != WL_CONNECTED) {
    // Connect to WPA/WPA2 network. Change this line if using open or WEP network:
    status = WiFi.begin(ssid, pass);
    // wait 1 seconds for connection:
    for(int i = 0; i < 10; i++){
      digitalWrite(LED, HIGH);                // GET /L turns the LED off
      delay(500);
      digitalWrite(LED, LOW);                // GET /L turns the LED off
      delay(500);
    }
  }
  server.begin();                           // start the web server on port 80
  digitalWrite(LED2, HIGH);                // GET /L turns the LED off
  delay(500);
  digitalWrite(LED2, LOW);                // GET /L turns the LED off
  delay(500);
  //printWifiStatus();                        // you're connected now, so print out the status
  printIP();
}


void loop() {
  WiFiClient client = server.available();   // listen for incoming clients

  if (client) {                             // if you get a client,
    Serial.println("new client");           // print a message out the serial port
    String currentLine = "";                // make a String to hold incoming data from the client
    while (client.connected()) {            // loop while the client's connected
      if (client.available()) {             // if there's bytes to read from the client,
        char c = client.read();             // read a byte, then
        //Serial.write(c);                    // print it out the serial monitor
        if (c == '\n') {                    // if the byte is a newline character

          // if the current line is blank, you got two newline characters in a row.
          // that's the end of the client HTTP request, so send a response:
          if (currentLine.length() == 0) {
            char pagina[] = "HTTP/1.1 200 OK\nContent-type:text/html\n\nClick <a href=\"/RED\">here</a> turn the RED LED on<br>\nClick <a href=\"/GREEN\">here</a> turn the GREEN LED on<br>";
            client.println(pagina);
            break;
          } else {    // if you got a newline, then clear currentLine:
            currentLine = "";
          }
        } else if (c != '\r') {  // if you got anything else but a carriage return character,
          currentLine += c;      // add it to the end of the currentLine
        }

        // Check to see if the client request was "GET /H" or "GET /L":
        if (currentLine.endsWith("GET /RED")) {
          digitalWrite(LED, HIGH);               // GET /H turns the LED on
          delay(100);
          digitalWrite(LED, LOW);                // GET /L turns the LED off
        }
        if (currentLine.endsWith("GET /GREEN")) {
          digitalWrite(LED2, HIGH);                // GET /L turns the LED off
          delay(100);
          digitalWrite(LED2, LOW);                // GET /L turns the LED off
        }
      }
    }
    // close the connection:
    client.stop();
  }
}

void tx(char a){
  digitalWrite(TX, HIGH);
  delay(BAUD_T*3);
  digitalWrite(TX, LOW);
  delay(BAUD_T);
  for(int i = 0; i < 8; i++){
    digitalWrite(TX, bool((a>>i)&1));
    delay(BAUD_T);
    }
   digitalWrite(TX, HIGH);
   delay(BAUD_T*3);
}


void printWifiStatus() {
  // print the SSID of the network you're attached to:

  // print your WiFi shield's IP address:
  IPAddress ip = WiFi.localIP();

Serial.println(ip[0]);
  delay(500);
  Serial.println(ip[1]);
  delay(500);
  Serial.println(ip[2]);
  delay(500);
  Serial.println(ip[3]);
  
}

void printIP(){  
  IPAddress ip = WiFi.localIP();
  for(int i = 0; i < 4; i++){
    //digitalWrite(TX, HIGH);
    tx((char) ip[i]);
  }  
}
