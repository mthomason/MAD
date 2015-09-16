//
//  NSString+MTProtocol.h
//  Reports
//
//  Created by Michael Thomason on 12/16/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_NSString_MTProtocol_h
#define Reports_NSString_MTProtocol_h

#import <Foundation/Foundation.h>
#import <MADDataStructures/MADDataStructures.h>

@interface NSString (MTProtocol) <MTProtocolCompare, MTProtocolLog>

@end

#endif
