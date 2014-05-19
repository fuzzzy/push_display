/*
 *Push Display 
 *by Yury Zarouski 
 *
 *Showing live stream from camera on Ableton Push pads
*/

import themidibus.*; 
import processing.video.*;

final int COLOR_SPACE_DIM = 8;

final int PUSH_COLORS_COUNT= 128;
final int PUSH_SCREEN_WIDTH = 8;
final int PUSH_SCREEN_HEIGHT = 8;
final int PUSH_SCREEN_START_NOTE = 36;

final int SCREEN_WIDTH = 480;
final int SCREEN_HEIGHT = 360;

final int CAPTURE_WIDTH = 320;
final int CAPTURE_HEIGHT = 240;

int pixDeltaX = SCREEN_WIDTH / PUSH_SCREEN_WIDTH;
int pixDeltaY = SCREEN_HEIGHT / PUSH_SCREEN_HEIGHT;

int[][][] colorMap = new int[COLOR_SPACE_DIM][COLOR_SPACE_DIM][COLOR_SPACE_DIM];
int[] revColorMap = new int[PUSH_COLORS_COUNT];

Capture video;
MidiBus pushMidiBus;

void prepareColormap() {
  PImage img = loadImage("111.jpg");
  
  int colorVelocity = 0;
 
  for(int y = 22; y > 0; y-=3) {
    for(int x = 1; x < 32; x+=4) {
      color pix = img.get(x, y);
      int r = ((pix >> 16) & 0xff) ;
      int g = ((pix >> 8) & 0xff);
      int b = (pix & 0xff);
      
      revColorMap[colorVelocity]=pix;
      colorVelocity++;
    }
  }
  
  img = loadImage("222.jpg");
  for(int y = 22; y > 0; y-=3) {
    for(int x = 1; x < 32; x+=4) {
      color pix = img.get(x, y);
      int r = ((pix >> 16) & 0xff) ;
      int g = ((pix >> 8) & 0xff);
      int b = (pix & 0xff);

      revColorMap[colorVelocity]=pix;
      colorVelocity++;
    }
  }
  
  for(int ir = 0; ir < COLOR_SPACE_DIM; ir++){
    for(int ig = 0; ig < COLOR_SPACE_DIM; ig++){
      for(int ib = 0; ib < COLOR_SPACE_DIM; ib++){ 
       
        int selectedIndex = -1;
        int selectedMetric = 255*255*4;
       
        for(int colorIdx=0; colorIdx < PUSH_COLORS_COUNT; colorIdx++) {
          //all follwing are 8bit color channel vals.
          final int r = ((revColorMap[colorIdx] >> 16) & 0xff);
          final int g = ((revColorMap[colorIdx] >> 8) & 0xff);
          final int b = (revColorMap[colorIdx] & 0xff);
          //3bit colors upscaled to 8bit
          final int r3 = (ir << 5) + (1 << 3);
          final int g3 = (ig << 5) + (1 << 3);
          final int b3 = (ib << 5) + (1 << 3);
          
          int metric =  (r - r3)*(r - r3) + (g - g3)*(g - g3) + (b - b3)*(b - b3);
          if(selectedMetric > metric) {
            selectedIndex = colorIdx;
            selectedMetric = metric;
          }
        }
        
        colorMap[ir][ig][ib] = selectedIndex;
      }
    }
  }
}  

void dumpColormapToFile() {
  PImage img = createImage(COLOR_SPACE_DIM *2, COLOR_SPACE_DIM * 4, ARGB);
  int pixelPos = 0; 
  for(int ir = 0; ir < COLOR_SPACE_DIM; ir++){
    for(int ig = 0; ig < COLOR_SPACE_DIM; ig++){
      for(int ib = 0; ib < COLOR_SPACE_DIM; ib++){ 
        img.pixels[pixelPos] = revColorMap[colorMap[ir][ig][ib]];
        pixelPos++;
      }
    }
  }
     
  img.save("colormap.png");
}
 
void dumpColorspaceToFile() {
  PImage img = createImage(COLOR_SPACE_DIM *2, COLOR_SPACE_DIM * 4, ARGB);
  int pixelPos = 0; 
  for(int ir = 0; ir < COLOR_SPACE_DIM; ir++){
    for(int ig = 0; ig < COLOR_SPACE_DIM; ig++){
      for(int ib = 0; ib < COLOR_SPACE_DIM; ib++){ 
        img.pixels[pixelPos] = color(ir<<5, ig<<5, ib<<5);
        pixelPos++;
      }
    }
  }
     
  img.save("colorspace.png");
} 
 
void dumpRevColormapToFile() {
  PImage img = createImage(PUSH_SCREEN_WIDTH, PUSH_SCREEN_HEIGHT * 2, ARGB);
  for(int i = 0; i < img.pixels.length; i++) {
    int row = (PUSH_SCREEN_HEIGHT * 2 - 1) - (i / PUSH_SCREEN_WIDTH) ;
    int colorPosition = PUSH_SCREEN_WIDTH * row + (i % PUSH_SCREEN_WIDTH); 
    img.pixels[colorPosition] = revColorMap[i];    
  }
  img.save("revcolormap.png");
}

void setup() {
  size(SCREEN_WIDTH * 2, SCREEN_HEIGHT * 2);
  background(0);
  
  prepareColormap();
//  dumpRevColormapToFile();
//  dumpColormapToFile();
//  dumpColorspaceToFile();

  MidiBus.list(); // List all available Midi devices on STDOUT. This will show each device's index and name.
  pushMidiBus = new MidiBus(this, 2, 2); // Create a new MidiBus object

  //sysex_set_ableton_mode = [240, 71, 127, 21, 98, 0, 1, 1, 247]
  //sysex_set_user_mode = [240, 71, 127, 21, 98, 0, 1, 0, 247]
  
  pushMidiBus.sendMessage( new byte[] { (byte)240, (byte)71, (byte)127, (byte)21, (byte)98, (byte)0, (byte)1, (byte)1, (byte)247 } );
  
  video = new Capture(this, CAPTURE_WIDTH, CAPTURE_HEIGHT);
  video.start();

  colorPrintPush(0);
  colorPrintPush(PUSH_SCREEN_WIDTH * PUSH_SCREEN_HEIGHT);  
}

void captureEvent(Capture c) {
  c.read();
}

void draw() {
  renderFromCamToPush();
}

void renderFromCamToPush()
{
  video.loadPixels();
  
  int note = 36;
  
  int pixX = 0;
  int pixY = SCREEN_HEIGHT - pixDeltaY;
  
  for (int y = video.height - 1; y >= 0 ; y-= video.height / PUSH_SCREEN_HEIGHT) {
    for (int x = video.width - 1; x >= 0; x-= video.width / PUSH_SCREEN_WIDTH) {
     
      final int pixelColor = video.get(x,y);
      // Faster method of calculating r, g, b than red(), green(), blue() 
      final int r = ((pixelColor >> 16) & 0xff);
      final int g = ((pixelColor >> 8) & 0xff);
      final int b = (pixelColor & 0xff);
      
      //calculating average pixel color
      double avr = 0;
      double avg = 0;
      double avb = 0;
      for(int colX = x - video.width / PUSH_SCREEN_WIDTH; colX < x; colX++) {
        for(int colY =  y- video.height / PUSH_SCREEN_HEIGHT; colY < y; colY++) {
          final int pixCount = (video.width / PUSH_SCREEN_WIDTH) * (video.height / PUSH_SCREEN_HEIGHT);
          avr += (double)((video.get(colX, colY) >> 16) & 0xff) / pixCount;
          avg += (double)((video.get(colX, colY) >> 8) & 0xff) / pixCount;
          avb += (double)(video.get(colX, colY) & 0xff) / pixCount; 
        }
      }
      final int ra = (int)(avr)& 0xff;
      final int ga = ((int)(avg)& 0xff);
      final int ba = (((int)(avb)& 0xff));
      
      final int randomPixelColor = video.get(int(random(x, x - video.width / 8)), int(random(y, y - video.height / 8)));
      final int rr = ((randomPixelColor >> 16) & 0xff);
      final int gr = ((randomPixelColor >> 8) & 0xff);
      final int br = (randomPixelColor & 0xff);
      //screens placement:
      //[1][2]
      //[3][4]
      
      //SCREEN 1 TOP LEFT
      fill(revColorMap[colorMap[rr>>5][gr>>5][br>>5]]);    
      rect(pixX, pixY, pixDeltaX, pixDeltaY);
      
      //SCREEN 2 TOP RIGHT
      fill(revColorMap[colorMap[ra>>5][ga>>5][ba>>5]]);   
      rect(SCREEN_WIDTH+pixX,  pixY, pixDeltaX, pixDeltaY);
      
      //SCREEN 3 BOTTOM LEFT
      fill(rr & 0xE0, gr & 0xE0, br & 0xE0);
      rect(pixX, pixY + SCREEN_HEIGHT, pixDeltaX, pixDeltaY);
      
      //SCREEN 4 BOTTOM RIGHT
      fill(ra & 0xE0, ga & 0xE0, ba & 0xE0 );  
      rect(SCREEN_WIDTH+pixX,  pixY + SCREEN_HEIGHT, pixDeltaX, pixDeltaY);
     
      //drawing on push
      pushMidiBus.sendNoteOn(0 , note, colorMap[ra>>5][ga>>5][ba>>5]);
      
      //iterating push and screens
      pixX+=pixDeltaX;
      if(pixX >= SCREEN_WIDTH) {
        pixX = 0;
        pixY-= pixDeltaY;
      }
      note++; 
    }
  }
}

//dumps all colors available on push
void colorPrintPush(final int offset) {
  for (int note = PUSH_SCREEN_START_NOTE; note < PUSH_SCREEN_START_NOTE + (PUSH_SCREEN_WIDTH * PUSH_SCREEN_HEIGHT); note++) {
    pushMidiBus.sendNoteOn(0, note, note - PUSH_SCREEN_START_NOTE + offset);
    //pushMidiBus.sendNoteOn(0, note, note - PUSH_SCREEN_START_NOTE + PUSH_SCREEN_WIDTH * PUSH_SCREEN_HEIGHT); 
  }
}
