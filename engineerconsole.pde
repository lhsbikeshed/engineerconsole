import ddf.minim.spi.*;
import ddf.minim.signals.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import ddf.minim.effects.*;

import processing.serial.*;

import oscP5.*;
import netP5.*;
import java.awt.Point;

import java.awt.*;
import java.awt.image.BufferedImage;

//CHANGE ME
boolean testMode = false;


String serverIP = "127.0.0.1";
boolean serialEnabled = false;


//display handling
Hashtable<String, Display> displayMap = new Hashtable<String, Display>();
Display currentScreen, powerDisplay, wormholeDisplay;
BannerOverlay bannerSystem = new BannerOverlay();

//boot screen
BootDisplay bootDisplay;
//dropscene display
DropDisplay dropDisplay;

//osc
OscP5 oscP5;

//state of ship
ShipState shipState = new ShipState();

//sound shit
Minim minim;
ConsoleAudio consoleAudio;


PFont font;
long deathTime = 0;

//Peripheral things
Serial serialPort;
String serialBuffer = "";
String lastSerial = "";

Serial panelPort;
String panelBuffer = "";
String lastPanelSerial = "";

//heartbeat
long heartBeatTimer = -1;

int damageTimer = -1000;
PImage noiseImage;

boolean globalBlinker = false;
long blinkTime = 0;

long sillinessStartTime = 0;

void setup() {

  if (testMode) {
    serialEnabled = false;
    serverIP = "127.0.0.1";
    shipState.poweredOn = true;
  } else {
    serialEnabled = true;
    serverIP = "10.0.0.100";
    shipState.poweredOn = false;
  }


  size(1024, 768, P2D);
  noSmooth();
  frameRate(30);
  hideCursor();

  if (serialEnabled) {
    serialPort = new Serial(this, "COM11", 9600);
    panelPort = new Serial(this, "COM12", 115200);
  }

  noiseImage = loadImage("noise.png");

  oscP5 = new OscP5(this, 12001);

  powerDisplay =  new PowerDisplay(oscP5, serverIP);
  wormholeDisplay  =  new WormholeDisplay(oscP5, serverIP);

  displayMap.put("power", powerDisplay);
  displayMap.put("drop", new DropDisplay(oscP5, serverIP));
  displayMap.put("hyperspace", new HyperSpaceDisplay(oscP5, serverIP));
  displayMap.put("jamming", new JamDisplay(oscP5, serverIP));
  displayMap.put("airlockdump", new AirlockDisplay(oscP5, serverIP));
  displayMap.put("selfdestruct", new DestructDisplay());
  displayMap.put("RemoteConnection", new RemoteConnectionDisplay());
  displayMap.put("pwned", new PwnedDisplay());
  displayMap.put("wormholeStatus", wormholeDisplay );

  currentScreen = displayMap.get("power");


  bootDisplay = new BootDisplay();
  displayMap.put("boot", bootDisplay);    ///THIS    


  //setup sound
  minim = new Minim(this);
  consoleAudio = new ConsoleAudio(minim);

  font = loadFont("HanzelExtendedNormal-48.vlw");
  /*sync to current game screen*/
  OscMessage myMessage = new OscMessage("/game/Hello/EngineerStation");  
  oscP5.send(myMessage, new NetAddress(serverIP, 12000));
}

void draw() {
  if(shipState.sillinessInProgress && sillinessStartTime + 5000 < millis()){
    shipState.sillinessInProgress = false;
  }
  if (blinkTime + 750 < millis()) {
    blinkTime = millis();
    globalBlinker = ! globalBlinker;
  }
  noSmooth();
  background(0, 0, 0);
  //serial read
  if (serialEnabled) {
    while (serialPort.available () > 0) {
      char val = serialPort.readChar();
      if (val == ',') {
        //get first char
        dealWithSerial(serialBuffer);
        serialBuffer = "";
      } else {
        serialBuffer += val;
      }
    }

    while (panelPort.available () > 0) {
      char val = panelPort.readChar();
      if (val == ',') {
        //get first char
        dealWithSerial(panelBuffer);
        panelBuffer = "";
      } else {
        panelBuffer += val;
      }
    }
  }



  if (shipState.areWeDead) {
    fill(255, 255, 255);
    if (deathTime + 2000 < millis()) {
      textFont(font, 60);
      text("YOU ARE DEAD", 50, 300);
      textFont(font, 20);
      int pos = (int)textWidth(shipState.deathText);
      text(shipState.deathText, (width/2) - pos/2, 340);
    }
  } else {
    if (shipState.poweredOn) {
      currentScreen.draw();
    } else {
      if (shipState.poweringOn) {
        bootDisplay.draw();
        if (bootDisplay.isReady()) {
          shipState.poweredOn = true;
          shipState.poweringOn = false;
          /* sync current display to server */
          OscMessage myMessage = new OscMessage("/game/Hello/EngineerStation");  
          oscP5.send(myMessage, new NetAddress(serverIP, 12000));
        }
      }
    }
    bannerSystem.draw();      //THIS
  }

  if (heartBeatTimer > 0) {
    if (heartBeatTimer + 400 > millis()) {
      int a = (int)map(millis() - heartBeatTimer, 0, 400, 255, 0);
      fill(0, 0, 0, a);
      rect(0, 0, width, height);
    } else {
      heartBeatTimer = -1;
    }
  }

  if ( damageTimer + 1000 > millis()) {
    if (random(10) > 3) {
      image(noiseImage, 0, 0, width, height);
    }
  }
}

public void keyPressed() {
  consoleAudio.randomBeep();

  currentScreen.keyPressed();
  if (key >= '0' && key <= '9') {
    currentScreen.serialEvent("KEY:" + key);
  } else if (key == ' ') {
    currentScreen.serialEvent("BUTTON:AIRLOCK");
  } else if (key == ';') { //change me to something on keyboard
    currentScreen.serialEvent("KEY:" + key);
  } else if (key >= 'a' && key <= 't') {
    currentScreen.serialEvent("KEY:" + key);
  } else if (key == ' ') {
    currentScreen.serialEvent("KEY:" + key);
  } 
  if (key == '[') {
    if (shipState.sillinessLevel >= 0 && shipState.poweredOn && shipState.sillinessInProgress == false) {
      OscMessage msg = new OscMessage("/system/reactor/silliness");
      sillinessStartTime = millis();
      switch(shipState.sillinessLevel) {
      case 0:
        shipState.sillinessLevel = 1;
        shipState.sillinessInProgress = true;
        msg.add(0);
        oscP5.flush(msg, new NetAddress(serverIP, 12000));
        bannerSystem.setSize(700, 300);
        bannerSystem.setTitle("!!WARNING!!");
        bannerSystem.setText("Please do not push that button again");
        bannerSystem.displayFor(5000);
        consoleAudio.playClip("warning1");
        break;
      case 1:
        shipState.sillinessInProgress = true;
        //shut down
        shipState.sillinessLevel = 2;
        consoleAudio.playClip("warning2");
        msg.add(1);
        oscP5.flush(msg, new NetAddress(serverIP, 12000));
        break;
      case 2:
        shipState.sillinessInProgress = true;
        shipState.sillinessLevel = -1;
        consoleAudio.playClip("warning3");
        msg.add(2);
        oscP5.flush(msg, new NetAddress(serverIP, 12000));
        bannerSystem.setSize(700, 300);
        bannerSystem.setTitle("!!WARNING!!");
        bannerSystem.setText("You Didnt listen, did you?");
        bannerSystem.displayFor(5000);
        break;
      }
    }
  }
}
public void keyReleased() {
  currentScreen.keyReleased();
}

void dealWithSerial(String vals) {

  char p = vals.charAt(0);
  if (p == 'P') {          //this is from new panel
    if (vals.substring(0, 2).equals("PS")) {  //PS10:1
      //switch
      vals = vals.substring(2);
      String[] sw = vals.split(":");
      consoleAudio.randomBeep();
      if (sw[0].equals("9") ) {    //FIX ME - not this switch num

        OscMessage myMessage = new OscMessage("/control/grapplingHookState");
        myMessage.add(Integer.parseInt(sw[1]));
        oscP5.flush(myMessage, new NetAddress(serverIP, 12000));
      } else {

        String t = "NEWSWITCH:" + sw[0] + ":" + sw[1];
        consoleAudio.randomBeep();

        currentScreen.serialEvent(t);
      }
    } else if (vals.substring(0, 2).equals("PC")){//probe complete, unmute audio for buttons
       consoleAudio.muteBeeps = false;
    } else {
      //its a dial
      String t = "NEWDIAL:" + vals.substring(1, 2) + ":" + vals.substring(3);
      
      currentScreen.serialEvent(t);
    }
  } else {

    if (p == 'A' || p == 'B') { //values from the jamming knobs
      int v = Integer.parseInt(vals.substring(1, vals.length()));  
      String s = "JAM" + p + ":"+v;
      currentScreen.serialEvent(s);
    } else if (p == 'S') {
      int v = Integer.parseInt(vals.substring(1, vals.length()));  
      //println(v);
      if (v == 0) {
        consoleAudio.playClipForce("codeFail");
      } else if (v <= 5) {
        consoleAudio.playClipForce("beepLow");
      } else if (v <= 9) {
        consoleAudio.playClipForce("beepHigh");
      } else {
        consoleAudio.playClipForce("reactorReady");
      }
      if (v > 0) {  
        OscMessage myMessage = new OscMessage("/system/reactor/switchState");

        myMessage.add(v);
        oscP5.flush(myMessage, new NetAddress(serverIP, 12000));
      } else {
        OscMessage myMessage = new OscMessage("/system/reactor/setstate");
        myMessage.add(0);
        oscP5.flush(myMessage, new NetAddress(serverIP, 12000));
      }
    } else if ( p=='R') {
      OscMessage myMessage = new OscMessage("/system/reactor/setstate");
      myMessage.add(1);
      oscP5.flush(myMessage, new NetAddress(serverIP, 12000));
    } else if (p == 'p') {
      int v = Integer.parseInt(vals.substring(1, vals.length())) + 1;  
      String s = "KEY:"+v;
      consoleAudio.randomBeep();

      currentScreen.serialEvent(s);
    } else if (p=='L') {

      currentScreen.serialEvent("BUTTON:AIRLOCK");
    }
  }
}

//send a reset to all attached devices
void resetDevices() {
  if (!serialEnabled) {
    return;
  }
  serialPort.write('r');
}


/* switch to a new display */
void changeDisplay(Display d) {
  currentScreen.stop();
  currentScreen = d;
  currentScreen.start();
}

/* send a probe to engineer arduino panel to get the current state */
void probeEngPanel() {
  if (serialEnabled) {
    println("probng");
    panelPort.write('P');
    //mute the random beeps in console audio and only unmute when reeiving a probe complete message
    consoleAudio.muteBeeps = true;
  }
}

void oscEvent(OscMessage theOscMessage) {
  // println(theOscMessage);
  if (theOscMessage.checkAddrPattern("/system/reactor/stateUpdate")==true) {
    int state = theOscMessage.get(0).intValue();
    String flags = theOscMessage.get(1).stringValue();
    String[] fList = flags.split(";");
    //reset flags
    bootDisplay.brokenBoot = false;
    for (String f : fList) {
      if (f.equals("BROKENBOOT")) {
        println("BROKEN BOOT");
        bootDisplay.brokenBoot = true;
      }
    }

    if (state == 0) {
      shipState.poweredOn = false;
      shipState.poweringOn = false;
      bootDisplay.stop();
      bannerSystem.cancel();
      resetDevices();
    } else {


      if (!shipState.poweredOn ) {
        shipState.poweringOn = true;
        changeDisplay(bootDisplay);
      }
    }
  } else if (theOscMessage.checkAddrPattern("/scene/youaredead") == true) {
    //oh noes we died
    shipState.areWeDead = true;
    shipState.deathText = theOscMessage.get(0).stringValue();
    deathTime = millis();
    if (serialEnabled) {
      serialPort.write('k');
    }
  } else if (theOscMessage.checkAddrPattern("/game/reset") == true) {
    //reset the entire game
    if (serialEnabled) {
      serialPort.write('r');
    }
    changeDisplay(displayMap.get("power"));
    shipState.poweredOn = false;
    shipState.poweringOn = false;
    shipState.areWeDead = false;
    bootDisplay.stop();  
    println("reset");
    shipState.sillinessLevel = 0;
  } else if (theOscMessage.checkAddrPattern("/engineer/powerState") == true) {

    if (theOscMessage.get(0).intValue() == 1) {
      shipState.poweredOn = true;
      shipState.poweringOn = false;
      bootDisplay.stop();
    } else {
      shipState.poweredOn = false;
      shipState.poweringOn = false;
    }
  } else if (theOscMessage.checkAddrPattern("/ship/effect/heartbeat") == true) {
    heartBeatTimer = millis();
  } else if (theOscMessage.checkAddrPattern("/ship/damage")==true) {

    damageTimer = millis();
  } else if ( theOscMessage.checkAddrPattern("/clientscreen/EngineerStation/changeTo") ) {
    if (!shipState.poweredOn) { 
      return;
    }
    String changeTo = theOscMessage.get(0).stringValue();
    try {
      Display d = displayMap.get(changeTo);
      println("found display for : " + changeTo);
      changeDisplay(d);
    } 
    catch(Exception e) {
      println("no display found for " + changeTo);
      e.printStackTrace();
      changeDisplay(displayMap.get("power"));
    }
  } else if (theOscMessage.checkAddrPattern("/clientscreen/showBanner") ) {
    String title = theOscMessage.get(0).stringValue();
    String text = theOscMessage.get(1).stringValue();
    int duration = theOscMessage.get(2).intValue();

    bannerSystem.setSize(700, 300);
    bannerSystem.setTitle(title);
    bannerSystem.setText(text);
    bannerSystem.displayFor(duration);
  } else if (theOscMessage.checkAddrPattern("/system/boot/diskNumbers") ) {

    int[] disks = { 
      theOscMessage.get(0).intValue(), theOscMessage.get(1).intValue(), theOscMessage.get(2).intValue()
      };
      println(disks);
    bootDisplay.setDisks(disks);
  } else if (theOscMessage.addrPattern().startsWith("/system/powerManagement")) {
    powerDisplay.oscMessage(theOscMessage);
  } else if (theOscMessage.addrPattern().startsWith("/engineer/wormholeStatus/")) {

    wormholeDisplay.oscMessage(theOscMessage);
  } else if (theOscMessage.checkAddrPattern("/control/grapplingHookState")) {
  } else {

    currentScreen.oscMessage(theOscMessage);
  }
}

void mouseClicked() {
  println(mouseX + ":" + mouseY);
  //displayList[currentDisplay].serialEvent("connectok");
}


void hideCursor(){
  BufferedImage cursorImg = new BufferedImage(16, 16, BufferedImage.TYPE_INT_ARGB);
  Cursor blankCursor = Toolkit.getDefaultToolkit().createCustomCursor(
    cursorImg, new Point(0,0), "blank cursor");
    frame.setCursor(blankCursor);
  
}
public class ShipState {

  public int smartBombsLeft = 6;
  public boolean poweredOn = true;
  public boolean poweringOn = false ;
  public boolean areWeDead = false;
  public String deathText = "";

  public PVector shipPos = new PVector(0, 0, 0);
  public PVector shipRot = new PVector(0, 0, 0);
  public PVector shipVel = new PVector(0, 0, 0);

  public int sillinessLevel = 0;
  public boolean sillinessInProgress = false;
  public int[] powerLevels;

  public ShipState() {
  };

  public void resetState() {
  }
}


public interface Display {

  public void draw();
  public void oscMessage(OscMessage theOscMessage);
  public void start();
  public void stop();

  public void keyPressed();
  public void keyReleased();
  public void serialEvent(String evt);
}

