//
//  MTProtocolCompare.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/14/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MTProtocolCompare <NSObject>

@required

- (BOOL)isEqualTo:(id)sender;

@optional

@end