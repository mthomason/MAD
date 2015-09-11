//
//  MADOperationArchiveData.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/11/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationArchiveData.h"

@interface MADOperationArchiveData ()
    @property (nonatomic, strong) NSURL *url;
    @property (nonatomic, strong) id <NSCoding> object;
@end

@implementation MADOperationArchiveData

- (instancetype)initWithURL:(NSURL *)url andObject:(id <NSCoding>)object {
    if (self = [super init]) {
        self.url = url;
        self.object = object;
    }
    return self;
}

- (void)main {
    NSError *error = nil;
    NSData *d = [NSKeyedArchiver archivedDataWithRootObject:self.object];
    [d writeToURL:self.url options:NSDataWritingAtomic error:&error];
}

@end
