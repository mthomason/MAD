//
//  MTProtocolEnumerator.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 2/3/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MTProtocolEnumerator <NSObject>


@optional

- (id)next;
- (id)previous;

@end