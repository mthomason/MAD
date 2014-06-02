//
//  NSString+Extras.h
//  Reports
//
//  Created by Michael Thomason on 12/1/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_NSString_Extras_h
#define Reports_NSString_Extras_h

#import <Foundation/Foundation.h>

@interface NSString (Extras)

+ (const char *)cStringFromString:(NSString *)theString;

@end

#endif
