//
//  MADFileInfo.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADFileInfo.h"
#import "MADFileUtilities.h"

#define AAPLListColorUndefined ((AAPLListColor)-1)

@interface MADFileInfo ()

@property (nonatomic, strong) dispatch_queue_t fetchQueue;

@end

@implementation MADFileInfo

#pragma mark - Initialization

- (instancetype)initWithURL:(NSURL *)URL {
    self = [super init];
    
    if (self) {
        _fetchQueue = dispatch_queue_create("com.everydayapps.mad.fileinfo", DISPATCH_QUEUE_SERIAL);
        _URL = URL;
    }
    
    return self;
}

#pragma mark - Fetch Methods

- (void)fetchInfoWithCompletionHandler:(void (^)(void))completionHandler {
    dispatch_async(self.fetchQueue, ^{
        /*
        if (self.color != AAPLListColorUndefined) {
            completionHandler();
            
            return;
        }
        
        [MADFileUtilities readListAtURL:self.URL withCompletionHandler:^(AAPLList *list, NSError *error) {
            dispatch_async(self.fetchQueue, ^{
                if (list) {
                    self.color = list.color;
                }
                else {
                    self.color = AAPLListColorGray;
                }
                
                completionHandler();
            });
        }];*/
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
    if (![object isKindOfClass:[MADFileInfo class]]) {
        return NO;
    }
    
    return [self.URL isEqual:[object URL]];
}

@end
