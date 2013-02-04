//
//  MTProtocolEnumerator.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 2/3/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MTProtocolEnumerator <NSObject>

- (id)next;
- (id)previous;

@optional

- (id)first;
- (id)last;

@end