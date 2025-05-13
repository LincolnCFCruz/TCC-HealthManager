#include "WiFiProv.h"
#include "WiFi.h"

// ------------------------------

#include <Wire.h>
#include <U8g2lib.h>          // More memory-efficient OLED library
#include <Adafruit_BMP085.h>  // For BMP180
#include <MPU6050_tockn.h>    // For MPU6050

// ------------------------------

const char * pop = "abcd1234";            // Proof of possession - otherwise called a PIN - string provided by the device, entered by the user in the phone app
const char * service_name = "PROV_123";   // Name of your device (the Espressif apps expects by default device name starting with "Prov_")
const char * service_key = NULL;          // Password used for SofAP method (NULL = no password needed)
bool reset_provisioned = true;            // When true the library will automatically delete previously provisioned data.

// ------------------------------

// Use the most memory-efficient constructor
U8G2_SSD1306_128X64_NONAME_1_HW_I2C u8g2(U8G2_R0);

// ------------------------------

// Sensor objects (global but necessary)
Adafruit_BMP085 bmp;
MPU6050 mpu6050(Wire);

// ------------------------------

const int pulsePin = 15;

// ------------------------------

// WARNING: SysProvEvent is called from a separate FreeRTOS task (thread)!
void SysProvEvent(arduino_event_t *sys_event) {
  switch (sys_event->event_id) {
    case ARDUINO_EVENT_WIFI_STA_GOT_IP:
      Serial.print("\nConnected IP address : ");
      Serial.println(IPAddress(sys_event->event_info.got_ip.ip_info.ip.addr));
      break;
    case ARDUINO_EVENT_WIFI_STA_DISCONNECTED: Serial.println("\nDisconnected. Connecting to the AP again... "); break;
    case ARDUINO_EVENT_PROV_START:            Serial.println("\nProvisioning started\nGive Credentials of your access point using smartphone app"); break;
    case ARDUINO_EVENT_PROV_CRED_RECV:
    {
      Serial.println("\nReceived Wi-Fi credentials");
      Serial.print("\tSSID : ");
      Serial.println((const char *)sys_event->event_info.prov_cred_recv.ssid);
      Serial.print("\tPassword : ");
      Serial.println((char const *)sys_event->event_info.prov_cred_recv.password);
      break;
    }
    case ARDUINO_EVENT_PROV_CRED_FAIL:
    {
      Serial.println("\nProvisioning failed!\nPlease reset to factory and retry provisioning\n");
      if (sys_event->event_info.prov_fail_reason == NETWORK_PROV_WIFI_STA_AUTH_ERROR) {
        Serial.println("\nWi-Fi AP password incorrect");
      } else {
        Serial.println("\nWi-Fi AP not found....Add API \" nvs_flash_erase() \" before beginProvision()");
      }
      break;
    }
    case ARDUINO_EVENT_PROV_CRED_SUCCESS: 
      Serial.println("\nProvisioning Successful"); 
      break;
    
    case ARDUINO_EVENT_PROV_END:
      Serial.println("\nProvisioning Ends"); 
      break;

    default:
      break;
  }
}

// ------------------------------

void setup() {
  Serial.begin(9600);

  pinMode(pulsePin, INPUT);

  // ------------------------------

  WiFi.onEvent(SysProvEvent);

  Serial.println("Begin Provisioning using BLE");

  uint8_t uuid[16] = {0xb4, 0xdf, 0x5a, 0x1c, 0x3f, 0x6b, 0xf4, 0xbf, 0xea, 0x4a, 0x82, 0x03, 0x04, 0x90, 0x1a, 0x02}; // Sample uuid that user can pass during provisioning using BLE

  WiFiProv.beginProvision(NETWORK_PROV_SCHEME_BLE, NETWORK_PROV_SCHEME_HANDLER_FREE_BLE, NETWORK_PROV_SECURITY_1, pop, service_name, service_key, uuid, reset_provisioned);

  log_d("ble qr");

  WiFiProv.printQR(service_name, pop, "ble");

  // ------------------------------

  Wire.begin();

  // Initialize OLED with minimal memory footprint
  u8g2.begin();
  u8g2.setFont(u8g2_font_6x10_tr);
  u8g2.firstPage();

  do {
    u8g2.drawStr(0, 10, "Initializing...");
  } while (u8g2.nextPage());

  // Initialize sensors with error handling
  if (!bmp.begin()) {
    showError("BMP180 Fail");
    while(1);
  }

  mpu6050.begin();
  mpu6050.calcGyroOffsets(false); // Disable serial output to save memory
}

void loop() {
  static uint32_t lastUpdate = 0;
  if (millis() - lastUpdate >= 250) {
    lastUpdate = millis();
    
    // Read and process data in minimal scope
    float temperature = bmp.readTemperature();
    float pressure = bmp.readPressure() / 100.0f;
    float altitude = bmp.readAltitude(101325);
    
    mpu6050.update();
    float angleX = mpu6050.getAngleX();
    float angleY = mpu6050.getAngleY();
    float angleZ = mpu6050.getAngleZ();

    int pulseValue = analogRead(pulsePin);
    Serial.println(pulseValue);

    // Serial output (comment out if not needed to save memory)
    Serial.print(temperature); Serial.print("C ");
    Serial.print(pressure); Serial.print("hPa ");
    Serial.print(altitude); Serial.print("m ");
    Serial.print(angleX); Serial.print(",");
    Serial.print(angleY); Serial.print(",");
    Serial.println(angleZ);

    // Memory-efficient display update
    u8g2.firstPage();
    do {
      // Display first 3 lines
      u8g2.setCursor(0, 10);
      u8g2.print("T:"); u8g2.print(temperature, 1); u8g2.print("C");
      
      u8g2.setCursor(64, 10);
      u8g2.print("P:"); u8g2.print(pressure, 0); u8g2.print("hPa");
      
      u8g2.setCursor(0, 22);
      u8g2.print("Alt:"); u8g2.print(altitude, 1); u8g2.print("m");
      
      // Display angles
      u8g2.setCursor(0, 34);
      u8g2.print("X:"); u8g2.print(angleX, 1);
      u8g2.setCursor(64, 34);
      u8g2.print("Y:"); u8g2.print(angleY, 1);
      
      u8g2.setCursor(0, 46);
      u8g2.print("Z:"); u8g2.print(angleZ, 1);
      
      // Simple orientation indicator
      u8g2.drawFrame(110, 40, 16, 16);
      u8g2.drawPixel(118 + angleY/20, 48 + angleX/20);
    } while (u8g2.nextPage());
  }
}

void showError(const char *msg) {
  Serial.println(msg);
  u8g2.firstPage();
  do {
    u8g2.drawStr(0, 10, "ERROR:");
    u8g2.drawStr(0, 22, msg);
  } while (u8g2.nextPage());
  while(1);
}
