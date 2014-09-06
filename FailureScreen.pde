
public class FailureScreen implements Display {

  PImage background;
  PImage warningImage;
  PImage leftIcon, rightIcon;
  
  int animTime = 0;
  float leftIconPos = 309f;
  float rightIconPos = 435f;
  
  public FailureScreen(){
    background = loadImage("failure/bg.png");
    warningImage = loadImage("failure/warning.png");
    
    leftIcon = loadImage("failure/leftPart.png");
    rightIcon = loadImage("failure/rightPart.png");
  }
  
  public void start(){
    animTime = 0;
    consoleAudio.playClip("structuralFailure");
  }
  public void stop(){}
  
  public void draw(){
    image(background,0,0,width,height);
    animTime++;
    leftIconPos-=0.2f;
    rightIconPos+=0.2f;
    
    
    pushMatrix();    
    translate(leftIconPos + leftIcon.width, 328 + 328);
    rotate(radians(-animTime / 10.0f));
    image(leftIcon, -leftIcon.width, -328);
    popMatrix();
    
    pushMatrix();    
    translate(rightIconPos + 10, 229 + 229);
    rotate(radians(animTime / 10.0f));
    image(rightIcon, -10, -229);
    popMatrix();
    
    for(int i = 0; i < 5; i++){
      if(random(10) > 7){
        fill(220 + random(40),204,0);
        float rad = 50 + random(50);
        ellipse(435 + random(40), 350 + random(100), rad, rad);
      }
    }
      
  
  
  
    if(globalBlinker){
      image(warningImage,44, 28);
    }
  }
  public void oscMessage(OscMessage theOscMessage){}
 
  public void serialEvent(String content){}
  public void keyPressed() {
  }
  public void keyReleased() {
    
  }
}
  
