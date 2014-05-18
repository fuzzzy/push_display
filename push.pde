import themidibus.*; //Import the library
import javax.sound.midi.MidiMessage; //Import the MidiMessage classes http://java.sun.com/j2se/1.5.0/docs/api/javax/sound/midi/MidiMessage.html
import javax.sound.midi.SysexMessage;
import javax.sound.midi.ShortMessage;

MidiBus myBus; // The MidiBus
HashMap<Integer, Integer> colortable;

import processing.video.*;

Capture video;

void setup() {
  size(400, 400);
  background(0);

  MidiBus.list(); // List all available Midi devices on STDOUT. This will show each device's index and name.
  myBus = new MidiBus(this, 2, 2); // Create a new MidiBus object

//sysex_set_ableton_mode = [240, 71, 127, 21, 98, 0, 1, 1, 247]
//sysex_set_user_mode = [240, 71, 127, 21, 98, 0, 1, 0, 247]

  
  myBus.sendMessage(
    new byte[] { (byte)240, (byte)71, (byte)127, (byte)21, (byte)98, (byte)0, (byte)1, (byte)1, (byte)247 } );
  
  video = new Capture(this, 160, 120);
  
  // Start capturing the images from the camera
  video.start();    
    
   myBus.addMidiListener(new RawMidiListener() {
     public
     void rawMidiMessage(byte[] data) {
       println(data);
     }
   }
   );
   
//   colortable = new HashMap<Integer, Integer>();
//   
//   PImage img = loadImage("1.jpg");
//
//   int i = 0;
//   for(int x = (200 / 8) / 2; x < 200; x += (200 / 8)) {
//     for (int y = (148 / 8) / 2; x < 148; x += (148 / 8)) {
//       color pix = img.get(x, y);
//       colortable.put(pix.,  i);
//       i++;
//     }
//   }
//     
//    println(colortable);
}

void captureEvent(Capture c) {
  c.read();
}

int maxluma=0;

void draw() {

  video.loadPixels();
  int note = 36;
  for (int y = video.height -1; y > 0 ; y-= video.height / 8) {

    // Move down for next line
    for (int x = 0; x < video.width; x+= video.width / 8) {
      int pixelColor = video.pixels[ y*video.width + x  ];
      // Faster method of calculating r, g, b than red(), green(), blue() 
      int r = (pixelColor >> 16) & 0xff;
      int g = (pixelColor >> 8) & 0xff;
      int b = pixelColor & 0xff;
      int luma = (int)(0.2126*(float)r + 0.7152*(float)g + 0.0722*(float)b);
      
      luma = luma / 10;
      int pointcolor = 0;
      
      if (luma < 5)
        pointcolor = 0;
      else if (luma < 10)
        pointcolor = 48;
      else if (luma < 15)
        pointcolor = 47;
      else if (luma < 20)
        pointcolor = 46;
      else
        pointcolor = 45;
      
      myBus.sendNoteOn(0 , note, pointcolor);
      //print (" msg: " + x + " " +  y + " c=" + r + g + b);
      note++;
    }
  }
//  for (int note = 36; note < 36 + 8; note++) {
//    myBus.sendNoteOn(0, note, note  - 36 + 48); // Send a Midi noteOn
//  }
}

// Notice all bytes below are converted to integeres using the following system:
// int i = (int)(byte & 0xFF) 
// This properly convertes an unsigned byte (MIDI uses unsigned bytes) to a signed int
// Because java only supports signed bytes, you will get incorrect values if you don't do so

void rawMidi(byte[] data) { // You can also use rawMidi(byte[] data, String bus_name)
  // Receive some raw data
  // data[0] will be the status byte
  // data[1] and data[2] will contain the parameter of the message (e.g. pitch and volume for noteOn noteOff)
  println();
  println("Raw Midi Data:");
  println("--------");
  println("Status Byte/MIDI Command:"+(int)(data[0] & 0xFF));
  // N.B. In some cases (noteOn, noteOff, controllerChange, etc) the first half of the status byte is the command and the second half if the channel
  // In these cases (data[0] & 0xF0) gives you the command and (data[0] & 0x0F) gives you the channel
  for (int i = 1;i < data.length;i++) {
    println("Param "+(i+1)+": "+(int)(data[i] & 0xFF));
  }
}

void midiMessage(MidiMessage message) { // You can also use midiMessage(MidiMessage message, long timestamp, String bus_name)
  // Receive a MidiMessage
  // MidiMessage is an abstract class, the actual passed object will be either javax.sound.midi.MetaMessage, javax.sound.midi.ShortMessage, javax.sound.midi.SysexMessage.
  // Check it out here http://java.sun.com/j2se/1.5.0/docs/api/javax/sound/midi/package-summary.html
  println();
  println("MidiMessage Data:");
  println("--------");
  println("Status Byte/MIDI Command:"+message.getStatus());
  for (int i = 1;i < message.getMessage().length;i++) {
    println("Param "+(i+1)+": "+(int)(message.getMessage()[i] & 0xFF));
  }
}

void delay(int time) {
  int current = millis();
  while (millis () < current+time) Thread.yield();
}
