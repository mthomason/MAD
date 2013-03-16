//
//  UIDevice+Hack.m
//  Reports
//
//  Created by Michael Thomason on 3/16/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "UIDevice+Hack.h"

@implementation UIDevice (Hack)

+ (BOOL)isPad {
    
    static NSNumber *isPad;
    if (!isPad) {
        isPad = @([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);
    }
    return [isPad boolValue];
}

@end
