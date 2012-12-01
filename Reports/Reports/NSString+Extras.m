//
//  NSString+Extras.m
//  Reports
//
//  Created by Michael Thomason on 12/1/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "NSString+Extras.h"

@implementation NSString (Extras)

+ (const char *)cStringFromString:(NSString *)theString {
    NSMutableData *theData;
    NSLog(@"theString, %@", theString);
    if (! theString) {
        return (const char *)NULL;
    }
    
    theData = [NSMutableData dataWithData:[theString dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
    [theData increaseLengthBy:1];
    return (const char *)[theData bytes];
}

@end