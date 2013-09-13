

public class RemoteConnectionDisplay implements Display {

  PImage bgImage, fileBg;

  PFont font2;

  public static final int STATE_CONNECTING = 0;
  public static final int STATE_CONNECTED = 1;
  public static final int STATE_RUNNING = 2;
  public static final int STATE_FILELIST = 3;

  int state = STATE_CONNECTED;
  long stateStart = 0;
  int connectionProgress = 0;


  // actual parts of the game
  //two columns of hex dumps, some rows change on left and right, enter the matching rows
  int[][] memoryData = new int[30][8];

  ChangingData[] sploitList = new ChangingData[10];
  int currentSploit = 0;
  int hackCount = 0;

  String enteredText = "";


  //file list stuff

  FileEntry[] fileList = new FileEntry[8];
  int curFile = 0;
  String[] displayWords;
  String displayText = "";
  int displayTimer = 0;
  boolean textDone = true;
  long lastTimer = 0;
  PImage displayImage;

  public RemoteConnectionDisplay() {
    font2 = loadFont("FixedsysTTF-48.vlw");
    bgImage = loadImage("haxxorbg.png");
    fileBg = loadImage("filelistbg.png");

    //setup the file list
    for (int i = 0; i < 5;i++) {
      fileList[i] = new FileEntry();
      fileList[i].contents = getFileContents("file" + i + ".txt");
      fileList[i].name = "Security Log " + (i + 1) + ".log";
    }
    fileList[5] = new FileEntry();
    fileList[5].type = "image";
    fileList[5].contents = "files/image1.png";
    fileList[5].name = "Last Cam Image.png";

    fileList[6] = new FileEntry();
    fileList[6].type = "osc";
    fileList[6].contents = "Captains log";
    fileList[6].name = "captains log.mp3";
    fileList[6].oscTriggerId = 1;

    fileList[7] = new FileEntry();
    fileList[7].type = "text";
    String randomMess = "";
    for(int i = 0; i < 1300; i++){
      randomMess += (char)random(255);
    }
    fileList[7].contents = randomMess;
    fileList[7].name = "MineSweeper.exe";
    fileList[7].oscTriggerId = 2;

    start();
  }


  public void start() {
    state = STATE_CONNECTING;
    for (int i = 0; i < memoryData.length; i++) {
      for (int p = 0; p < memoryData[i].length; p++) {
        memoryData[i][p] = (int)random(255);
      }
    }

    int[] randomList  = new int[30];
    for (int i = 0; i < 30; i++) {
      randomList[i] = i;
    }

    for (int i = 29; i > 0; i--) {
      int toMove = (int)random(i);
      int t = randomList[i];
      randomList[i] = randomList[toMove];
      randomList[toMove] = t;
    }

    for (int i = 0; i < sploitList.length; i++) {
      sploitList[i] = new ChangingData();
      sploitList[i].destRow = randomList[i];
      for (int p = 0; p < sploitList[i].data.length; p++) {
        sploitList[i].data[p] = (int)random(250);
        sploitList[i].originalData[p] = sploitList[i].data[p];
      }
    }
    currentSploit = 9;
    connectionProgress = 0;
    curFile = 0;
    displayText = "";
    textDone = true;
  }
  public void stop() {
  }


  public void draw() {
    //image(bgImage, 0,0,width,height);
    background(0, 0, 0);
    if (state == STATE_CONNECTING) {    // Show a "connecting..." dialogue
      //show connecting, then "password prompt"
      textFont(font, 20);
      text("CONNECTING..", 100, 100);
      connectionProgress ++;
      rect(100, 150, connectionProgress * 10 > 300 ? 300 : connectionProgress * 10, 20);
      if (connectionProgress > 36) {
        text("ACCESS DENIED!", 100, 130);
      }
      if (connectionProgress > 45) {
        textFont(font, 30);
        String dots = ".";
        for (int i = 0; i < connectionProgress % 4; i++) {
          dots += ".";
        }
        text("STARTING OVERRIDE SEQUENCE" + dots, 100, 220);
      }

      if (connectionProgress > 70) {
        state = STATE_CONNECTED;
      }
    } 
    else if (state == STATE_CONNECTED || state == STATE_RUNNING) {

      gameStuff();
    } 
    else if (state == STATE_FILELIST) {
      fileListStuff();
    }
    //connecting : show connecting then pw prompt
    //connected: show "hacking puzzle"
    //hackdone : show file list, ordered list of log entries
    // each entry triggers a download and then plays it on the ships speakers
    // final entry is virus infected
  }

  private void gameStuff() {
    //update states
    for (int s = 0; s < sploitList.length; s++) {
      sploitList[s].update();
    }

    image(bgImage, 0, 0, width, height);
    textFont(font2, 25);
    int startX = 38;
    int startY = 150;
    String t = "";
    fill(255, 255, 255);

    for (int i = 0; i < memoryData.length; i++) {
      int sploitId = -1;
      for (int s = 0; s < sploitList.length; s++) {
        if (sploitList[s].destRow == i) {
          sploitId = s;
          break;
        }
      }
      t = "00000";        
      t = t + (100 + i * 10) + ":";
      String code = "";
      if (sploitId < 0) {
        for (int c = 0; c < memoryData[i].length; c++) {
          String d = ("" + hex(memoryData[i][c])).substring(6, 8);
          code = code + " " + d;
        }     
        fill (255, 255, 255);
      } 
      else {
        for (int c = 0; c < sploitList[sploitId].data.length; c++) {
          String d = ("" + hex(sploitList[sploitId].data[c])).substring(6, 8);
          code = code + " " + d;
        }
        if (sploitList[sploitId].done == true) {
          fill(0, 255, 0);
        } else {
          fill(220,120,120);
        }
      }

      t = t + code;
      int y = startY + i * 20;

      text(t, startX, y);
    }

    //draw the patch list
    startX = 620; 
    startY = 154;

    for (int i = 0; i < sploitList.length; i++) {
      String code = ">";
      for (int c = 0; c < sploitList[i].originalData.length; c++) {
        String d = ("" + hex(sploitList[i].originalData[c])).substring(6, 8);
        code = code + " " + d;
      }
      if (currentSploit == i) {
        fill(0, 255, 0);
      } 
      else {
        fill(255, 255, 255);
      }
      text(code, startX, startY + i * 20);
    }

    text(enteredText + "_", 640, 570);

    if (state == STATE_RUNNING) {
      String[] progress = {
        "-", "\\", "|", "/"
      };
      String c = progress[ (millis() / 400) % 4 ];
      text(c + " EXECUTING " + c, 708, 357);

      if (millis() % 30 < 15) {
        hackCount++;
      }
      if (hackCount < memoryData.length) {
        memoryData[hackCount] = new int[] {
          0xDE, 0xAD, 0xBE, 0xEF, 0xDE, 0xAD, 0xBE, 0xEF
        };
      } 
      else {
        println("COMPLETE");
        state = STATE_FILELIST;
        stateStart = millis();
        bannerSystem.setSize(700, 300);
        bannerSystem.setTitle("SUCCESS");
        bannerSystem.setText("Access to remote server granted");
        bannerSystem.displayFor(1000);
      }
    }
  }


  public void fileListStuff() {
    image(fileBg, 0, 0, width, height);

    textFont(font2, 22);
    fill(255, 255, 255);
    for (int i = 0; i < fileList.length; i++) {
      if (curFile == i) {
        fill(0, 255, 0);
      } 
      else {
        fill(255, 255, 255);
      }
      text(fileList[i].name, 40, 170 + i * 20);
    }

    if (textDone == false) {
      if (lastTimer + 100 < millis()) {
        //println(displayTimer);
        lastTimer = millis();
        if (textWidth( displayText + " " + displayWords[displayTimer] )< 500) {
          displayText = displayText + " " + displayWords[displayTimer];
        } 
        else {
          displayText = displayText + "\r\n" + displayWords[displayTimer];
        }
        displayTimer ++;
        if (displayTimer > displayWords.length -1) {
          if(fileList[curFile].oscTriggerId > 0){
            println("Sending osc trigger...");
            OscMessage myMessage = new OscMessage(fileList[curFile].oscTrigger);
            myMessage.add(fileList[curFile].oscTriggerId);
            oscP5.flush(myMessage, new NetAddress(serverIP, 12000));
          }
          textDone = true;
        }
      }
    }

    fill(255, 255, 255);
    text (displayText, 460, 154);

    if (displayImage != null) {
      if (lastTimer + 100 < millis()) {
        //println(displayTimer);
        lastTimer = millis();
        displayTimer ++;
      }
      if (displayTimer > 10) {
        image(displayImage, 460, 154);
      } 
      else {
        text("Loading " + (displayTimer * 10) + "%", 460, 154);
      }
    }
  }

  public void playFile() {
    println("Showing file " + curFile);
    FileEntry f = fileList[curFile];
    if (f.type.equals("text")) {
      displayImage = null;
      displayWords = f.contents.split(" ");
      displayText = "";
      displayTimer = 0;
      textDone = false;
    } 
    else if (f.type.equals("image")) {
      displayText = "";
      textDone = true;
      displayTimer = 0;
      displayImage = loadImage(f.contents);
    } else if (f.type.equals("osc")){
     
      displayText = "PLAYING..";
      textDone = true;
      displayTimer = 0;
      displayImage = null;
      OscMessage myMessage = new OscMessage(fileList[curFile].oscTrigger);
      myMessage.add(fileList[curFile].oscTriggerId);
      oscP5.flush(myMessage, new NetAddress(serverIP, 12000));
    }
  }


  public void oscMessage(OscMessage theOscMessage) {
  }

  public void checkCode() {
    int rowId = Integer.parseInt(enteredText);
    rowId -= 100;
    rowId /= 10;
    if (rowId >= 0 && rowId < memoryData.length) {
      println("r: " + rowId + " C: " +sploitList[currentSploit].destRow );
      if (sploitList[currentSploit].destRow == rowId) {
        sploitList[currentSploit].done = true;
        currentSploit++;
        if (currentSploit >= sploitList.length) {
          println("Done");
          state = STATE_RUNNING;
          stateStart = millis();
        }
      }
    }
  }


  public void serialEvent(String evt) {
    String[] evtData = evt.split(":");
    if (evtData.length < 2) {
      return;
    }
    char c = evtData[1].charAt(0);
    if (state == STATE_CONNECTED ) {
      if (c >= '0' && c <= '9') {
        enteredText += c;
        if (enteredText.length() == 8) {
          checkCode();
          enteredText = "";
        }
      } 
      else if (c == 'k') {  //change me
        checkCode();
        enteredText = "";
      }
    } 
    else if (state == STATE_FILELIST) {
      if (c == '8') {
        curFile --;
        if (curFile < 0) { 
          curFile = 0;
        }
      } 
      else if (c == '2') {
        curFile++;
        if (curFile > fileList.length - 1) { 
          curFile = fileList.length - 1;
        }
      } 
      else if (c == '5') {
        playFile();
      }
    }
  }

  public void keyPressed() {
  }
  public void keyReleased() {
  }

  private String getFileContents(String fname) {
    // Load the local file 'data.txt' and initialize a new InputStream
    println("Loading : " + fname);
    InputStream input = createInput("files/" + fname);

    String content = "";

    try {
      int data = input.read();
      while (data != -1) {
        content += (char)data;
        data = input.read();
      }
    }
    catch (IOException e) {
      e.printStackTrace();
    }
    finally {
      try {
        input.close();
      } 
      catch (IOException e) {
        e.printStackTrace();
      }
    }

    return content;
  }


  /* an entry in the remote sec log file system */
  public class FileEntry {
    public String type = "text";
    public String name = "seclog01.txt";
    public String contents = "PISSING AND POOING";
    public int creationTime = 10000202;

    public boolean isAudio = false;
    public String oscTrigger = "/scene/nebulascene/fileEntry";
    public int oscTriggerId = 0;

    public FileEntry() {
    }
  }


  public class ChangingData {
    public int[] data = new int[8];
    public int[] originalData = new int[8];

    public int destRow;
    public boolean done = false;

    long lastChange = 0;
    long changeRate = 1000;

    public ChangingData() {
      changeRate = 550 + (long)random(450);
    }



    public void update() {
      if (lastChange + changeRate < millis() && !done) {
        lastChange = millis();
        for (int i = 0; i < data.length; i++) {
          data[i] += 50;
          data[i] %= 250;
        }
      }
    }
  }
}

