//
//  MADOperation.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/11/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADOperation_h
#define MAD_Designer_MADOperation_h

#import <Foundation/NSOperation.h>

typedef NS_ENUM(char, MADOperationState) {
    nonready,
    ready,
    executing,
    finished,
    error,
    cancelled,
    usercancelled
};

@interface MADOperation : NSOperation

    - (void)setStateCanceled;
    - (void)setStateError;
    - (void)setStateFinished;
    - (void)setStateExecuting;
    - (void)setStateUserCancelled;

@end

#endif
