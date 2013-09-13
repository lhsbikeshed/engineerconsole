

public class DestructDisplay implements Display {
  
  PImage bgImage, criticalImg;
  int time;
  
  PFont font;
  
  int blinkTime = 0;
  boolean blinker = false;
  
  public DestructDisplay(){
    font = loadFont("HanzelExtendedNormal-48.vlw");
    bgImage = loadImage("destruct.png");
    criticalImg = loadImage("critical.png");
  }
  
  
  public void start(){
    time =60;
  }
  public void stop(){
    
  }
  
  public void draw(){
    if(blinkTime + 1000 < millis()){
      blinker = !blinker;
      blinkTime = millis();
    }
    background(0,0,0);
    image(bgImage, 0,0,width,height);
    if(blinker){
      image(criticalImg, 0, 90);
    }
    textFont(font, 50);
    
    fill(255,255,255);
    int x = 625 - (int)textWidth("" + time) / 2 ;
    text(time, x,440);
  }
  
  public void oscMessage(OscMessage msg){
    if(msg.checkAddrPattern("/system/reactor/overloadstate")){
      time = msg.get(0).intValue();
    }
  }

  public void serialEvent(String evt){}

  public void keyPressed(){}
  public void keyReleased(){}
}
