//
//  MADRefreshOperationReload.m
//  MAD Designer
//
//  Created by Michael Thomason on 4/3/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADRefreshOperationReload.h"
#import <MAD/MADocument.h>

#import <os/log.h>

@interface MADRefreshOperationReload ()

    @property (nonatomic, weak) MADocument *document;

@end

@implementation MADRefreshOperationReload

- (BOOL)isAsynchronous { return NO; }

- (void)execute {

    if (self.cancelled) {
        return [self finish];
    }

    [self finish];
}

@end
