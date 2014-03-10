public class Highlighter {
  int time = 10;
  PVector startSize = new PVector(400, 400);
  PVector endSize = new PVector (100, 100);
  PVector centre = new PVector(10, 10);

  boolean running = false;
  int hangRoundTime = 1000;

  long startTime = 0;

  public Highlighter(PVector centre, PVector startSize, PVector endSize, int time, int hang) {
    this.centre = centre;
    this.startSize = startSize;
    this.endSize = endSize;
    this.time = time;
    this.hangRoundTime = hang;

    running = true;
    startTime = millis();
  }

  public boolean isDone() {
    if (startTime + time + hangRoundTime < millis()) {
      return true;
    } 
    else {
      return false;
    }
  }

  public void update() {
    if (running) {
      int w = 0;
      int h = 0;

      if (startTime + time < millis()) {
        w = (int)endSize.x;
        h = (int)endSize.y;
      } 
      else if (startTime + time > millis()) {

        float t = (millis() - startTime) / (float)time;
        w = (int)lerp( startSize.x, endSize.x, t);
        h = (int)lerp( startSize.y, endSize.y, t);
      } 
      noFill();
      int r = (int)map(sin(millis() / 100.0f), -1.0f, 1.0f, 120, 255);
      stroke(r,0,0);
      strokeWeight(4);
      for(int i = 0; i < 4; i++){
        rect( centre.x - w/2 - i * 5, centre.y - h/2 -  i * 5, w + i * 10, h + i * 10);
      }
    }
  }
}




