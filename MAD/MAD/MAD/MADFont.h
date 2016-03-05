//
//  MTFont.h
//  Reports
//
//  Created by Michael Thomason on 1/1/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADFont_h
#define Reports_MADFont_h

#import <Foundation/NSObject.h>
#import <CoreGraphics/CGBase.h>

@interface MADFont : NSObject

    + (NSString *)defaultFamily;
    + (CGFloat)defaultSize;

@end

#endif
