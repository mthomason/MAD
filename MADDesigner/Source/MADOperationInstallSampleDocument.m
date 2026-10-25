//
//  MADOperationInstallSampleDocument.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/11/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADOperationInstallSampleDocument.h"
#import <MADFoundation/madlog.h>

#import <MADFoundation/MADURLFactory.h>

#import <Foundation/NSString.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSURL.h>

#import <UIKit/NSDataAsset.h>

@interface MADOperationInstallSampleDocument ()

	@property (nonatomic, copy) NSString *filename;
	@property (nonatomic, copy) NSString *fileExtension;
	@property (nonatomic, copy) NSString *groupIdentifier;
	@property (nonatomic, copy) NSString *installFlag;

@end

@implementation MADOperationInstallSampleDocument

- (void)dealloc { }

- (instancetype)initWithFilename:(NSString *)filename fileExtension:(NSString *)fileExtension
				 groupIdentifier:(NSString *)groupIdentifier installFlag:(NSString *)installFlag {

	if (self = [super init]) {
		_sampleDocumentInstalled = false;
		_filename = [filename copy];
		_fileExtension = [fileExtension copy];
		_groupIdentifier = [groupIdentifier copy];
		_installFlag = [installFlag copy];
		
	}
	return self;
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
	if (self.cancelled) {
		return [self finish];
	}
	
	BOOL installed = [[NSUserDefaults standardUserDefaults] boolForKey:_installFlag];
	if (!installed) {
		
	
		NSURL *localDocumentsDirectory = [MADURLFactory newURLLocalDocumentsDirectoryForGroupIdentifier:_groupIdentifier];
		NSURL *destination = [localDocumentsDirectory URLByAppendingPathComponent: _filename
																	  isDirectory: NO];
		
		// !!!: Do an extra check to hanle the case of upgrades.
		BOOL isDirectory;
		NSString *path = destination.path;
		if (path != nil && path.length > 0) {
			installed = [[NSFileManager defaultManager] fileExistsAtPath: path
															 isDirectory: &isDirectory];
			
			if (self.cancelled) {
				return [self finish];
			}
			
			if (!installed) {
				destination = [destination URLByAppendingPathExtension: _fileExtension];
				
				NSError *error;
				NSDataAsset *sampleDoc = [[NSDataAsset alloc] initWithName:_filename];
				installed = [sampleDoc.data writeToURL:destination options:NSDataWritingAtomic error:&error];
				if (!installed && error != nil) {
					os_log_error(GetDesignerLog(), "%s: %@", __PRETTY_FUNCTION__, error);
				}
				_sampleDocumentInstalled = installed ? true : false;
			} else {
				_sampleDocumentInstalled = true;
			}
			[[NSUserDefaults standardUserDefaults] setBool:installed forKey:_installFlag];
		}
	}
	[self finish];
}

- (NSURL *)resourceUrl {
	return [[NSBundle mainBundle] URLForResource: _filename
								   withExtension: _fileExtension];
}

@end
