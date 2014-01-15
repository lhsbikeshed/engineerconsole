public class AirlockDisplay implements Display {

  //failure text @ 315:544
  /* 
   325:396
   473:391
   620:391
   768:389
   */

  PImage bgImage;
  PImage dumpOverlay;
  PImage failedDumpOverlay;

  OscP5 p5;
  String serverIP = "";
  NetAddress  myRemoteLocation;



  
  int[] possibleAuthCodes = {12345, 62918, 26192};

  //game state
  boolean locked = true;
  boolean failedCode = false;
  boolean greatSuccess = false;
  boolean doneSuccessMessage = false;
  String stateText = "DOOR LOCKED";
  int failTime = 0;
  int successTime = 0;
  int codePtr = 0;
  int[] codeAttempt = new int[5];

  int doorCode = 12345;
  long puzzleStartTime = 0;
  boolean totalFailure = false;




  public AirlockDisplay(OscP5 op5, String sIP) {
    this.p5 = op5;
    serverIP = sIP;
    myRemoteLocation  = new NetAddress(sIP, 12000);
    bgImage = loadImage("airlockscreen.png");
    dumpOverlay = loadImage("airlockoverlay.png");
    failedDumpOverlay = loadImage("airlockFailedOverlay.png");
    for (int i = 0; i < 5; i++) { 
      codeAttempt[i] = 0;
    }
  }


  public void start() {
    puzzleStartTime = millis();
    failedCode = false;
    totalFailure = false;
    locked = true;
    codePtr = 0;
    greatSuccess = false;
    successTime = 0;
    doneSuccessMessage = false;
    stateText = "DOOR LOCKED";
    for (int i = 0; i < 5; i++) { 
      codeAttempt[i] = 0;
    }
    doorCode = possibleAuthCodes[(int)random(3)];
    
  }
  public void stop() {
  }

  public void draw() {
    image(bgImage, 0, 0, width, height);

    textFont(font, 50);
    for (int i = 0; i < codePtr; i++) {
      fill(0, 255, 0);
      text(codeAttempt[i], 170 + i*150, 390);
    }

    textFont(font, 50);
    if (locked) {
      fill(255, 0, 0);
    } 
    else {
      fill(0, 255, 0);
    }
    text(stateText, 207, 544);

    if (failedCode) {
      if (failTime + 1500 < millis()) {
        failedCode = false;
        codePtr = 0;
        stateText = "DOOR LOCKED";
      }
    }

    if (locked == false) {
      image(dumpOverlay, 160, 232);
    }
    
    if(puzzleStartTime + 25000 < millis() && !greatSuccess){
      //we failed, show that the intruder has disabled the airlock dump
      image(failedDumpOverlay, 160,232);
      if(totalFailure == false){
        totalFailure = true;
        OscMessage msg = new OscMessage("/system/transporter/beamAttemptResult");
        msg.add(2);
        p5.send(msg, myRemoteLocation);
      }
    }
    
    if(greatSuccess){
      if(!doneSuccessMessage){
        //OscMessage msg = new OscMessage("/system/transporter/beamAttemptResult");
        //msg.add(3);
        //p5.send(msg, myRemoteLocation);
        println("Change");
        doneSuccessMessage = true;
        //turn off airlock dump light
        setAirlockLightState(false);
      }
        
   
    }
    
    
  }
  
  void setAirlockLightState(boolean state){
    println("setting airlock light to : " + state);
    OscMessage msg = new OscMessage("/system/effect/airlockLight");
    msg.add(state == true ? 1 : 0);
    //p5.send(msg, myRemoteLocation);
  }

  public void oscMessage(OscMessage theOscMessage) {
  }
  
  public void keyEntered(int k){
    
    if (locked) {
      if (codePtr < 4) {
        if (failedCode == false) {
          codeAttempt[codePtr] = k - 48;
          codePtr++;
        }
      } 
      else {
        if (failedCode == false) {

          codeAttempt[codePtr] = k - 48;
          codePtr++;
        }

        //check the code
        int testCode = codeAttempt[0] * 10000 +
          codeAttempt[1] * 1000 +
          codeAttempt[2] * 100 +   
          codeAttempt[3] * 10 + 
          codeAttempt[4];


        if (testCode == doorCode) {
          failedCode = false;
          locked = false;
          stateText = "CODE OK";
          //turn on the airlock dump light
          setAirlockLightState(true);
          consoleAudio.playClip("codeOk");
        } 
        else {      
          failedCode = true;
          stateText = "CODE FAILED";
          failTime = millis();
          //turn off airlock dump light
          setAirlockLightState(false);
          consoleAudio.playClip("codeFail");
        }
      }
    }
  }
  public void keyPressed() {


  }
  public void keyReleased() {
  }
  public void serialEvent(String evt) {
    String[] evtData = evt.split(":");
   
    if(evtData[0].equals("KEY")){
      if(evtData[1].length() == 1){
        char c = evtData[1].charAt(0);
        if( c >= '0' && c <= '9'){
          keyEntered(c);
        }
      }
    }
    
    if(evtData[0].equals("BUTTON")){
      if(evtData[1].equals("AIRLOCK") && locked == false){
        greatSuccess = true;
        successTime = millis();
        if(!doneSuccessMessage){
          println("send message");
          OscMessage msg = new OscMessage("/system/transporter/beamAttemptResult");
          msg.add(3);
          oscP5.send(msg, myRemoteLocation);
          consoleAudio.playClip("airlockDump", -1.0f);
          
        }
      }
    }
    
    
    
    
  }
}

