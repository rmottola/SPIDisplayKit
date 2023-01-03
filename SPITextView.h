/*
   Project: SPIDisplayKit

   Copyright (C) 2022-2023 Free Software Foundation

   Author: Riccardo Mottola

   Created: 2022-12-31

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

#ifndef _SPITEXTVIEW_H_
#define _SPITEXTVIEW_H_

#import <Foundation/Foundation.h>

@class PCD8544Display;

@interface SPITextView : NSObject
{
  PCD8544Display *lcd;
  NSMutableArray *textLines;
  NSInteger scrollbackLines;
  NSUInteger maxWidth;
  NSUInteger maxHeigth;
}

- (void)setLine:(NSUInteger)line toString:(NSString *)aStr;
- (void)appendLine:(NSString *)aStr;

@end

#endif // _SPITEXTVIEW_H_

