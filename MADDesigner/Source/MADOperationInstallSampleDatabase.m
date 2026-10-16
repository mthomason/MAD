//
//  MADInstallOperationSampleDatabase.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/11/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADOperationInstallSampleDatabase.h"
#import <MADFoundation/madlog.h>

#import <MAD/MADConstants.h>
#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADApplicationProtocol.h>
#import <MADFoundation/MADURLFactory.h>

#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSBundle.h>
#import <UIKit/NSDataAsset.h>

NSString * const MADUpgradeInstalledSamples			= @"MADUpgradeInstalledSamples";
NSString * const MADUpgradeInstalledChinook			= @"MADUpgradeInstalledChinook";

static NSString * const MTSampleDatabaseChinook		= @"chinook";
static NSString * const MTDocumentExtentionSqlite3	= @"sqlite3";

@implementation MADOperationInstallSampleDatabase

- (void)dealloc { }


- (BOOL)isAsynchronous { return YES; }

- (void)execute {
	if (self.cancelled) return [self finish];

	NSURL *fileURL, *databaseURL;
	NSError *error = nil;
	NSDataAsset *sampleDB;

	BOOL installed = [[NSUserDefaults standardUserDefaults] boolForKey:MADUpgradeInstalledChinook];

	if (installed) goto FINISH;

	
	fileURL = [MADOperationInstallSampleDatabase newApplicationBundleSampleDatabaseChinook];
	databaseURL = [MADOperationInstallSampleDatabase newApplicationSupportSampleDatabaseChinook];
	
	if (databaseURL == nil) goto FINISH;
	
	sampleDB = [[NSDataAsset alloc] initWithName:MTSampleDatabaseChinook];
	installed = [sampleDB.data writeToURL:databaseURL options:NSDataWritingAtomic error:&error];
	
	if (installed) {
		NSString *filepath = databaseURL.path;
		if (self.cancelled) return [self finish];
		if ([[NSFileManager defaultManager] fileExistsAtPath:filepath]) {
			if (self.cancelled) return [self finish];
			[[NSUserDefaults standardUserDefaults] setBool: YES
													forKey: MADUpgradeInstalledChinook];
			[[NSUserDefaults standardUserDefaults] synchronize];
		}
	}

	FINISH:;
	[self finish];

}

+ (NSURL *)newApplicationBundleSampleDatabaseChinook {
	return [[NSBundle mainBundle] URLForResource: MTSampleDatabaseChinook
								   withExtension: MTDocumentExtentionSqlite3];
}

+ (NSURL *)newApplicationSupportSampleDatabaseChinook {
	return [MADURLFactory newURLApplicationSupportFile: MTSampleDatabaseChinook
											 extension: MTDocumentExtentionSqlite3];
}

@end
