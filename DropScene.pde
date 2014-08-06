
public class DropDisplay implements Display {

  OscP5 p5;

  //assets
  PImage instructionImage, patchImage, authImage, jumpOverlayImage, jumpEnableOverlay, dropFailOverlay, plugImage;
  PFont font;
  PImage structFailOverlay;

  boolean structFail = false;


  public  int STATE_INST = 0;
  public  int STATE_PATCHING = 1;
  public  int STATE_AUTH = 2;
  public  int STATE_CODEOK = 3;
  int state = STATE_INST;

  String currentAuthCode = "62918";
  //12345, 62918, 26192
  String[] possibleAuthCodes = {
    "12345", "62918", "26192"
  };

  float chargePercent = 0;
  String serverIP = "";

  int curPatch = -1; 

  long failTimer = 0;

  long sceneStartTime = 0;
  String authCode = "";
  boolean authResult = false;
  long authDisplayTime = 0;


  //patch panel state
  int[] cableOrder = {
    0, 1, 2, 3, 4
  };
  //cable pins -> colour map
  // yellow = 0
  // black = 1
  // white = 2
  // blue = 3
  // red = 4
  int[] colorMap = new int[5];

  int currentCable = 0;
  boolean[] cableState = new boolean[5];

  boolean showFailure = false;  //show a failure message on screen?

  public DropDisplay(OscP5 p5, String sIP) {
    this.p5 = p5;
    serverIP = sIP;
    instructionImage = loadImage("dropnew.png");
    patchImage = loadImage("dropnew.png");
    authImage = loadImage("dropscene3.png");
    jumpOverlayImage = loadImage("emergencyjump.png");
    jumpEnableOverlay = loadImage("jumpEnableOverlay.png");
    structFailOverlay = loadImage("structuralFailure.png");
    dropFailOverlay = loadImage("dropFailOverlay.png");
    plugImage = loadImage("dropPlugs.png");
    font =  loadFont("HanzelExtendedNormal-48.vlw");

    //setup colours for plugs
    colorMap[0] = color(255, 255, 0);
    colorMap[1] = color(0, 0, 0);
    colorMap[2] = color(255, 255, 255);
    colorMap[3] = color(0, 0, 255);
    colorMap[4] = color(255, 0, 0);
  }


  public void draw() {
    if (state == STATE_INST) {
      image(instructionImage, 0, 0, width, height);

      state = STATE_PATCHING;
    } 
    else if (state == STATE_PATCHING) {
      image(patchImage, 0, 0, width, height);
      fill(0, 255, 0);
      textFont(font, 20);
      noStroke();
      for (int i = 0; i < 5; i ++) {
        //draw the plug colour
        fill(colorMap[ cableOrder[i] ]);
        rect(350, 300 + 88 * i, 85, 62);
        rect(614, 300 + 88 * i, 85, 62);
  
        //and now mask it with cleverness
        image (plugImage, 350, 299 + 88 * i);
        
        //and connection state
        if (i < currentCable) {
          if(cableState[cableOrder[i]] == true){
            fill(0, 255, 0);        //connected and correct
          } else {
            fill(250, 0, 0);        //connected and wrong
          }
        } 
        else {
          if(i == currentCable){
              int c = (int)map(sin(millis() / 100.0f), -1.0f, 1.0f, 0, 255);  
            fill(c,c,0);
          } else {
            fill(120, 0, 0);          //not connected
          }
        }
        rect(438, 301 + 88 * i, 174, 62);
      }


      if (showFailure) {
        image(dropFailOverlay, 97, 471);
      }
    } 
    else if (state == STATE_AUTH || state == STATE_CODEOK) {
      fill(255, 255, 255);
      image(authImage, 0, 0, width, height);
      textFont(font, 20);
      text(authCode + "_", 266, 445);

      if (authDisplayTime + 1500 > millis()) {
        if (authResult == false) {
          fill(255, 0, 0);
          textFont(font, 40);
          text("CODE FAIL", 266, 573);
        } 
        else {
          fill(0, 255, 0);
          textFont(font, 40);
          text("CODE OK", 266, 573);
        }
      } 
      else if (authDisplayTime +2500 > millis() && authResult == true) {
        state = STATE_CODEOK;
      } 

      if (state == STATE_CODEOK) {
        //show an overlay that the jump engine is on and charging
        image(jumpOverlayImage, 64, 320);
        rect(125, 469, map(chargePercent, 0, 1.0f, 0, 480), 48);
        if (chargePercent >= 1.0f) {
          image(jumpEnableOverlay, 173, 237);
        }
      }
    }

    if (structFail) { //show the "structural failure" warning

      image(structFailOverlay, 128, 200);
    }
  }

  /* cable was connected, check to see if its the next one in the list
   * if so then prepare for next one in list
   * if not then set showFailure to true and stop paying attention to new connects
   */
  private void cableConnected(int ind) {
    if (ind >= 0 && ind < 5) {
      if (cableState[ind] == true) {  //ignore repeated connection events
        return;
      }
      cableState[ind] = true;
      consoleAudio.playClip("beepHigh");
    }
    if (cableOrder[currentCable] == ind) {
      //yay! a good connection

      if (currentCable < 4) {
        currentCable ++;
        println("Current cable:" + currentCable);
      } 
      else {
        //we're done here, show the auth screen
        state = STATE_AUTH;
        consoleAudio.playClip("codeOk");
      }
    } 
    else {
      //wrong cable matey!
      showFailure = true;
      consoleAudio.playClip("codeFail");
    }
  }

  /* cable was unplugged, if all cables are disconnected then turn the failure off */
  private void cableDisconnected(int ind) {
    if (ind >= 0 && ind < 5) {
      if (cableState[ind] == false) {  //ignore repeated disconnection events
        return;
      }
      cableState[ind] = false;
      if(!showFailure){  //generally a disconnected cable will cause a failure
        showFailure = true;
        consoleAudio.playClip("codeFail");
      }
    }
    //check to see if all cables are disconnected now
    boolean allClear = true;
    for (int i = 0; i < 5; i++) {
      if (cableState[i] == true) {
        allClear = false;
      }
    }

    if (allClear) {
      showFailure = false;
      currentCable = 0;
    }
  }

  public void oscMessage(OscMessage theOscMessage) {
    if (theOscMessage.checkAddrPattern("/ship/stats")==true) {
      chargePercent = theOscMessage.get(0).floatValue();
    }
    if (theOscMessage.checkAddrPattern("/scene/drop/panelRepaired")==true) {

      state = STATE_AUTH;
    } 
    else if (theOscMessage.checkAddrPattern("/scene/drop/conduitConnect")==true) {      
      int val = theOscMessage.get(0).intValue();
      cableConnected(val);
    } 
    else if (theOscMessage.checkAddrPattern("/scene/drop/conduitDisconnect")==true) {      
      int val = theOscMessage.get(0).intValue();
      cableDisconnected(val);
      //println(curPatch);
    } 
    else if (theOscMessage.checkAddrPattern("/scene/drop/conduitFail")==true) {
      curPatch = -1;
      showFailure = true;
      failTimer = millis();
      consoleAudio.playClip("codeFail");
    } 
    else if (theOscMessage.checkAddrPattern("/scene/drop/structuralFailure")==true) {
      structFail = true;
    }
  }


  public void start() {
    structFail = false;
    currentAuthCode = possibleAuthCodes[1];

    chargePercent = 0;
    sceneStartTime = millis();
    authCode = "";
    authResult = false;
    authDisplayTime = 0; //start for auth fail/ok display time
    state = STATE_INST;
    curPatch = -1;
    currentCable = 0;
    showFailure = false;

    //randomise the order
    for (int i = 4; i > 0; i--) {
      int rand = floor(random(i+1));
      if (rand != i) {
        int t = cableOrder[i];
        cableOrder[i] = cableOrder[rand];
        cableOrder[rand] = t;
      }
    }
  }


  public void stop() {
    chargePercent = 0;
    sceneStartTime = millis();
    authCode = "";
    authResult = false;
    authDisplayTime = 0; //start for auth fail/ok display timesplay time
  }
  public void serialEvent(String evt) {
    if (state == STATE_PATCHING) {
      if (evt.equals("connectok") ) {
        //we received an ok from the panel hardware
        //tell the main game that the test passed
        //OscMessage myMessage = new OscMessage("/scene/droppanelrepaired");
        // myMessage.add(1);
        //p5.flush(myMessage, new NetAddress(serverIP, 12000));
        state = STATE_AUTH;
      }
    } 
    else if (state == STATE_AUTH ) {
      if (evt.length() == 1) {
        if (authCode.length() < 4) {
          authCode += evt;
        } 
        else {
          authCode += evt;
          if (authCode.equals(currentAuthCode)) {
            authResult = true;
            consoleAudio.playClip("codeOk");
            //tell the main game that auth passed
            OscMessage myMessage = new OscMessage("/scene/drop/droppanelrepaired");
            myMessage.add(2);
            p5.flush(myMessage, new NetAddress(serverIP, 12000));
          } 
          else {
            authResult = false;
            consoleAudio.playClip("codeFail");
            authCode = "";
          }

          authDisplayTime = millis();
        }
      }
    }
  }



  public void keyPressed() {
  }
  public void keyReleased() {
    serialEvent("" + key);
  }
}

