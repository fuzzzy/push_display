import themidibus.*; //Import the library
import javax.sound.midi.MidiMessage; //Import the MidiMessage classes http://java.sun.com/j2se/1.5.0/docs/api/javax/sound/midi/MidiMessage.html
import javax.sound.midi.SysexMessage;
import javax.sound.midi.ShortMessage;

MidiBus myBus; // The MidiBus
int[][][] colorMap;

import processing.video.*;

Capture video;

void prepareColormap() {
   colorMap = new int[7][7][7];
  
  PImage img = loadImage("11.jpg");
  
  int colorVelocity = 0;
  
  int minr = 255;
  int ming = 255;
  int minb = 255;
  
  int maxr = 0;
  int maxg = 0;
  int maxb = 0;
  
  for(int y = 23; y > 0; y-=3) {
    for(int x = 0; x < 32; x+=4) {
      color pix = img.get(x, y);
      int r = ((pix >> 16) & 0xff) ;
      int g = ((pix >> 8) & 0xff);
      int b = (pix & 0xff);
      
      if(r < minr) {
        minr = r;
      }
      if(r > maxr) {
        maxr = r;
      }  
      if(g < ming) {
        ming = g;
      }
      if(g > maxg) {
        maxg = g;
      } 
      if(b < minb) {
        minb = b;
      }
      if(b > maxb) {
        maxb = b;
      } 
      
      r = r * 7 / 187;
      g = g * 7 / 172;
      b = b * 7 / 169;
      colorMap[r][g][b] = colorVelocity; 
      colorVelocity++;
    }
  }
  
  println("r: " + minr + " " + maxr +"g: " + ming + " " + maxg + " " + "b: " + minb + " " + maxb);
  
  PImage img2 = loadImage("22.jpg");
  for(int y = 23; y > 0; y-=3) {
    for(int x = 0; x < 32; x+=4) {
      color pix = img2.get(x, y);
      int r = ((pix >> 16) & 0xff) ;
      int g = ((pix >> 8) & 0xff);
      int b = (pix & 0xff);
      
      if(r < minr) {
        minr = r;
      }
      if(r > maxr) {
        maxr = r;
      }  
      if(g < ming) {
        ming = g;
      }
      if(g > maxg) {
        maxg = g;
      } 
      if(b < minb) {
        minb = b;
      }
      if(b > maxb) {
        maxb = b;
      } 
      
      r = r * 7 / 191;
      g = g * 7 / 222;
      b = b * 7 / 219;
      colorMap[r][g][b] = colorVelocity;
      colorVelocity++;
    }
  }
  
  println("r: " + minr + " " + maxr +"g: " + ming + " " + maxg + " " + "b: " + minb + " " + maxb);
  
  int[] setColors = new int[350];
  int iter = 0;
  for(int r=5; r > 0; r--) {
    for(int g=5; g > 0; g--) {
      for(int b=5; b > 0; b--) {
        if(colorMap[r][g][b] != 0) {
          setColors[iter] = 100 * r + 10 *g + b;
          iter++;
        }
      }
    }
  }
  
  for(int c = iter - 1 ; c >= 0; c--) {
    int r = setColors[c] / 100;
    int g = (setColors[c] % 100) / 10;
    int b = setColors[c] % 10;
    for(int ir = r-1; ir <=r+1; ir++){
      for(int ig = r-1; ig <=r+1; ig++){
        for(int ib = r-1; ib <=r+1; ib++){
          if(colorMap[ir][ig][ib] == 0) {
            colorMap[ir][ig][ib] = colorMap[r][g][b];
          }
        }
      }
    }
  }
  
  colorMap[0][0][0] = 0;
  colorMap[1][0][0] = 0;
  colorMap[0][1][0] = 0;
  colorMap[0][0][1] = 0;
}

void setup() {
  size(400, 400);
  background(0);
  
  prepareColormap();

  MidiBus.list(); // List all available Midi devices on STDOUT. This will show each device's index and name.
  myBus = new MidiBus(this, 2, 2); // Create a new MidiBus object

//sysex_set_ableton_mode = [240, 71, 127, 21, 98, 0, 1, 1, 247]
//sysex_set_user_mode = [240, 71, 127, 21, 98, 0, 1, 0, 247]
  
  myBus.sendMessage(
    new byte[] { (byte)240, (byte)71, (byte)127, (byte)21, (byte)98, (byte)0, (byte)1, (byte)1, (byte)247 } );
  
  video = new Capture(this, 160, 120);
  video.start();    
}

void captureEvent(Capture c) {
  c.read();
}

void draw() {
  video.loadPixels();
  int note = 36;
  for (int y = video.height -1; y > 0 ; y-= video.height / 8) {

    // Move down for next line
    for (int x = video.width -1; x > 0; x-= video.width / 8) {
      int pixelColor = video.pixels[ y*video.width + x  ];
      // Faster method of calculating r, g, b than red(), green(), blue() 
      int r = ((pixelColor >> 16) & 0xff) * 7 / 256;
      int g = ((pixelColor >> 8) & 0xff) * 7 / 256;
      int b = (pixelColor & 0xff) * 7 / 256;
      
      myBus.sendNoteOn(0 , note, colorMap[r][g][b]);
      //print (" msg: " + x + " " +  y + " c=" + r + g + b);
      note++;
    }
  }
}

void colorprintPush() {
  for (int note = 36; note < 36 + 64; note++) {
    myBus.sendNoteOn(0, note, note - 36 +64); // Send a Midi noteOn
  }
}
