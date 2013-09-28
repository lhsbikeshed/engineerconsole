
/* display some info about the wormhole
 * such as "stay outside 300m when it opens"
 * charge level
 * opening or closing
 * force full power to sensors to show all data
 *
 */
public class WormholeDisplay implements Display {

  PImage bgImage;

  PFont font;

  //osc
  OscP5 p5;
  String serverIP = "";
  
  PVect


  //power man
  //logic thingies
  int[] power = new int[4];
  int lastReducedIndex = -1;
  float oxygenLevel = 100.0f;
  float hullState = 100.0f;
  float jumpCharge = 0.0f;

  public WormholeDisplay(OscP5 p5, String sIP) {
    font = loadFont("FixedsysTTF-48.vlw");
    bgImage = loadImage("wormholeStatus.png");
    serverIP = sIP;
    this.p5 = p5;
    for (int i = 0; i < 4; i++) {
      power[i] = 2;
    }
  }



  public void start() {
    for (int i = 0; i < 4; i++) {
      power[i] = 2;
    }
  }
  public void stop() {
  }

  public void draw() {
    background(0, 0, 0);

    image(bgImage, 0,0,width,height);
    text("WORMHOLES MOTHERFUCKER", 20, 400);

    //draw power management bars
    fill(0, 255, 0);
    for (int i = 0; i < 4; i++) {
      int w = power[i] * 23;
      rect(906, 411 + i * 70, -w, 65);
    }
  }

  public void oscMessage(OscMessage theOscMessage) {
  }

  public void serialEvent(String evt) {
    String[] p = evt.split(":");  
    if (p[0].equals( "KEY")) {
      char c = p[1].charAt(0);
      switch(c) {
      case '1':
        changePower(0);
        break;
      case '2':
        changePower(1);
        break;
      case '3':
        changePower(2);
        break;
      case '4':
        changePower(3);
        break;
      }
    }
  }

  public void changePower(int slot) {
    if (slot >= 0 && slot < 5) {
      //find the highest power and sub 1
      int highestIndex = -1;
      int highest = -1;
      for (int i = 0; i < 4; i++) {
        if (power[i] >= highest && i != slot && lastReducedIndex != i) {
          highest = power[i];
          highestIndex = i;
        }
      }
      if (power[highestIndex] - 1 > 0 && power[slot] + 1 < 4) {
        power[highestIndex]--;
        lastReducedIndex = slot;

        power[slot]++;
        OscMessage msg = new OscMessage("/control/subsystemstate");
        for (int i = 0; i < 4; i++) {
          msg.add(power[i] );
        }
        p5.flush(msg, new NetAddress(serverIP, 12000));
      }
    } 
    else if (slot == 5) {
      for (int i = 0; i < 4; i++) {
        power[i] = 2;
      }
      lastReducedIndex = -1;
    }
  }

  public void keyPressed() {
  }
  public void keyReleased() {
  }
}

