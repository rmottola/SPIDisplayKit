/*
   Project: SPIDisplayKit

   Copyright (C) 2010 Limor Fried, Adafruit Industries
   Copyright (C) 2011 Le Dang Dung  <LeeDangDung@gmail.com> (tested on LPC1769)
   Copyright (C) 2012 Andre Wussow <desk@binerry.de>
   Copyright (C) 2020 Riccardo Mottola

   Author: Riccardo Mottola
           Andre Wussow

   Created: 2020-06-18 09:06:15

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

/*
=================================================================================

 Description :
     A simple PCD8544 LCD (Nokia3310/5110) driver. Target board is Raspberry Pi.
     This driver uses 5 GPIOs on target board with a bit-bang SPI implementation
     (hence, may not be as fast).
	 Makes use of WiringPI-library of Gordon Henderson (https://projects.drogon.net/raspberry-pi/wiringpi/)

	 Recommended connection (http://www.raspberrypi.org/archives/384):
	 LCD pins      Raspberry Pi
	 LCD1 - GND    P06  - GND
	 LCD2 - VCC    P01 - 3.3V
	 LCD3 - CLK    P11 - GPIO0
	 LCD4 - Din    P12 - GPIO1
	 LCD5 - D/C    P13 - GPIO2
	 LCD6 - CS     P15 - GPIO3
	 LCD7 - RST    P16 - GPIO4
	 LCD8 - LED    P01 - 3.3V 

 References  :
 http://www.arduino.cc/playground/Code/PCD8544
 http://ladyada.net/products/nokia5110/
 http://code.google.com/p/meshphone/

 */


#include <unistd.h>

#import "PCD8544Display.h"

#include <wiringPi.h>

#include "pilogo.h"
#include "font.h"

// An abs() :)
#define abs(a) (((a) < 0) ? -(a) : (a))

// bit set
#define _BV(bit) (0x1 << (bit))

// the memory buffer for the LCD
uint8_t pcd8544_buffer[LCDWIDTH * LCDHEIGHT / 8] = {0,};

// LCD port variables
static SDKPoint cursor;
static uint8_t textsize, textcolor;
static int8_t _din, _sclk, _dc, _rst, _cs;

#ifdef enablePartialUpdate
static uint8_t xUpdateMin, xUpdateMax, yUpdateMin, yUpdateMax;
#endif

static void updateBoundingBox(uint8_t xmin, uint8_t ymin, uint8_t xmax, uint8_t ymax) {
#ifdef enablePartialUpdate
	if (xmin < xUpdateMin) xUpdateMin = xmin;
	if (xmax > xUpdateMax) xUpdateMax = xmax;
	if (ymin < yUpdateMin) yUpdateMin = ymin;
	if (ymax > yUpdateMax) yUpdateMax = ymax;
#endif
}

@implementation PCD8544Display

- (id)init
{
  // Init with common defaults
  return [self initWithPinsClock:0 dataIn:1 dataCommand:2 chipEnable:3 reset:4 contrast:50];
}

- (id) initWithPinsClock:(uint8_t)SCLK dataIn:(uint8_t)DIN dataCommand:(uint8_t)DC chipEnable:(uint8_t)CE reset:(uint8_t)RST contrast:(uint8_t)contrast
{
  if ((self = [super init]))
    {
      _din = DIN;
      _sclk = SCLK;
      _dc = DC;
      _rst = RST;
      _cs = CE;
      cursor = SDKZeroPoint;
      textsize = 1;
      textcolor = BLACK;

      // set pin directions
      pinMode(_din, OUTPUT);
      pinMode(_sclk, OUTPUT);
      pinMode(_dc, OUTPUT);
      pinMode(_rst, OUTPUT);
      pinMode(_cs, OUTPUT);

      // toggle RST low to reset; CS low so it'll listen to us
      if (_cs > 0)
	digitalWrite(_cs, LOW);

      digitalWrite(_rst, LOW);
      delayMillis(500);
      digitalWrite(_rst, HIGH);

      // get into the EXTENDED mode!
      [self command:PCD8544_FUNCTIONSET | PCD8544_EXTENDEDINSTRUCTION];

      // LCD bias select (4 is optimal?)
      [self command:PCD8544_SETBIAS | 0x4];

      // set VOP
      if (contrast > 0x7f)
	contrast = 0x7f;

      [self command: PCD8544_SETVOP | contrast]; // Experimentally determined

      // normal mode
      [self command:PCD8544_FUNCTIONSET];

      // Set display to Normal
      [self command:PCD8544_DISPLAYCONTROL | PCD8544_DISPLAYNORMAL];

      // set up a bounding box for screen updates
      updateBoundingBox(0, 0, LCDWIDTH-1, LCDHEIGHT-1);    
    }
  return self;
}

- (void) command:(uint8_t) c;
{
  digitalWrite( _dc, LOW);
  LCDspiwrite(c);
}

- (void) data:(uint8_t) c
{
  LCDdata(c);
}

- (void) SPIWrite:(uint8_t)c
{
  LCDspiwrite(c);
}


- (void) shiftOut:(uint8_t)val dataPin:(uint8_t)dp withClock:(uint8_t)clockPin andOrder:(uint8_t)bitOrder
{
   shiftOut(dp, clockPin, bitOrder, val);
}

- (void)display
{
  uint8_t col, maxcol, p;

  for(p = 0; p < 6; p++)
    {
#ifdef enablePartialUpdate
      // check if this page is part of update
      if ( yUpdateMin >= ((p+1)*8) )
	{
	  continue;   // nope, skip it!
	}
      if (yUpdateMax < p*8)
	{
	  break;
	}
#endif

      [self command: PCD8544_SETYADDR | p];


#ifdef enablePartialUpdate
      col = xUpdateMin;
      maxcol = xUpdateMax;
#else
      // start at the beginning of the row
      col = 0;
      maxcol = LCDWIDTH-1;
#endif

      [self command:PCD8544_SETXADDR | col];

      for(; col <= maxcol; col++) {
	//uart_putw_dec(col);
	//uart_putchar(' ');
	LCDdata(pcd8544_buffer[(LCDWIDTH*p)+col]);
      }
    }

  [self command: PCD8544_SETYADDR];  // no idea why this is necessary but it is to finish the last byte?
#ifdef enablePartialUpdate
  xUpdateMin = LCDWIDTH - 1;
  xUpdateMax = 0;
  yUpdateMin = LCDHEIGHT-1;
  yUpdateMax = 0;
#endif

}

- (void) setContrast:(uint8_t)val
{
  if (val > 0x7f)
    {
      val = 0x7f;
    }
  [self command: PCD8544_FUNCTIONSET | PCD8544_EXTENDEDINSTRUCTION];
  [self command: PCD8544_SETVOP | val];
  [self command: PCD8544_FUNCTIONSET];
}

// clear everything
- (void)clear
{
  uint32_t i;
  for ( i = 0; i < LCDWIDTH*LCDHEIGHT/8 ; i++)
    pcd8544_buffer[i] = 0;
  updateBoundingBox(0, 0, LCDWIDTH-1, LCDHEIGHT-1);
  cursor = SDKZeroPoint;
}

- (void) showLogo
{
  uint32_t i;
  for (i = 0; i < LCDWIDTH * LCDHEIGHT / 8; i++  )
    {
      pcd8544_buffer[i] = pi_logo[i];
    }
  [self display];
}

- (void) setPixel:(SDKPoint)p withColor:(uint8_t) color
{
  if ((p.x >= LCDWIDTH) || (p.y >= LCDHEIGHT))
    return;

  // x is which column
  if (color)
    pcd8544_buffer[p.x+ (p.y/8)*LCDWIDTH] |= _BV(p.y%8);
  else
    pcd8544_buffer[p.x+ (p.y/8)*LCDWIDTH] &= ~_BV(p.y%8);
  updateBoundingBox(p.x,p.y,p.x,p.y);
}

- (uint8_t) getPixel:(SDKPoint)p
{
  if ((p.x >= LCDWIDTH) || (p.y >= LCDHEIGHT))
    return 0;

  return (pcd8544_buffer[p.x+ (p.y/8)*LCDWIDTH] >> (7-(p.y%8))) & 0x1;
}

- (void) setCursorAt:(SDKPoint)point
{
  cursor = point;
}

- (void) setTextColor:(uint8_t)color
{
  textcolor = color;
}

- (void) drawChar:(char)ch atPoint:(SDKPoint)p
{
  if (p.y >= LCDHEIGHT) return;
  if ((p.x+5) >= LCDWIDTH) return;
  uint8_t i,j;
  for ( i =0; i<5; i++ )
    {
      uint8_t d = *(font+(ch*5)+i);
      uint8_t j;
      for (j = 0; j<8; j++)
	{
	  if (d & _BV(j))
	    {
	      my_setpixel(p.x+i, p.y+j, textcolor);
	    }
	  else
	    {
	      my_setpixel(p.x+i, p.y+j, !textcolor);
	    }
	}
    }

  for ( j = 0; j<8; j++)
    {
      my_setpixel(p.x+5, p.y+j, !textcolor);
    }
  updateBoundingBox(p.x, p.y, p.x+5, p.y+8);
}

- (void) writeChar:(uint8_t)c
{
  if (c == '\n')
    {
      cursor.y += textsize*8;
      cursor.x = 0;
    }
  else if (c == '\r')
    {
      // skip em
    }
  else
    {
      [self drawChar:c atPoint:cursor];
      cursor.x += textsize*6;
      if (cursor.x >= (LCDWIDTH-5))
	{
	  cursor.x = 0;
	  cursor.y+=8;
	}
      if (cursor.y >= LCDHEIGHT)
	cursor.y = 0;
    }
}

- (void)drawCString:(char*)c atPoint:(SDKPoint)p
{
  cursor = p;
  while (*c)
    {
      [self writeChar:*c++];
    }
}

- (void) fillCircleWithCenter:(SDKPoint)center radius:(uint8_t)r color:(uint8_t)c
{
  LCDfillcircle(center.x, center.y, r, c);
}

- (void) strokeCircleWithCenter:(SDKPoint)center radius:(uint8_t)r color:(uint8_t)c
{
  LCDdrawcircle(center.x, center.y, r, c);
}

- (void) fillRect:(SDKRect)rect color:(uint8_t)c
{
  LCDfillrect(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height, c);
}

- (void) strokeRect:(SDKRect)rect color:(uint8_t)c
{
  LCDfillrect(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height, c);
}

// bresenham's algorithm - thx wikpedia
- (void) strokeLineFromPoint:(SDKPoint)p1 toPoint:(SDKPoint)p2 color:(uint8_t)c
{
  uint8_t steep = abs(p2.y - p1.y) > abs(p2.x - p1.x);
  if (steep)
    {
      swap(p1.x, p1.y);
      swap(p2.x, p2.y);
    }

  if (p1.x > p2.x)
    {
      swap(p1.x, p2.x);
      swap(p1.y, p2.y);
    }

  // much faster to put the test here, since we've already sorted the points
  updateBoundingBox(p1.x, p1.y, p2.x, p2.y);

  uint8_t dx, dy;
  dx = p2.x - p1.x;
  dy = abs(p2.y - p2.y);

  int8_t err = dx / 2;
  int8_t ystep;

  if (p1.y < p2.y)
    {
      ystep = 1;
    } else
    {
      ystep = -1;
    }

  for (; p1.x<=p2.x; p1.x++)
    {
      if (steep)
	{
	  my_setpixel(p1.y, p1.x, c);
	}
      else
	{
	  my_setpixel(p1.x, p1.y, c);
	}
      err -= dy;
      if (err < 0)
	{
	  p1.x += ystep;
	  err += dx;
	}
    }
}

- (void) drawBitmap:(uint8_t*)bmp inRect:(SDKRect)rect color:(uint8_t)color
{
  LCDdrawbitmap(rect.origin.x, rect.origin.y, bmp, rect.size.height, rect.size.width, color);
}

@end





// reduces how much is refreshed, which speeds it up!
// originally derived from Steve Evans/JCW's mod but cleaned up and optimized
//#define enablePartialUpdate

static void my_setpixel(uint8_t x, uint8_t y, uint8_t color)
{
	if ((x >= LCDWIDTH) || (y >= LCDHEIGHT))
		return;
	// x is which column
	if (color)
		pcd8544_buffer[x+ (y/8)*LCDWIDTH] |= _BV(y%8);
	else
		pcd8544_buffer[x+ (y/8)*LCDWIDTH] &= ~_BV(y%8);
}







void LCDdrawbitmap(uint8_t x, uint8_t y,const uint8_t *bitmap, uint8_t w, uint8_t h,uint8_t color)
{
	uint8_t j,i;
	for ( j=0; j<h; j++)
	{
		for ( i=0; i<w; i++ )
		{
			if (*(bitmap + i + (j/8)*w) & _BV(j%8))
			{
				my_setpixel(x+i, y+j, color);
			}
		}
	}
	updateBoundingBox(x, y, x+w, y+h);
}




// filled rectangle
void LCDfillrect(uint8_t x, uint8_t y, uint8_t w, uint8_t h,  uint8_t color)
{
	// stupidest version - just pixels - but fast with internal buffer!
	uint8_t i,j;
	for ( i=x; i<x+w; i++)
	{
		for ( j=y; j<y+h; j++)
		{
			my_setpixel(i, j, color);
		}
	}
	updateBoundingBox(x, y, x+w, y+h);
}

// draw a rectangle
void LCDdrawrect(uint8_t x, uint8_t y, uint8_t w, uint8_t h, uint8_t color)
{
	// stupidest version - just pixels - but fast with internal buffer!
	uint8_t i;
	for ( i=x; i<x+w; i++) {
		my_setpixel(i, y, color);
		my_setpixel(i, y+h-1, color);
	}
	for ( i=y; i<y+h; i++) {
		my_setpixel(x, i, color);
		my_setpixel(x+w-1, i, color);
	}

	updateBoundingBox(x, y, x+w, y+h);
}

// draw a circle outline
void LCDdrawcircle(uint8_t x0, uint8_t y0, uint8_t r, uint8_t color)
{
	updateBoundingBox(x0-r, y0-r, x0+r, y0+r);

	int8_t f = 1 - r;
	int8_t ddF_x = 1;
	int8_t ddF_y = -2 * r;
	int8_t x = 0;
	int8_t y = r;

	my_setpixel(x0, y0+r, color);
	my_setpixel(x0, y0-r, color);
	my_setpixel(x0+r, y0, color);
	my_setpixel(x0-r, y0, color);

	while (x<y)
	{
		if (f >= 0)
		{
			y--;
			ddF_y += 2;
			f += ddF_y;
		}
		x++;
		ddF_x += 2;
		f += ddF_x;

		my_setpixel(x0 + x, y0 + y, color);
		my_setpixel(x0 - x, y0 + y, color);
		my_setpixel(x0 + x, y0 - y, color);
		my_setpixel(x0 - x, y0 - y, color);

		my_setpixel(x0 + y, y0 + x, color);
		my_setpixel(x0 - y, y0 + x, color);
		my_setpixel(x0 + y, y0 - x, color);
		my_setpixel(x0 - y, y0 - x, color);

	}
}

void LCDfillcircle(uint8_t x0, uint8_t y0, uint8_t r, uint8_t color)
{
	updateBoundingBox(x0-r, y0-r, x0+r, y0+r);
	int8_t f = 1 - r;
	int8_t ddF_x = 1;
	int8_t ddF_y = -2 * r;
	int8_t x = 0;
	int8_t y = r;
	uint8_t i;

	for (i=y0-r; i<=y0+r; i++)
	{
		my_setpixel(x0, i, color);
	}

	while (x<y)
	{
		if (f >= 0)
		{
			y--;
			ddF_y += 2;
			f += ddF_y;
		}
		x++;
		ddF_x += 2;
		f += ddF_x;

		for ( i=y0-y; i<=y0+y; i++)
		{
			my_setpixel(x0+x, i, color);
			my_setpixel(x0-x, i, color);
		}
		for ( i=y0-x; i<=y0+x; i++)
		{
			my_setpixel(x0+y, i, color);
			my_setpixel(x0-y, i, color);
		}
	}
}

void LCDspiwrite(uint8_t c)
{
	shiftOut(_din, _sclk, MSBFIRST, c);
}

void LCDdata(uint8_t c)
{
	digitalWrite(_dc, HIGH);
	LCDspiwrite(c);
}



// bitbang serial shift out on select GPIO pin. Data rate is defined by CPU clk speed and CLKCONST_2. 
// Calibrate these value for your need on target platform.
void shiftOut(uint8_t dataPin, uint8_t clockPin, uint8_t bitOrder, uint8_t val)
{
	uint8_t i;
	uint32_t j;

	for (i = 0; i < 8; i++)  {
		if (bitOrder == LSBFIRST)
			digitalWrite(dataPin, !!(val & (1 << i)));
		else
			digitalWrite(dataPin, !!(val & (1 << (7 - i))));

		digitalWrite(clockPin, HIGH);
		for (j = CLKCONST_2; j > 0; j--); // clock speed, anyone? (LCD Max CLK input: 4MHz)
		digitalWrite(clockPin, LOW);
	}
}

void delayMillis(uint32_t t)
{
  // wiring pi takes in account small delays and uses loops, we should never be in that case though
  delayMicroseconds(t * 1000);
}
