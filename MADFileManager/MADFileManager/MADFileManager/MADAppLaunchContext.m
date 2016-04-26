//
//  MADAppLaunchContext.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/14/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADAppLaunchContext.h"
#import <UIKit/UIDocument.h>
#import <Foundation/NSUserActivity.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSURL.h>

NSString * const MADAppConfigurationUserActivityListURLPathUserInfoKey = @"MADUserInfoKeyFileURL";

@implementation MADAppLaunchContext

- (instancetype)initWithUserActivity:(NSUserActivity *)userActivity {
    self = [super init];
    
    if (self) {
        NSParameterAssert(userActivity.userInfo != nil);
        /*
         The URL may be provided as either a URL or a URL path via separate keys. Check first for
         `NSUserActivityDocumentURLKey`, if not provided, obtain the path and create a file URL from it.
         */
        _fileURL = userActivity.userInfo[NSUserActivityDocumentURLKey];
        
        if (!_fileURL) {
            NSString *fileInfoFilePath = userActivity.userInfo[MADAppConfigurationUserActivityListURLPathUserInfoKey];
            
            NSAssert(fileInfoFilePath != nil, @"The `userInfo` dictionary provided did not contain a URL or a URL path.");
            
            _fileURL = [NSURL fileURLWithPath:fileInfoFilePath isDirectory:NO];
        }
        
        NSAssert(_fileURL != nil, @"`listURL must not be `nil`.");
    }
    
    return self;
}

- (instancetype)initWithFileURL:(NSURL *)fileURL {
    self = [super init];
    
    if (self) {
        NSParameterAssert(fileURL.scheme != nil && [fileURL.scheme isEqualToString:@"lister"]);
        
        NSParameterAssert(fileURL.path != nil);
        // Construct a file URL from the path of the lister:// URL.

        _fileURL = [NSURL fileURLWithPath:fileURL.path isDirectory:NO];
        
        NSAssert(_fileURL != nil, @"`listURL must not be `nil`.");
    }
    
    return self;
}

@end
