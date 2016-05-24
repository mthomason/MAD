//
//  MADBlockObserver.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/17/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADBlockObserver_h
#define MAD_Designer_MADBlockObserver_h

#import <Foundation/NSObject.h>
#import "MADOperationObserver.h"

@class MADOperation;
@class NSOperation;

@interface MADBlockObserver : NSObject
                        <MADOperationObserver>

    - (instancetype)initWithStartHandler:(void(^)(MADOperation *))startHandler
                          produceHandler:(void(^)(MADOperation *, NSOperation *))produceHandler
                           finishHandler:(void(^)(MADOperation *, NSArray *))finishHandler;

@end

#endif
