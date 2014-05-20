//
//  MTObject.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/11/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTProtocolLog.h"
#import "MTProtocolCompare.h"

@interface MTObject : NSObject <MTProtocolCompare, MTProtocolLog>

@property (strong) id object;

+ (id)objectWithObject:(id)object;

@end