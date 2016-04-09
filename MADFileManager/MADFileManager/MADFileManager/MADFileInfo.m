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
#import <dispatch/dispatch.h>

@interface MADFileInfo ()

    @property (nonatomic, strong) dispatch_queue_t fetchQueue;

@end

@implementation MADFileInfo

#pragma mark - Initialization

- (instancetype)initWithURL:(NSURL *)URL {
    
    if (self = [super init]) {
        _fetchQueue = dispatch_queue_create("com.everydayapps.mad.fileinfo", DISPATCH_QUEUE_SERIAL);
        _URL = URL.copy;
    }
    
    return self;
}

#pragma mark - Fetch Methods

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
