public class DamageEffect {
  //time we last got damaged
  long damageTimer = -1000;
  PImage noiseImage; //static image that flashes
  
  boolean running = false;
  
  int tileX = 5;
  int tileY = 5;
  
  public DamageEffect(){
    println("generating damage images...");
    noiseImage = createImage(width / tileX, height / tileY, RGB);
    noiseImage.loadPixels();
    for (int i = 0; i < noiseImage.width * noiseImage.height; i++){
      noiseImage.pixels[i] = color(random(255));
    }
    noiseImage.updatePixels();
    println("     ...done");
  } 

  public void startTransform(){
     pushMatrix();
    if(running){
     
      translate(random(-20, 20), random(-20, 20));
      tint(random(255));
    }
  }
  
  public void stopTransform(){
    popMatrix();
    if(running){
      noTint();
    }
  }

  public void draw(){
    //image(noiseImage, 100,100);
     if(running){
       if(damageTimer < millis()){
         running = false;
       } else {
         
         for(int x = 0; x < tileX; x++){
           for(int y = 0; y < tileY; y++){
             if(random(100) < 25){
               image(noiseImage, x * noiseImage.width, y * noiseImage.height);
             }
           }
         }
       }
     }
             
  }
  
  
  
  public void startEffect(long ms){
    damageTimer = millis() + ms;
    running = true;
  }

}  
