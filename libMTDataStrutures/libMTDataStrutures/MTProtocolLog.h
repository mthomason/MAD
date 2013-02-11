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

- (NSString *)toString;
- (NSString *)toStringDebug;
- (NSString *)toStringHumanReadable;

@optional

- (NSString *)toStringExpressive;
- (NSString *)toStringSymbolic;
- (NSString *)toStringName;
- (NSAttributedString *)toAttributedString;

@end