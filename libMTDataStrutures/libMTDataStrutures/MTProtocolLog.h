//
//  MTProtocolLog.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/13/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MTProtocolLog <NSObject>

@required

- (NSString *)humanReadableObjectIdentifier;
- (NSString *)toString;
- (NSString *)toStringForDebugging;

@optional

@end