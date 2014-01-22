import java.util.Hashtable;
public class PowerDisplay implements Display {


  //osc
  OscP5 p5;
  String serverIP = "";
  //NetAddress  myRemoteLocation;

  //assets
  PImage bgImage, hullStateImage, reactorFailOverlay;

  //logic thingies
  int[] power = new int[4];
  int lastReducedIndex = -1;
  float oxygenLevel = 100.0f;
  float hullState = 100.0f;
  float jumpCharge = 0.0f;
  boolean reactorFailWarn = false;
  boolean failureState = true;
  int lastFailureCount = 0;
  int difficulty  = 1; //1 - 10


  //subsystem stuff   
  SubSystem[] subsystemList = new SubSystem[13];
  Hashtable<String, SubSystem> switchToSystemMap = new Hashtable<String, SubSystem>();
  //ArrayList<SubSystem> failureList = new ArrayList<SubSystem>();
  int[] analogVals = new int[4];  //analog vals from arduino
  long lastFailureTime = 0;
  long nextFailureTime = 3000;


  public PowerDisplay(OscP5 p5, String sIP) {
    this.p5 = p5;
    serverIP = sIP;
   // myRemoteLocation  = new NetAddress(sIP, 12000);
    bgImage = loadImage("powerman2.png");
    hullStateImage = loadImage("hulldamageoverlay.png");
    reactorFailOverlay = loadImage("reactorFailOverlay.png");
    for (int i = 0; i < 4; i++) {
      power[i] = 2;
    }


    //configure subsystems
    subsystemList[0] = new FuelFlowRateSystem("Deuterium", new PVector(10, 91), loadImage("icons/deuterium.png"));
    switchToSystemMap.put("NEWDIAL:2", subsystemList[0]);
    subsystemList[1] = new FuelFlowRateSystem("Tritium", new PVector(368, 91), loadImage("icons/tritium.png"));
    switchToSystemMap.put("NEWDIAL:3", subsystemList[1]);
    subsystemList[2] = new ModeratorCoilSystem("Moderator Rod 1", new PVector(405, 172), loadImage("icons/mod1.png"));
    switchToSystemMap.put("NEWDIAL:0", subsystemList[2]);
    subsystemList[3] = new ModeratorCoilSystem("Moderator Rod 2", new PVector(396, 402), loadImage("icons/mod2.png"));
    switchToSystemMap.put("NEWDIAL:1", subsystemList[3]);

    //field coils
    subsystemList[4] = new CoilSubSystem("Field Coil 1", new PVector(157, 205), loadImage("icons/coil1.png"));
    switchToSystemMap.put("NEWSWITCH:0", subsystemList[4]);
    subsystemList[5] = new CoilSubSystem("Field Coil 2", new PVector(437, 205), loadImage("icons/coil2.png"));
    switchToSystemMap.put("NEWSWITCH:2", subsystemList[5]);

    //coolant valves
    subsystemList[6] = new OnOffSystem("Coolant Valve 1", new PVector(52, 350), loadImage("icons/cool1.png"));
    switchToSystemMap.put("NEWSWITCH:4", subsystemList[6]);
    subsystemList[7] = new OnOffSystem("Coolant Valve 2", new PVector(94, 350), loadImage("icons/cool2.png"));
    switchToSystemMap.put("NEWSWITCH:6", subsystemList[7]);
    subsystemList[8] = new OnOffSystem("Coolant Valve 3", new PVector(133, 350), loadImage("icons/cool3.png"));
    switchToSystemMap.put("NEWSWITCH:8", subsystemList[8]);
    //coolant mixer
    subsystemList[9] = new OnOffSystem("Coolant mixer", new PVector(73, 390), loadImage("icons/mixer.png"));
    switchToSystemMap.put("NEWSWITCH:10", subsystemList[9]);

    //power dist
    subsystemList[10] = new MultiValueSystem("Power Dist Route", new PVector(553, 416), loadImage("icons/powerdist.png"), 3);
    switchToSystemMap.put("NEWSWITCH:13", subsystemList[10]);

    //turbines
    subsystemList[11] = new OnOffSystem("Turbine #1", new PVector(324, 456), loadImage("icons/turbine.png"));
    switchToSystemMap.put("NEWSWITCH:1", subsystemList[11]);
    subsystemList[12] = new OnOffSystem("Turbine #2", new PVector(324, 525), loadImage("icons/turbine.png"));
    switchToSystemMap.put("NEWSWITCH:3", subsystemList[12]);
  }


  public void start() {
//    for (int i = 0; i < 4; i++) {
//      power[i] = 2;
//    }
//    OscMessage msg = new OscMessage("/control/subsystemstate");
//    for (int i = 0; i < 4; i++) {
//      msg.add(power[i] );
//    }
//    p5.flush(msg,  new NetAddress(serverIP, 12000));
    for (SubSystem s : subsystemList) {
      s.reset();
    }

    probeEngPanel();
    lastFailureTime = millis();
    reactorFailWarn = false;
  }

  public void stop() {
//    for (int i = 0; i < 4; i++) {
//      power[i] = 2;
//    }
//    OscMessage msg = new OscMessage("/control/subsystemstate");
//    for (int i = 0; i < 4; i++) {
//      msg.add(power[i] );
//    }
//    p5.flush(msg,  new NetAddress(serverIP, 12000));
  }

  private int countSystemFailures() {
    int ct = 0;
    for (SubSystem s : subsystemList) {
      if (s.isFailed()) {
        ct ++;
      }
    }
    return ct;
  }

  private void addFailure() {
    int ct = countSystemFailures();
    if (ct > 7) {
      //we have a reactor failure!
      println("FAUL");
      OscMessage msg = new OscMessage("/system/reactor/fail");
      p5.flush(msg,  new NetAddress(serverIP, 12000));
      for (SubSystem s : subsystemList) {
        s.reset();
      }
      probeEngPanel();
    } 
    else if ( ct > 4) {
      //flash a warning
      reactorFailWarn = true;
      consoleAudio.playClip("failWarning");
    } 
    else {
      reactorFailWarn = false;
    }

    ArrayList<SubSystem> notFailedList = new ArrayList<SubSystem>();
    for (SubSystem s : subsystemList) {
      if (!s.isFailed()) {
        notFailedList.add(s);
      }
    }

    int rand =(int) floor(random(notFailedList.size()));
    if (rand >= 0 && rand < notFailedList.size()) {
      SubSystem s = notFailedList.get(rand);
      s.createFailure();
    } 
    else {
      //oh fuck EVERYTHING FAILED
    }
  }

  void updateFailCounts() {
    //update everyone with the current fail count
    OscMessage msg = new OscMessage("/system/powerManagement/failureCount");   
    msg.add( countSystemFailures() );
    p5.flush(msg,  new NetAddress(serverIP, 12000));
  }

  public void draw() {


    if (lastFailureTime + nextFailureTime < millis() && failureState) {
      lastFailureTime = millis();
      //nextFailureTime = 5000 + (long)random(3000);
      nextFailureTime = 2000 + (long)map(difficulty, 1, 10, 5000, 1000);

      addFailure();
    }
    if (lastFailureCount != countSystemFailures()) {
      lastFailureCount = countSystemFailures();
      updateFailCounts();
    }


    image(bgImage, 0, 0, width, height);
    //draw hull damage
    tint( (int)map(hullState, 0, 100, 255, 0), (int)map(hullState, 0, 100, 0, 255), 0);
    image(hullStateImage, 29, 470);
    noTint();


    fill(0, 255, 0);
    for (int i = 0; i < 4; i++) {
      int w = power[i] * 33;
      rect(884, 365 + i * 80, -w, 60);
    }

    textFont(font, 12);
    text((int)hullState  + "%", 179, 653);

    fill( (int)map(oxygenLevel, 0, 100, 255, 0), (int)map(oxygenLevel, 0, 100, 0, 255), 0);  
    text((int)oxygenLevel  + "%", 692, 662);

    fill( (int)map(jumpCharge, 0, 100, 255, 0), (int)map(jumpCharge, 0, 100, 0, 255), 0);    
    text((int)jumpCharge  + "%", 178, 699);



    int baseX = 625;
    int baseY = 85; 
    textFont(font, 12);   
    for (SubSystem s : subsystemList) {
      s.draw();
      textFont(font, 12);  
      if (s.isFailed()) {
        fill(0, 255, 0);
        text(s.getPuzzleString(), baseX, baseY);
        baseY += 20;
      }
    }

    if (power[1] == 3) {
      fill(255, 255, 255);
      textFont(font,15);
      text("Repairing..", 72, 611);
    }


    if (reactorFailWarn && globalBlinker) {
      image(reactorFailOverlay, 207, 631);
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
        p5.flush(msg,  new NetAddress(serverIP, 12000));
      }
    } 
    else if (slot == 5) {
      for (int i = 0; i < 4; i++) {
        power[i] = 2;
      }
      lastReducedIndex = -1;
    }
  }

  public void oscMessage(OscMessage theOscMessage) {
    if (theOscMessage.checkAddrPattern("/ship/stats")==true) {
      jumpCharge = theOscMessage.get(0).floatValue() * 100.0;
      oxygenLevel = theOscMessage.get(1).floatValue();
      hullState = theOscMessage.get(2).floatValue();
    } 
    else if (theOscMessage.checkAddrPattern("/system/powerManagement/failureState" )) {
      boolean state = theOscMessage.get(0).intValue() == 1 ? true : false;
      failureState = state;
    } 
    else if (theOscMessage.checkAddrPattern("/system/powerManagement/lightningStrike")) {
      int dam = theOscMessage.get(0).intValue();
      for (int i = 0; i < dam; i++) {
        addFailure();
      }
      println("Lstrike");
    }else if (theOscMessage.checkAddrPattern("/system/powerManagement/failureSpeed")) {
      difficulty = theOscMessage.get(0).intValue();
      println("diff changed " + difficulty);
    }
    
    
  }


  public void keyPressed() {
  }
  public void keyReleased() {
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
    else if (p[0].equals("NEWDIAL")) {

      String lookup = p[0] + ":" + p[1];// HRRNNNNNGGGGGGGGGGGGGG
      println(lookup);

      SubSystem s = switchToSystemMap.get(lookup);
      if (s != null) {
        s.setState(Integer.parseInt(p[2]));
      }
    } 
    else if (p[0].equals("NEWSWITCH")) {

      String lookup = p[0] + ":" + p[1];// HRRNNNNNGGGGGGGGGGGGGG
      println(lookup);

      SubSystem s = switchToSystemMap.get(lookup);
      if (s != null) {
        s.setState(Integer.parseInt(p[2]));
      }
    }
  }
}


/* base storage class for subsystems to be drawn to screen*/
public abstract class SubSystem {
  public PVector pos;
  public PVector size;
  public String name;

  protected String[] stateNames;
  protected int currentState = 0;  //current "value" of this system (i.e. flow rate or coil field mode
  protected int targetState = 0;   //target for the puzzle


  protected boolean isBlinking = false;
  protected long blinkStart = 0;
  protected PImage img;

  protected boolean firstValueSet = true;

  public SubSystem(String name, PVector pos, PImage p) {
    img = p;
    this.name = name;
    this.pos = pos;
  }



  public void setStateNames(String[] names) {
    stateNames = names;
  }

  public boolean isFailed() {
    return currentState != targetState;
  }

  public void setState(int state) {
    currentState = state;
    if (firstValueSet == true) {
      firstValueSet = false;
      targetState = currentState;
    }
  }

  public void reset() {
    firstValueSet = true;
    currentState = targetState;
  }

  public abstract String getPuzzleString();  //get the instruction that the user sees for this system
  public abstract void createFailure();      //make this system fail
  public String getStatusString() {    //the state that is drawn to screen i.e. "A" or "300/sec"
    return stateNames[currentState];
  }

  public void draw() {
    if (currentState != targetState ) {
      if (globalBlinker) {
        tint(255, 0, 0);
      } 
      else {
        tint(255, 255, 0);
      }
    } 
    else {
      tint(0, 255, 0);
    }
    image(img, pos.x, pos.y);
    noTint();
  }
}

public class FuelFlowRateSystem extends SubSystem {
  String fuelType = "";
  boolean targetBelowInitial = false;

  public FuelFlowRateSystem(String name, PVector pos, PImage p) {
    super(name, pos, p);
  }


  public void createFailure() {
    int newState = (int)random(999);    

    if (newState < currentState) {
      targetBelowInitial = true;
    } 
    else {
      targetBelowInitial = false;
    }
    targetState = newState;
  }

  public boolean isFailed() {

    return ! ((currentState - 50 < targetState ) && (currentState + 50 > targetState));
  }

  public void draw() {

    if (isFailed() ) {
      if (globalBlinker) {
        tint(255, 0, 0);
      } 
      else {
        tint(255, 255, 0);
      }
    } 
    else {
      tint(0, 255, 0);
    }
    image(img, pos.x, pos.y);
    noTint();
    if (isFailed()) {
      fill(255, 0, 0);
    } 
    else {
      fill(0, 255, 0);
    }
    text(getStatusString(), pos.x + 137, pos.y + 46);
  }

  public String getPuzzleString() {

    return "Set " + name + " flow close to " + targetState + "mg/sec";
  }

  public String getStatusString() {
    return currentState + "m";
  }
}

public class ModeratorCoilSystem extends SubSystem {
  String fuelType = "";
  boolean targetBelowInitial = false;

  public ModeratorCoilSystem(String name, PVector pos, PImage p) {
    super(name, pos, p);
  }


  public void createFailure() {
    int newState = (int)random(999);    

    targetState = newState;
  }

  public boolean isFailed() {
    return ! ((currentState - 100 < targetState ) && (currentState + 100 > targetState));
  }

  public void setState(int state) {
    super.setState(1000 - state);
  }

  public void draw() {

    if (isFailed() ) {
      if (globalBlinker) {
        tint(255, 0, 0);
      } 
      else {
        tint(255, 255, 0);
      }
    } 
    else {
      tint(0, 255, 0);
    }
    image(img, pos.x, pos.y);
    noTint();
    if (isFailed()) {
      fill(255, 0, 0);
    } 
    else {
      fill(0, 255, 0);
    }
    text(getStatusString(), pos.x + 67, pos.y + 23);
  }

  public String getPuzzleString() {

    return "Set " + name + " to " + (targetState / 10.0f) + "%";
  }

  public String getStatusString() {
    return (currentState / 10.0f) + "%";
  }
}

public class CoilSubSystem extends SubSystem {

  public CoilSubSystem(String name, PVector pos, PImage p) {
    super(name, pos, p);
  }

  public void createFailure() {
    targetState = 1- currentState;
  }

  public void draw() {
    super.draw();
    if (isFailed()) {
      fill(255, 0, 0);
    } 
    else {
      fill(0, 255, 0);
    }
    if (currentState == 0) {
      textFont(font, 25);
      text("A", pos.x + 50, pos.y + 65);
    } 
    else {
      textFont(font, 25);
      text("B", pos.x + 50, pos.y + 65);
    }
  }


  public String getPuzzleString() {
    if (targetState == 1) {
      return "Set " + name + " to B";
    } 
    else {
      return "Set " + name + " to A";
    }
  }
}

public class MultiValueSystem extends SubSystem {


  int maxVals = 1;

  public MultiValueSystem(String name, PVector pos, PImage p, int maxVals) {
    super(name, pos, p);
    this.maxVals = maxVals;
  }

  public void createFailure() {
    int ra = floor(random(maxVals));
    while (ra != targetState) {
      targetState = ra;
      ra = floor(random(maxVals));
    }
  }

  public String getPuzzleString() {
    return "Set " + name + " to " + (targetState + 1);
  }
}

public class OnOffSystem extends SubSystem {

  public OnOffSystem(String name, PVector pos, PImage p) {
    super(name, pos, p);
  }

  public void createFailure() {
    targetState = 1- currentState;
  }

  public String getPuzzleString() {
    if (targetState == 0) {
      return "Turn " + name + " on";
    } 
    else {
      return "Turn " + name + " off";
    }
  }
}

