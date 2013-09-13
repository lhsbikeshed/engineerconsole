

public class BootDisplay implements Display {
  
  PImage bgImage;
  public  int bootCount = 0;
  PFont font;
  
  public boolean brokenBoot = false;
  
  int curFile = 0;
  int[] filesToReplace = {12,11,6};
  String[] fileNames = {"kernel32.sys", "PilotIOController.sys", "SplineReticulator.so"};
  int nextFail = 100;
  
  public BootDisplay(){
    font = loadFont("HanzelExtendedNormal-48.vlw");
    bgImage = loadImage("bootlogo.png");
  }
  
  
  public void start(){
    bootCount = 0;
    curFile = 0;
    nextFail = 100;
    
    
  }
  public void stop(){
    bootCount = 0;
  }
  
  public boolean isReady(){
    return bootCount > 400 ? true : false;
  }

  public void draw(){
    //image(bgImage, 0,0,width,height);
    background(0,0,0);
    
    if(bootCount < 100){
      textFont(font,10);
      fill(0,255,0);
      String dots = ".";
      for(int i = 0; i < bootCount / 10; i++){
        dots += ".";
      }
      text("startup " + dots, 30,30);
      bootCount += 10;
    } else {
      fill(0,0,255);
      rect(353, 454, map(bootCount, 100, 400, 0, 330), 30);
      image(bgImage,0,0,width,height);;
      if(brokenBoot){
       if( bootCount > nextFail){
          bannerSystem.setSize(700,300);
          bannerSystem.setTitle("ERROR 100EF33");
          bannerSystem.setText("MISSING FILE <" + fileNames[curFile] + "> Please insert rescue disk " + filesToReplace[curFile]);
          bannerSystem.displayFor(360000);
       } else {
         bootCount += 10;
       }
      } else {
        bootCount += 10;
      }
    }
    
  }
  
  public void setDisks(int[] in){
    println("setting disks to: " + in);
    filesToReplace = in;
  }
  
  public void oscMessage(OscMessage theOscMessage){
    if(theOscMessage.checkAddrPattern("/system/boot/diskInsert")==true){
      boolean correct = theOscMessage.get(0).intValue() == 1 ? true : false;
      if(correct){
        curFile ++;
        if(curFile < 3){
          nextFail += 75;
        } else {
          brokenBoot = false;
          bannerSystem.cancel();
        }
      } else {
        println("Failed");
        bannerSystem.cancel();
        bannerSystem.setText("INCORRECT DISK. PLEASE INSERT DISK " + filesToReplace[curFile]);
        bannerSystem.displayFor(360000);
      }
  
    }
   
  }

  public void serialEvent(String evt){}

  public void keyPressed(){}
  public void keyReleased(){}
}
