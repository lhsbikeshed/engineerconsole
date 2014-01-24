public class BannerOverlay {

  PImage cornerImg, edgeImg;

  private long startDisplayTime = 0;
  private long duration = 1000;

  private boolean visible = false;

  private PVector pos = new PVector(0, 0);
  private PVector size = new PVector(32, 32);

  private String title = "TITLE";
  private ArrayList<String> text = new ArrayList<String>();

  private PFont font;

  private int iconIndex = 0;
  private PImage[] icons = new PImage[1];

  String pathBase = "C:/Users/tom/Dropbox/starship/engineerconsole/data/";    //TESTING
  //String pathBase = "c:/game/dev/engineerconsole/data/";    //LIVE

  public BannerOverlay () {
    cornerImg = loadImage(pathBase + "corner.png");
    edgeImg = loadImage(pathBase + "edge.png");
    font = loadFont(pathBase + "HanzelExtendedNormal-48.vlw");

    icons[0] = loadImage(pathBase + "/warningicon.png");
  }

  public void draw() {

    if (visible) {
      if (startDisplayTime + duration < millis()) {
        visible = false;
      }

      //draw it
      drawBox();
      fill(255, 0, 0);
      textFont(font, 50);
      int textX = (int)((pos.x + size.x/2) - ( textWidth(title) / 2));
      int textY = (int)(pos.y + 70) ;
      text(title, textX, textY);

      textFont(font, 20);
      fill(255, 255, 0);
      textX = (int)pos.x + 180;
      textY = (int)pos.y + 120;
      for (String line : text) {
        text(line, textX, textY);
        textY += 30;
      }
      image(icons[0], pos.x + 30, pos.y + 80, 120, 120);
    }
  }

  public void setText(String text) {
    String[] words = text.split(" ");
    textFont(font, 20);
    int maxWidth = (int)size.x - 170; //30 px border each size
    this.text = new ArrayList<String>();
    String curLine = "";
    for (String word : words) {
      if (textWidth(curLine + " " + word) < maxWidth) {
        curLine += word + " ";
      } 
      else {
        this.text.add(curLine);
        curLine = word + " ";
      }
    }
    this.text.add(curLine);
  }

  public void setTitle(String title) {
    this.title = title;
  }

  private void drawBox() {

    pushMatrix();
    translate(pos.x, pos.y); 
    image(cornerImg, 0, 0);   //TL
    pushMatrix();
    //translate(32, pos.y);
    rotate(PI/2);
    image(edgeImg, 0, -32, 32, -size.x + 32); //TOP
    popMatrix();

    pushMatrix(); //TR
    translate(size.x + 32, 0); 
    rotate(PI/2);

    image(cornerImg, 0, 0 );
    popMatrix();

    pushMatrix();
    translate(size.x, 32);
    rotate(PI);
    image(edgeImg, -32, - size.y, 32, size.y );
    popMatrix();

    pushMatrix();
    translate(0, size.y+ 64);
    rotate(-PI/2);
    image(edgeImg, 0, 32, 32, size.x - 32);
    popMatrix();

    pushMatrix();
    translate(0, 32);
    // rotate(PI);
    image(edgeImg, 0, 0, 32, size.y );
    popMatrix();


    pushMatrix(); //BR
    translate(size.x + 32, size.y + 64); 
    rotate(-PI);

    image(cornerImg, 0, 0 );
    popMatrix();

    pushMatrix();
    translate(0, size.y);
    rotate(-PI/2);
    image(cornerImg, -64, 0, 32, 32); //TOP
    popMatrix();

    popMatrix();

    fill(0);
    rect(pos.x + 16, pos.y + 16, size.x - 16, size.y + 16);
  }


  public void cancel() {
    visible = false;
  }

  public void displayFor(int time) {
    if (!visible) {
      startDisplayTime = millis();
      visible = true;
      duration = time;
      consoleAudio.playClip("bannerPopup");
    }
  }


  public void setSize(int w, int h) {

    size.x = w;
    size.y = h;
    pos.x = (width - w) / 2;
    pos.y = (height - h) / 2;
  }
}

