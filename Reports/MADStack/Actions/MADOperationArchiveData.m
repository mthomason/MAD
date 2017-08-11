//
//  MADOperationArchiveData.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/11/15.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationArchiveData.h"
#import <Foundation/NSData.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSException.h>
#import <Foundation/NSError.h>
#import <Foundation/NSKeyedArchiver.h>

#import <os/log.h>

@interface MADOperationArchiveData ()
    @property (nonatomic, copy) NSURL *url;
    @property (nonatomic, strong) id <NSCoding> object;
@end

@implementation MADOperationArchiveData

- (instancetype)initWithURL:(NSURL *)url andObject:(id <NSCoding>)object {
    if (self = [super init]) {
        _url = url.copy;
        self.object = object;
    }
    return self;
}

- (BOOL)isAsynchronous {
    return YES;
}

- (void)start {

    if (self.cancelled) {
        [self finish];
    }
    
    BOOL success = NO;
    NSError *error = nil;

    @try {

        id <NSCoding> obj = self.object;
        NSData *d = [NSKeyedArchiver archivedDataWithRootObject:obj];
        success = [d writeToURL:self.url options:NSDataWritingAtomic error:&error];
        //success = [d writeToURL:self.url atomically:NO];
        obj = nil;
        d = nil;
        self.object = nil;
        
    } @catch (NSException *exception) {
        
    } @finally {

        if (success) {
            [self finish];
        } else {
            NSError *err = error != nil ? error.copy : nil;
            [self finishWithError:err];
        }

    }

}

@end
