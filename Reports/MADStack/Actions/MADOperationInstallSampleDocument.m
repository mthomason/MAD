//
//  MADOperationInstallSampleDocument.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/11/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADOperationInstallSampleDocument.h"
#import <UIKit/NSDataAsset.h>
#import <Foundation/NSString.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSURL.h>
#import <MADFoundation/MADURLFactory.h>

#import <os/log.h>

@interface MADOperationInstallSampleDocument ()

	@property (nonatomic, copy) NSString *filename;
	@property (nonatomic, copy) NSString *fileExtension;
	@property (nonatomic, copy) NSString *groupIdentifier;
	@property (nonatomic, copy) NSString *installFlag;

@end

@implementation MADOperationInstallSampleDocument

- (void)dealloc {
	//NSLog(@"dealloc MADOperationInstallSampleDocument");
}

- (instancetype)initWithFilename:(NSString *)filename fileExtension:(NSString *)fileExtension
				 groupIdentifier:(NSString *)groupIdentifier installFlag:(NSString *)installFlag {

	if (self = [super init]) {
		
		_filename = filename.copy;
		_fileExtension = fileExtension.copy;
		_groupIdentifier = groupIdentifier.copy;
		_installFlag = installFlag.copy;
		
	}
	return self;
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {

	if (self.cancelled) {
		return [self finish];
	}
	
	//[NSBundle bundleWithIdentifier:<#(nonnull NSString *)#>]
	
	BOOL installed = [[NSUserDefaults standardUserDefaults] boolForKey:_installFlag];
	if (!installed) {
		
	
		NSURL *localDocumentsDirectory = [MADURLFactory newURLLocalDocumentsDirectoryForGroupIdentifier:_groupIdentifier];
		NSURL *destination = [localDocumentsDirectory URLByAppendingPathComponent: _filename
																	  isDirectory: NO];
		
		// !!!: Do an extra check to hanle the case of upgrades.
		BOOL isDirectory;
		NSString *path = destination.path;
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
			
		}
		[[NSUserDefaults standardUserDefaults] setBool:installed forKey:_installFlag];
	}
	[self finish];
}

- (NSURL *)resourceUrl {
	return [[NSBundle mainBundle] URLForResource: _filename
								   withExtension: _fileExtension];
}

@end
