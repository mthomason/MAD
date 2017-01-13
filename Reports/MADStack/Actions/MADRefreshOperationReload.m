//
//  MADRefreshOperationReload.m
//  MAD Designer
//
//  Created by Michael Thomason on 4/3/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADRefreshOperationReload.h"
#import <MAD/MADocument.h>

@interface MADRefreshOperationReload ()

    @property (nonatomic, weak) MADocument *document;

@end

@implementation MADRefreshOperationReload

- (BOOL)isAsynchronous { return NO; }

- (void)execute {
    [self finish];
}

@end
