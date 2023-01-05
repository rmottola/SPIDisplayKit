/*
   Project: SPIDisplayKit

   Copyright (C) 2022-2023 Riccardo Mottola

   Author: Riccardo Mottola

   Created: 2022-12-31 13:33:50 +0000 by pi

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

#import "SPIDisplayKit/SPITextView.h"
#import "SPIDisplayKit/PCD8544Display.h"

@implementation SPITextView

- (id)initWithDisplay:(PCD8544Display *)disp
{
  if ((self = [super init]))
    {
      textLines = [[NSMutableArray alloc] initWithCapacity:4];
      maxWidth = 15;
      maxHeight = 6;
      lcd = disp;
    }
  return self;
}

- (void)setLine:(NSUInteger)line toString:(NSString *)aStr
{
  NSUInteger lastLine;
  
  lastLine = [textLines count]-1;
  [textLines replaceObjectAtIndex:lastLine withObject:aStr];
}

- (void)appendLine:(NSString *)aStr;
{
  [textLines addObject: aStr];
}

- (void)draw
{
  NSUInteger lastLine;
  NSUInteger i;
  NSMutableArray *linesToDraw;
  NSUInteger offset;

  // extract a subarray of strings to draw
  // if there is no scrollback, it is just the first lines
  // otherwise it is from the end the maximum display height
  linesToDraw = [[NSMutableArray alloc] initWithCapacity:maxHeight];
  offset = 0;
  if ([textLines count] > maxHeight)
    offset = [textLines count]-maxHeight;
  for (i = offset; i < [textLines count]; i++)
    [linesToDraw addObject:[textLines objectAtIndex:i]];

  [lcd clear];
  for (i = 0; i < [linesToDraw count]; i++)
    {
      NSString *lineStr;
      NSString *displayStr;
      char *cStr;

      lineStr = [linesToDraw objectAtIndex:i];
      displayStr = lineStr;
      if ([displayStr length] > maxWidth)
	{
	  displayStr = [lineStr substringWithRange:NSMakeRange(0,maxWidth)];
	}
      NSLog(@"draw |%@| of |%@|", displayStr, lineStr);
      cStr = [displayStr cString];
      [lcd drawCString: cStr atPoint:SDKMakePoint(0,i*8)];
      [lcd display];
    }
  [linesToDraw release];
}

@end
