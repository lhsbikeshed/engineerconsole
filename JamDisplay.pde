
public class JamDisplay implements Display {

  OscP5 p5;
  String serverIP = "";
  NetAddress  myRemoteLocation;


  //assets
  PImage bgImage;
  PImage intruderOverlay;
  PImage jammingOverlay;

  //game data
  int STATE_SCAN = 0;
  int STATE_PLAYING = 1;
  int STATE_FAIL = 2;
  int STATE_OK = 3;

  int[][] graphData = new int[2][10]; //live graph data (drawn to screen)
  int[][] targetData = new int[2][10]; //where we are moving the graph bars too
  int[][] prevData = new int[2][10]; //bar position at point of changing the targets
  int[] target = new int[2]; // the target frequencies
  int gameState = STATE_SCAN;
  int scanStart = -5000;
  int playStart = -5000;
  int failStart = -2000;
  int lastChangeTime = 0;
  int newValueTime = 0; //time that we created new values for the graph, used to smoothly change the graph
  int attempts = 3;

  int dialA = 0;
  int dialB = 0;
  boolean jamAttempt = false;
  boolean jamSuccess = false;  //
  int jamTimer = 0;
  boolean jamMessageDone = false;

  public JamDisplay(OscP5 p5, String sIP) {

    this.p5 = p5;
    serverIP = sIP;
    myRemoteLocation  = new NetAddress(serverIP, 12000);
    bgImage = loadImage("jammingscreen.png");
    intruderOverlay = loadImage("intruderoverlay.png");
    jammingOverlay = loadImage("jammingoverlay.png");
    for (int i = 0; i < 10; i++ ) {

      prevData[0][i] = 0;
      prevData[1][i] = 0;
    }
    resetPuzzle();
    scanStart = millis();
  }

  public void resetPuzzle() {

    newValues();
    scanStart = -5000;
    playStart = -5000;
    failStart = -2000;
    gameState = STATE_SCAN;
    jamMessageDone = false;
    jamSuccess = false;
  }

  public void newValues() {
    target[0] = (int)random(10);//(int)random(10);    
    target[1] = (int)random(10);

    for (int i = 0; i < 10; i++ ) {
      prevData[0][i] = targetData[0][i];
      prevData[1][i] = targetData[1][i];
      targetData[0][i] = 150 - (abs(target[0] - i)) * 15;
      targetData[1][i] = 150 - (abs(target[1] - i)) * 15;
    }
    newValueTime = millis();
  }

  public void start() {

    resetPuzzle();
  }
  public void stop() {
    consoleAudio.setToneState(false);
  }

  public void draw() {
    //dialA =(int) map(mouseX, 0, width, 0, 12);
    //dialB = (int) map(mouseY, 0, height, 0, 12);


    image(bgImage, 0, 0, width, height);
    textFont(font, 20);
    // text("test " + mouseX + ":" + mouseY, mouseX, mouseY);

    if (gameState == STATE_SCAN) {
      if (scanStart + 5000 < millis()) {
        gameState = STATE_PLAYING;
        playStart = millis();
        consoleAudio.setToneState(true);
      } 
      else {
        textFont(font, 30);
        text("Scanning frequencies..", 460, 355);
      }
    } 
    else if (gameState == STATE_PLAYING) {
      if (lastChangeTime + 4500 < millis()) {
        newValues();
        lastChangeTime = millis();
      }

      consoleAudio.setToneValue(  map(dialA, 0, 12, 150, 220), map(dialB, 0, 12, 0.1, 15));



      if (playStart + 35000 < millis()) {
        //failed, beam aboard
        gameState = STATE_FAIL;
        consoleAudio.setToneState(false);

        failStart = millis();
        //also sent a failure OSC message
        OscMessage msg = new OscMessage("/system/jammer/jamresult");
        msg.add(0);
        p5.flush(msg, myRemoteLocation);
      }
      //draw the graphs


      textFont(font, 10);
      for (int i = 0; i < 10; i++) {
        int graphHeightA = 0;
        int graphHeightB = 0;

        if (!jamAttempt) {

          if (newValueTime + 1000 > millis()) {
            graphData[0][i] = -(int)lerp(prevData[0][i], targetData[0][i], map(millis() - newValueTime, 0, 1000, 0, 1.0));
            graphData[1][i] = -(int)lerp(prevData[1][i], targetData[1][i], map(millis() - newValueTime, 0, 1000, 0, 1.0));

            graphHeightA = graphData[0][i] + (int)map(sin((millis() + i*100) / 100.0f), -1.0, 1.0, -3.0, 3.0);
            graphHeightB = graphData[1][i] + (int)map(sin((millis() + i*100) / 100.0f), -1.0, 1.0, -3.0, 3.0);
          } 
          else {

            graphHeightA = -targetData[0][i] + (int)map(sin((millis() + i*100) / 100.0f), -1.0, 1.0, -3.0, 3.0);
            graphHeightB = -targetData[1][i] + (int)map(sin((millis() + i*100) / 100.0f), -1.0, 1.0, -3.0, 3.0);
          }
        } 
        else {
          graphHeightA = -(int)random(150);
          graphHeightB = -(int)random(150);
        }
        fill(0, 255, 0);
        text(i + 1, 340 + 60 * i, 430);
        if (dialA - 1 == i) {
          fill(0, 255, 255);
        }
        rect(330 + 60 * i, 415, 40, graphHeightA);

        fill(0, 255, 0);
        text(i + 1, 340 + 60 * i, 655);
        if (dialB - 1 == i) {
          fill(0, 255, 255);
        }
        rect(330 + 60 * i, 640, 40, graphHeightB);
      }

      fill(0, 255, 0);
      textFont(font, 35);
      text(dialA - 1, 124, 390);
      text(dialB - 1, 124, 600);


      if (jamAttempt) {
        //overlay
        fill(0, 0, 0, 128);
        rect(0, 0, width, height);
        image(jammingOverlay, 167, 251);
        jamTimer --;
        if (jamTimer <= 0) {
          jamAttempt = false;
          consoleAudio.setToneState(true);

          if (jamSuccess) {
            //skip out were done here

            //parent.changeDisplay(0);
          }
        }
        if (jamTimer < 60) {


          //show the success/failure message
          if (jamSuccess) {
            textFont(font, 45);
            fill(0, 255, 0);
            text("SUCCESS", 439, 426);
            if (!jamMessageDone) {
              consoleAudio.playClip("codeOk");
              OscMessage msg = new OscMessage("/system/jammer/jamresult");
              msg.add(1);
              p5.flush(msg, myRemoteLocation);
              jamMessageDone = true;
              // consoleAudio.setToneState(true);
            }
          } 
          else {
            if (!jamMessageDone) {
              consoleAudio.playClip("codeFail");
              jamMessageDone = true;
            }
            textFont(font, 45);
            fill(255, 0, 0);
            text("FAILED", 439, 426);
          }
        }
      }
    } 
    else if (gameState == STATE_FAIL) {
      fill(0, 0, 0, 128);
      rect(0, 0, width, height);
      consoleAudio.setToneState(false);

      if (failStart + 2000 > millis()) {

        image(intruderOverlay, 170, 250);
      } 
      else {
        //switch the display to the airlock subdisplay
        // parent.changeDisplay(2);
      }
    }
  }

  public void oscMessage(OscMessage theOscMessage) {
  }
  public void keyPressed() {
  }
  public void keyReleased() {
  }
  public void serialEvent(String evt) {
    if (evt.equals("boobs")) {
      jamAttempt = true;
      jamTimer = 120;
      jamSuccess = true;
    }
    String[] v = evt.split(":");
    if (v.length < 2) {
      return;
    }
    println(v[1]);

    if (v[0].equals("JAMA")) {
      dialA = Integer.parseInt(v[1]);
      println(dialA);
    } 
    else if (v[0].equals("JAMB")) {
      dialB = Integer.parseInt(v[1]);
    } 
    else if (v[0].equals("KEY")) {
      if (v[1].equals(";")) {
        jamAttempt();
        }
      } 
    else if (evt.equals("NEWSWITCH:11:1")) {
      jamAttempt();
    }
  }
  public void jamAttempt() {
    jamAttempt = true;
    jamMessageDone = false;

    consoleAudio.setToneState(false);
    consoleAudio.playClip("jamattempt");

    jamTimer = 120;
    if (dialA - 1 == target[0] && dialB - 1 == target[1]) {
      jamSuccess = true;
    } 
    else {
      jamSuccess = false;
    }
  }
}

