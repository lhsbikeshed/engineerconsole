public class HyperSpaceDisplay implements Display {

  //osc
  OscP5 p5;
  String serverIP = "";
  NetAddress  myRemoteLocation;



  //state things
  boolean haveFailed = false;    //have we failed/
  long failStart = 0;            //when fail started
  long failDelay = 0;

  float timeRemaining = 0;       //how long until exit
  int failsRemaining = 5;

  long nextFailTime = 5000;
  long lastFailTime = 0;
  int keypressesSinceFuckUp = 0;

  //assets
  PImage bgImage;
  PImage overlayImage;
  PImage warningBanner;

  //GUI crap
  PFont font;

  char[] charMap = {
    'a', 'f', 'k', 'p', 'b', 'q', 'c', 'r', 'd', 's', 'e', 'j', 'o', 't'
  };

  Emitter[] emitters = new Emitter[14];

  //text labels



  int[][] keyMapping = new int[20][2]; /*{   {97, 0, 0}, 
   {98, 1, 0},
   {99, 2, 0},
   {100, 3, 0},*/



  public HyperSpaceDisplay(OscP5 p5, String sIP) {
    this.p5 = p5;
    serverIP = sIP;
    myRemoteLocation  = new NetAddress(serverIP, 12000);

    //load assets
    bgImage = loadImage("hyperspace2.png");
    overlayImage = loadImage("hyperfailoverlay.png");
    font = loadFont("HanzelExtendedNormal-48.vlw");
    warningBanner = loadImage("warpWarning.png");
    int idCt = 0;
    for (int y = 0; y < 5; y++) {
      for (int x = 0; x < 4; x++) {

        if (y == 0 || y ==4) {
          Emitter e = new Emitter();
          e.pos = new PVector(334 + x * 67 + x * 29, 220 + y * 67 + y *27);
          e.size = new PVector(67, 67);
          e.id = idCt;
          e.keyChar = charMap[idCt];
          emitters[idCt] = e;
          idCt++;
        } 
        else {
          if (x == 0 || x ==3) {
            Emitter e = new Emitter();
            e.pos = new PVector(334 + x * 67 + x * 29, 220 + y * 67 + y *27);
            e.size = new PVector(67, 67);
            e.id = idCt;
            e.keyChar = charMap[idCt];
            emitters[idCt] = e;
            idCt++;
          }
        }
      }
    }
  }


  public void start() {
    haveFailed = false;
    failsRemaining = 5;
    for (Emitter e : emitters) {
      e.state = Emitter.STATE_OFF;
    }
    keypressesSinceFuckUp = 0;
  }
  
  
  public void stop() {
  }

  public void draw() {
    image(bgImage, 0, 0, width, height);
    if (haveFailed) {
      image(overlayImage, 40, 200);
    } 
    else {
      fill(255, 255, 0);
      textFont(font, 22);
      if (timeRemaining >0.0f) {

        text("Time Remaining: " + timeRemaining, 294, 700);
      } 
      else {
        text("EXITING HYPERSPACE", 294, 700);
      }

      text("Hyperspace Tunnel Health: " + (failsRemaining * 20) + "%", 149, 740);


      if (lastFailTime + nextFailTime < millis()) {
        lastFailTime = millis();
        nextFailTime =  (long)map(keypressesSinceFuckUp, 0, 5, 5000, 1000) + (long)random(500);
        int r = (int)random(14);
        emitters[r].state = Emitter.STATE_FAIL;
      }
      int deadCount = 0;
      for (Emitter e : emitters) {
        if (e.getState() == Emitter.STATE_FAIL) {
          deadCount ++;
        }
        e.draw();
        if(e.getState() == Emitter.STATE_OK){
          stroke(15,15,255);
          strokeWeight(4);
          line(515,437, e.pos.x + 35, e.pos.y + 35);
        }
      }

      if (deadCount > 5) {
        sendFailMessage();
        for (Emitter b : emitters) {
          b.state = Emitter.STATE_OFF;
        }
      } 
      if (deadCount >=3){
        image(warningBanner, 30, 218);
      }
    }
  }

  public void oscMessage(OscMessage theOscMessage) {

    if (theOscMessage.checkAddrPattern("/scene/warp/updatestats")==true) {
      timeRemaining = (int)theOscMessage.get(1).floatValue();
      failsRemaining = (int)theOscMessage.get(0).floatValue();
    }
    else if (theOscMessage.checkAddrPattern("/scene/warp/failjump") == true) {
      haveFailed = true;
      failStart = millis();
      failDelay = theOscMessage.get(0).intValue() * 1000;
    }
  }

  private void sendOkMessage() {
    OscMessage myMessage = new OscMessage("/scene/warp/warpkeepalive");

    p5.flush(myMessage, myRemoteLocation);
  }
  private void sendFailMessage() {
    OscMessage myMessage = new OscMessage("/scene/warp/warpfail");
    p5.flush(myMessage, myRemoteLocation);
    
    keypressesSinceFuckUp = 0;
  }

  public void keyPressed() {
  }
  public void keyReleased() {
  }
  public void serialEvent(String evt) {
    String[] va = evt.split(":");
    println(evt);
    if (va[0].equals("KEY")) {

      char c2 = va[1].charAt(0); 
      if (c2 >= 'a' && c2 <= 't') {
        for (Emitter e : emitters) {
          if (e.keyChar == c2 ) {
            if (e.getState() == Emitter.STATE_FAIL) {
              e.setState (Emitter.STATE_OK);
              keypressesSinceFuckUp++;
              if (keypressesSinceFuckUp > 5) {
                keypressesSinceFuckUp = 5;
              }
            } 
            else {
              for (Emitter b : emitters) {
                b.state = Emitter.STATE_OFF;
              }
              e.setState(Emitter.STATE_WRONG);
              keypressesSinceFuckUp = 0;
              sendFailMessage();
              return;
            }
          }
        }
      }
    }
  }

  protected class Emitter {
    PVector pos;
    PVector size;
    public int id = 0;
    public char keyChar;
    
    public static final int STATE_OFF = 0;
    public static final int STATE_FAIL = 1;
    public static final int STATE_WRONG = 2;
    public static final int STATE_OK = 3;
    private long timerStart = 0;
    private int state = STATE_OFF;
    
    public void setState(int state){
      this.state = state;
      if(state == STATE_WRONG || state == STATE_OK){
        timerStart = millis();
      }
    }
    
    public int getState(){
      return state;
    }
    
    public Emitter() {
    }


    public void draw() {
      if (state == STATE_FAIL) {
        if (globalBlinker) {
          fill(0, 0, 255, 150);
        } 
        else {
          fill(0, 0, 128, 150);
        }
        rect(pos.x, pos.y, size.x, size.y);
      } else if (state == STATE_WRONG) {
      
        fill(255, 0, 0, 150);
       
        if(timerStart + 750 < millis()){
          state = STATE_OFF;
        }
        rect(pos.x, pos.y, size.x, size.y);
      } else if (state == STATE_OK) {
      
        fill(0, 255, 0, 150);
       
        if(timerStart + 750 < millis()){
          state = STATE_OFF;
        }
        rect(pos.x, pos.y, size.x, size.y);
      }
    }
  }
}


