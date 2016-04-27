//
//  MADFileInfo.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADFileInfo.h"
#import "MADFileUtilities.h"
#import <Foundation/NSURL.h>
#import <Foundation/NSFileManager.h>
#import <dispatch/dispatch.h>

static const char * QueueFileInfo = "com.everydayapps.mad.fileinfo";

@interface MADFileInfo () {
    dispatch_queue_t _fetchQueue;
}

    @property (nonatomic, strong, readonly) dispatch_queue_t fetchQueue;

@end

@implementation MADFileInfo

#pragma mark - Initialization

- (instancetype)initWithURL:(NSURL *)URL {
    
    if (self = [super init]) {
        _URL = URL.copy;
    }
    
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    id copy = [[[self class] alloc] initWithURL:self.URL];
    return copy;
}

#pragma mark - Fetch Methods

- (dispatch_queue_t)fetchQueue {
    if (_fetchQueue == nil) {
        _fetchQueue = dispatch_queue_create(QueueFileInfo, DISPATCH_QUEUE_SERIAL);
    }
    return _fetchQueue;
}

- (void)fetchInfoWithCompletionHandler:(void (^)(void))completionHandler {
    dispatch_async(self.fetchQueue, ^{
        completionHandler();
        return;
    });
}

#pragma mark - Property Overrides

- (NSString *)name {
    NSString *displayName = [[NSFileManager defaultManager] displayNameAtPath:self.URL.path];
    return displayName.stringByDeletingPathExtension;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[MADFileInfo class]]) return NO;
    return [self.URL isEqual:((MADFileInfo *)object).URL];

}

@end
