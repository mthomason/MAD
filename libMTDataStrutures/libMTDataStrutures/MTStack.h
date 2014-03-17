//
//  MTStack.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/11/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTObject.h"
#import "MTProtocolLog.h"

@interface MTStack : MTObject  <NSFastEnumeration,  MTProtocolLog>

- (void)push:(id)object;
- (id)pop;
- (BOOL)isEmpty;

@end