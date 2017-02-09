//
//  MADNotificationFileUpdate.m
//  MAD
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADNotificationFileUpdate.h"
#import <Foundation/NSException.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSURL.h>
#import "MADProgress.h"

NSString * const MADNotificationIdentifierFileUpdate = @"MADProgressNotification";

@interface MADNotificationFileUpdate ()
  - (instancetype)init  NS_UNAVAILABLE;
    @property (nonatomic, copy) NSURL *url;
@end

@implementation MADNotificationFileUpdate

- (instancetype)init {
    id name = @"MADNotificationFileUpdateException";
    NSException *exception = [[NSException alloc] initWithName: name
                                                        reason: @"Not implemented"
                                                      userInfo: nil];
    @throw exception;
}

- (instancetype)initWithURL:(NSURL *)url {
    if (self = [super init]) {
        self.url = url.copy;
    }
    return self;
}

- (void)notify {
    NSURL *url = self.url.copy;
    NSNotification *notification = [NSNotification notificationWithName: MADNotificationIdentifierFileUpdate
                                                                 object: url
                                                               userInfo: nil];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

@end
