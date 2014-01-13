
public class DropDisplay implements Display{

  OscP5 p5;
  
  
  PImage instructionImage, patchImage, authImage, jumpOverlayImage, jumpEnableOverlay, dropFailOverlay;
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
  String[] possibleAuthCodes = {"12345", "62918", "26192"};
  
  float chargePercent = 0;
  String serverIP = "";
  
  int curPatch = -1; 
  
  long failTimer = 0;
  boolean failed = false;
  long sceneStartTime = 0;
  String authCode = "";
  boolean authResult = false;
  long authDisplayTime = 0;
  
  public DropDisplay(OscP5 p5, String sIP){
    this.p5 = p5;
    serverIP = sIP;
    instructionImage = loadImage("dropscene1.png");
    patchImage = loadImage("dropscene1.png");
    authImage = loadImage("dropscene3.png");
    jumpOverlayImage = loadImage("emergencyjump.png");
    jumpEnableOverlay = loadImage("jumpEnableOverlay.png");
    structFailOverlay = loadImage("structuralFailure.png");
    dropFailOverlay = loadImage("dropFailOverlay.png");

    font =  loadFont("HanzelExtendedNormal-48.vlw");
    
  }
  
  
  public void draw(){
    if(state == STATE_INST){
      image(instructionImage,0,0, width, height);
      
        state = STATE_PATCHING;
      
    } else if (state == STATE_PATCHING){
      image(patchImage,0,0, width, height);
      fill(0,255,0);
      textFont(font,20);
      if(curPatch != -1){
        
        /*
        203:581
        269:631
        326:582
        393:633
        width = 66, height=50
        stepx = 57
        */
        int baseX = 203;
        for(int i = 0; i < curPatch; i++){
          //text("Done", 230,335   + i * 30);
          fill(0,255,0);
          rect( baseX + i * 66, 580, 66, 52);
          baseX += 59; 
        }
      }
      
      if(failed){
        image(dropFailOverlay, 97, 471);
      }
      
    } else if (state == STATE_AUTH || state == STATE_CODEOK){
      fill(255,255,255);
      image(authImage,0,0, width, height);
      textFont(font,20);
      text(authCode + "_", 266,445);
      
      if(authDisplayTime + 1500 > millis()){
        if(authResult == false){
          fill(255,0,0);
          textFont(font,40);
          text("CODE FAIL", 266,573);
        } else {
          fill(0,255,0);
          textFont(font,40);
          text("CODE OK", 266,573);
          
          
        }
      } else if (authDisplayTime +2500 > millis() && authResult == true){
        state = STATE_CODEOK;
      } 
       
      if(state == STATE_CODEOK){
        //show an overlay that the jump engine is on and charging
        image(jumpOverlayImage, 64,320);
        rect(125,469, map(chargePercent, 0, 1.0f, 0,480), 48);
        if(chargePercent >= 1.0f){
          image(jumpEnableOverlay, 173,237);
        }
      }
    }
    
    if (structFail) { //show the "structural failure" warning

      image(structFailOverlay, 128, 200);
    }
      
    
  }
  
  public void oscMessage(OscMessage theOscMessage){
    if (theOscMessage.checkAddrPattern("/ship/stats")==true) {
      chargePercent = theOscMessage.get(0).floatValue();
    }
    if (theOscMessage.checkAddrPattern("/scene/drop/panelRepaired")==true) {
      
        state = STATE_AUTH;
      
    } else if (theOscMessage.checkAddrPattern("/scene/drop/conduit")==true) {
      
      curPatch = theOscMessage.get(0).intValue() + 1;
      if(curPatch == 1){
        failed = false;
      }
      println(curPatch);
    } else if (theOscMessage.checkAddrPattern("/scene/drop/conduitFail")==true) {
      curPatch = -1;
      failed = true;
      failTimer = millis();
    } else if (theOscMessage.checkAddrPattern("/scene/drop/structuralFailure")==true) {
      structFail = true;
    }
      
  }
  
  
  public void start(){
    structFail = false;
    currentAuthCode = "62918"; //possibleAuthCodes[(int)random(3)];
    
     chargePercent = 0;
    sceneStartTime = millis();
     authCode = "";
     authResult = false;
     authDisplayTime = 0; //start for auth fail/ok display time
     state = STATE_INST;
     curPatch = -1;
  }
  
  
  public void stop(){
    chargePercent = 0;
    sceneStartTime = millis();
       authCode = "";
       authResult = false;
       authDisplayTime = 0; //start for auth fail/ok display timesplay time
  }
    public void serialEvent(String evt){
      if(state == STATE_PATCHING){
        if(evt.equals("connectok") ){
          //we received an ok from the panel hardware
          //tell the main game that the test passed
          //OscMessage myMessage = new OscMessage("/scene/droppanelrepaired");
         // myMessage.add(1);
          //p5.flush(myMessage, new NetAddress(serverIP, 12000));
          state = STATE_AUTH;
        }
      } else if (state == STATE_AUTH ){
        if(evt.length() == 1){
          if(authCode.length() < 4){
            authCode += evt;
          } else {
            authCode += evt;
            if(authCode.equals(currentAuthCode)){
              authResult = true;
              consoleAudio.playClip("codeOk");
              //tell the main game that auth passed
              OscMessage myMessage = new OscMessage("/scene/drop/droppanelrepaired");
              myMessage.add(2);
              p5.flush(myMessage, new NetAddress(serverIP, 12000));
              
            } else {
              authResult = false;
              consoleAudio.playClip("codeFail");
              authCode = "";
            }
            
            authDisplayTime = millis();
          }
          
          
        }
        
      }
      
      
    }
    
    

  public void keyPressed(){}
  public void keyReleased(){
    serialEvent("" + key);
  }
}
