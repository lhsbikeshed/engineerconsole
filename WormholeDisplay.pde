
/* display some info about the wormhole
 * such as "stay outside 300m when it opens"
 * charge level
 * opening or closing
 */
public class WormholeDisplay implements Display {
  
  PImage bgImage;
  
  PFont font;
  
  public WormholeDisplay(){
    font = loadFont("FixedsysTTF-48.vlw");
   // bgImage = loadImage("bootlogo.png");
  }

  
  
  public void start(){

  }
  public void stop(){
   
  }
 
  public void draw(){
    //image(bgImage, 0,0,width,height);
    background(0,0,0);
   
    
  }
  
  public void oscMessage(OscMessage theOscMessage){
   
  }

  public void serialEvent(String evt){}

  public void keyPressed(){}
  public void keyReleased(){}
}
