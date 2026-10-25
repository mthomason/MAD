//
//  MADBlockObserver.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/17/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_Designer_MADBlockObserver_h
#define MAD_Designer_MADBlockObserver_h

#import <Foundation/NSObject.h>
#import <MADFoundation/MADOperationObserver.h>

NS_ASSUME_NONNULL_BEGIN

@interface MADBlockObserver : NSObject <MADOperationObserver>

- (instancetype)initWithStartHandler:(nullable void(^)(MADOperation *))startHandler
					  produceHandler:(nullable void(^)(MADOperation *, NSOperation *))produceHandler
					   finishHandler:(nullable void(^)(MADOperation *, NSArray <NSError *> *))finishHandler;

- (instancetype)initWithFinishHandler:(nullable void(^)(MADOperation *, NSArray<NSError *> *))finishHandler;

@end

NS_ASSUME_NONNULL_END

#endif
