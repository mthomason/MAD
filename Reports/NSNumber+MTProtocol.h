//
//  NSNumber+MTProtocol.h
//  Reports
//
//  Created by Michael Thomason on 12/16/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTProtocolCompare.h"
#import "MTProtocolLog.h"

@interface NSNumber (MTProtocol) <MTProtocolCompare, MTProtocolLog>

@end