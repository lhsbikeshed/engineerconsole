

public class ConsoleAudio {

  Minim minim;
  Hashtable<String, AudioPlayer> audioList;

  public boolean muteBeeps = false;
  //tone generation
  AudioOutput toneOutput;
  Oscil fm;
  Oscil wave;

  AudioPlayer[] beepList = new AudioPlayer[4];

  public ConsoleAudio(Minim minim) {
    this.minim = minim;
    loadSounds();

    //set up tone gen
    toneOutput   = minim.getLineOut();
    wave = new Oscil( 200, 0.8, Waves.TRIANGLE );
    fm   = new Oscil( 10, 2, Waves.SINE );
    // set the offset of fm so that it generates values centered around 200 Hz
    fm.offset.setLastValue( 200 );
    // patch it to the frequency of wave so it controls it
    fm.patch( wave.frequency );
    // and patch wave to the output

    wave.patch( toneOutput );
    toneOutput.setPan(1.0);
    setToneState(false);
  }


  public void setToneState(boolean state) {
    if (state) {
      wave.patch( toneOutput );
    } 
    else {
      wave.unpatch( toneOutput );
    }
  }

  //x should range from 220 - 50;
  //y should range from 0.1 - 100
  public void setToneValue(float x,  float y) {
    fm.frequency.setLastValue( y );
    fm.amplitude.setLastValue( x );
  }

  private void loadSounds() {
    //load sounds from soundlist.cfg
    audioList = new Hashtable<String, AudioPlayer>();
    String lines[] = loadStrings("audio/soundlist.cfg");
    println("Loading " + lines.length + " SFX");
    for (int i = 0 ; i < lines.length; i++) {
      String[] parts = lines[i].split("=");
      if (parts.length == 2 && !parts[0].startsWith("#")) {
        println("loading: " + parts[1]);
        AudioPlayer s = minim.loadFile("audio/" + parts[1], 512);
        //move to right channel
        s.setPan(1.0f);
        audioList.put(parts[0], s);
        println(s.getControls());
      }
    }
    for (int i = 0; i < beepList.length; i++) {

      beepList[i] = minim.loadFile("audio/buttonBeep" + i + ".wav");
      beepList[i].setPan(1.0f);
    }
  }

  public void randomBeep() {
    if (!shipState.poweredOn || muteBeeps) {
      return;
    }
    int rand = floor(random(beepList.length));
    while (beepList[rand].isPlaying ()) {
      rand = floor(random(beepList.length));
    }
    beepList[rand].rewind();
    beepList[rand].play();
  }

/* forces a sound to play even when ship os powered off*/
  public void playClipForce(String name){
    
    AudioPlayer c = audioList.get(name);
    if (c != null) {
      c.setPan(1.0f);
      c.rewind();
      c.play();
    } 
    else {
      println("ALERT: tried to play " + name + " but not found");
    }
  }

  public void playClip(String name) {
    if (!shipState.poweredOn) {
      return;
    }
    playClipForce(name);
  }
}

