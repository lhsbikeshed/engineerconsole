

public class PwnedDisplay implements Display {
  
  PImage bgImage,mouthImage;
 
  PFont font;
  
  public PwnedDisplay(){
    font = loadFont("HanzelExtendedNormal-48.vlw");
    bgImage = loadImage("pwnedbg.png");
    mouthImage = loadImage("pwnedmouth.png");
    
  }
  
  
  public void start(){
  
  }
  public void stop(){
   
  }
  

  public void draw(){
    //image(bgImage, 0,0,width,height);
    background(0,0,0);
    image(bgImage,0,0,width,height);
    int y = 490 + (int)map(sin(millis()), -1,1, 0,20);
    image(mouthImage, 432, y);
    
  }
  
  public void oscMessage(OscMessage theOscMessage){
   
  }

  public void serialEvent(String evt){}

  public void keyPressed(){}
  public void keyReleased(){}
}
