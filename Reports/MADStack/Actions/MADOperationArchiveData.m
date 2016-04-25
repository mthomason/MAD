//
//  MADOperationArchiveData.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/11/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationArchiveData.h"
#import <Foundation/NSData.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSException.h>
#import <Foundation/NSError.h>
#import <Foundation/NSKeyedArchiver.h>

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

    BOOL success = NO;
    NSError *error = nil;

    @try {

        NSData *d = [NSKeyedArchiver archivedDataWithRootObject:self.object];
        success = [d writeToURL:self.url options:NSDataWritingAtomic error:&error];
        
    } @catch (NSException *exception) {
        
    } @finally {

        self.object = nil;
        if (success) {
            [self finish];
        } else {
            NSError *err = error != nil ? error.copy : nil;
            [self finishWithError:err];
        }

    }

}

@end
