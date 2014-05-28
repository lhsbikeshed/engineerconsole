
/* load a sprite sheet and given widths/heights of frames and number of frames in each dimension, load them
 * as individual frames and draw them*/


public class Sprite {
  
  public int xPos = 0;
  public int yPos = 0;
  public int drawWidth, drawHeight;
  
  PImage spriteSheet;
  public int frameSpeed = 2;
  
  int frameTime = 0;
  int currentFrame = 0;
  int maxFrames = 0;
  int frameW, frameH;
  PImage[] frames;
  
  public int xCentre = 0;
  public int yCentre = 0;
  
  public Sprite(PImage sheet, int w, int h, int numFramesX, int numFramesY){
    frameW = w;
    frameH = h;
    maxFrames = numFramesX * numFramesY;
    
    frames = new PImage[maxFrames];
    for(int xp = 0; xp < numFramesX; xp++){
      for(int yp = 0; yp < numFramesY; yp++){
        int fNum = xp + yp * numFramesX;
        frames[fNum] = createImage(frameW, frameH,ARGB);
        frames[fNum].copy(sheet, xp * frameW, yp * frameH, frameW, frameH,  0, 0, frameW, frameH);
      }
    }
    drawWidth = frameW;
    drawHeight = frameH;
  }
  
  public void update(){
    frameTime -= 1;
    if(frameTime < 0){
      currentFrame++;
      currentFrame %= maxFrames;
      frameTime = frameSpeed;
     
    }
    
  }
  
  public void draw(){
    draw(xPos, yPos);
  }
  
  public void draw(int x, int y){
    image(frames[currentFrame], x - xCentre, y - yCentre, drawWidth, drawHeight);
  }
  public void draw(int x, int y, int w, int h){
    image(frames[currentFrame], x - xCentre, y - yCentre, w, h);
  }
  
  public void draw(int x, int y, int w){  //draw with width, calculate the height from aspect ratio
    int newH = (int)(w * (frameH / (float)frameW));
    draw(x, y, w, newH);
  }
}
      
