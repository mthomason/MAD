//
//  MADAppLaunchContext.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/14/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#include <TargetConditionals.h>
#import "MADAppLaunchContext.h"
#if defined(__APPLE__) && TARGET_OS_IPHONE
#import <UIKit/UIDocument.h>
#else
static NSString * const NSUserActivityDocumentURLKey = @"NSUserActivityDocumentURL";
#endif
#import <Foundation/NSException.h>
#import <Foundation/NSUserActivity.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSURL.h>

static NSString * const MADAppConfigurationUserInfoKey = @"MADUserInfoKeyFileURL";

@implementation MADAppLaunchContext

- (instancetype)initWithUserActivity:(NSUserActivity *)userActivity {
	self = [super init];
	
	if (self) {
		NSParameterAssert(userActivity.userInfo != nil);
		/*
		 The URL may be provided as either a URL or a URL path via separate keys. Check first for
		 `NSUserActivityDocumentURLKey`, if not provided, obtain the path and create a file
		 URL from it.
		 */
		_fileURL = userActivity.userInfo[NSUserActivityDocumentURLKey];
		
		if (!_fileURL) {
			NSString *fileInfoFilePath;
			fileInfoFilePath = userActivity.userInfo[MADAppConfigurationUserInfoKey];
			
			NSAssert(fileInfoFilePath != nil,
					 @"The `userInfo` dictionary provided did not contain a URL or a URL path.");
			
			_fileURL = [NSURL fileURLWithPath:fileInfoFilePath isDirectory:NO];
		}
		
		NSAssert(_fileURL != nil, @"`listURL must not be `nil`.");
	}
	
	return self;
}

- (instancetype)initWithFileURL:(NSURL *)fileURL {
	if (self = [super init]) {
		NSParameterAssert(fileURL.scheme != nil && [fileURL.scheme isEqualToString:@"lister"]);
		
		NSParameterAssert(fileURL.path != nil);
		// Construct a file URL from the path of the lister:// URL.
		NSString *path = fileURL.path;
		_fileURL = path != nil ? [NSURL fileURLWithPath:path isDirectory:NO] : nil;
		
		NSAssert(_fileURL != nil, @"`listURL must not be `nil`.");
	}
	
	return self;
}

@end
