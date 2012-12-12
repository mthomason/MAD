//
//  MTStack.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/11/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTObject.h"

@interface MTStack : MTObject

- (void)push:(id)object;
- (id)pop;
- (BOOL)isEmpty;

@end