//
//  MADFileCoordinator.m
//  MADFileManager
//
//  Created by Michael Thomason on 4/25/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
#import "MADFileCoordinator.h"
#import "MADLocalFileCoordinator.h"
#if __APPLE__
#import "MADCloudFileCoordinator.h"
#endif
#import <MADFileManager/MADAppStorageOption.h>

#import <Foundation/NSURL.h>
#import <Foundation/NSException.h>

@implementation MADFileCoordinator

@synthesize delegate = _delegate;
@synthesize documentsDirectory = _documentsDirectory;

- (void)setDelegate:(id<MADFileCoordinatorDelegate>)delegate {
	if (_delegate != delegate) {
		_delegate = delegate;
	}
}

- (id <MADFileCoordinatorDelegate>)delegate {
	return _delegate;
}

- (void)setDocumentsDirectory:(NSURL *)documentsDirectory {
	if (_documentsDirectory != documentsDirectory) {
		_documentsDirectory = documentsDirectory.copy;
	}
}

- (NSURL *)documentsDirectory {
	return _documentsDirectory;
}

+ (instancetype)newFileCoordinatorWithPathExtension: (NSString *)pathExtension
									  storageOption: (MADAppStorage)storageOption
										 identifier: (NSString *)identifier
								  firstQueryHandler: (void (^)(void))firstQueryHandler {
	id fileCoordinator;
	if (storageOption != MADAppStorageCloud) {
		fileCoordinator = [[MADLocalFileCoordinator alloc] initWithPathExtension: pathExtension
																	  identifier: identifier
														 firstQueryUpdateHandler: firstQueryHandler];
	}  else {
#if __APPLE__
		fileCoordinator = [[MADCloudFileCoordinator alloc] initWithPathExtension: pathExtension
																	  identifier: identifier
														 firstQueryUpdateHandler: firstQueryHandler];
#else
		// The cloud coordinator is its NSMetadataQuery and does not come over;
		// asking for cloud storage off Apple is a programming error.
		@throw [NSException exceptionWithName:NSInternalInconsistencyException
									   reason:@"Cloud storage is not available off Apple."
									 userInfo:nil];
#endif
	}
	return fileCoordinator;
}

+ (instancetype)newFileCoordinatorWithLastPathComponent: (NSString *)lastPathComponent
										  storageOption: (MADAppStorage)storageOption
											 identifier: (NSString *)identifier
									  firstQueryHandler: (void (^)(void))firstQueryHandler {
	id fileCoordinator;
#if __APPLE__
	fileCoordinator = storageOption != MADAppStorageCloud ?
				[[MADLocalFileCoordinator alloc] initWithLastPathComponent: lastPathComponent
																identifier: identifier
												   firstQueryUpdateHandler: firstQueryHandler] :
				[[MADCloudFileCoordinator alloc] initWithLastPathComponent: lastPathComponent
																identifier: identifier
												   firstQueryUpdateHandler: firstQueryHandler];
#else
	if (storageOption == MADAppStorageCloud) {
		// The cloud coordinator is its NSMetadataQuery and does not come over;
		// asking for cloud storage off Apple is a programming error.
		@throw [NSException exceptionWithName:NSInternalInconsistencyException
									   reason:@"Cloud storage is not available off Apple."
									 userInfo:nil];
	}
	fileCoordinator = [[MADLocalFileCoordinator alloc] initWithLastPathComponent: lastPathComponent
																	  identifier: identifier
														 firstQueryUpdateHandler: firstQueryHandler];
#endif
	return fileCoordinator;
}

- (void)startQuery {
	NSString *reason = [NSString stringWithFormat:@"Must subclass: %@", NSStringFromSelector(_cmd)];
	@throw [NSException exceptionWithName: NSInternalInconsistencyException
								   reason: reason
								 userInfo: nil];
}
- (void)stopQuery {
	NSString *reason = [NSString stringWithFormat:@"Must subclass: %@", NSStringFromSelector(_cmd)];
	@throw [NSException exceptionWithName: NSInternalInconsistencyException
								   reason: reason
								 userInfo: nil];
}
- (void)removeFileAtURL:(NSURL *)URL {
	NSString *reason = [NSString stringWithFormat:@"Must subclass: %@", NSStringFromSelector(_cmd)];
	@throw [NSException exceptionWithName: NSInternalInconsistencyException
								   reason: reason
								 userInfo: nil];
}
- (void)duplicateFileAtURL:(NSURL *)URL {
	NSString *reason = [NSString stringWithFormat:@"Must subclass: %@", NSStringFromSelector(_cmd)];
	@throw [NSException exceptionWithName: NSInternalInconsistencyException
								   reason: reason
								 userInfo: nil];
}
- (void)renameFileAtURL:(NSURL *)URL toName:(NSString *)name {
	NSString *reason = [NSString stringWithFormat:@"Must subclass: %@", NSStringFromSelector(_cmd)];
	@throw [NSException exceptionWithName: NSInternalInconsistencyException
								   reason: reason
								 userInfo: nil];
}
- (void)createURLWithName:(NSString *)name
				extention:(NSString *)extention
				fileGroup:(NSString *)fileGroup {
	NSString *reason = [NSString stringWithFormat:@"Must subclass: %@", NSStringFromSelector(_cmd)];
	@throw [NSException exceptionWithName: NSInternalInconsistencyException
								   reason: reason
								 userInfo: nil];
}
- (BOOL)canCreateFileWithName:(NSString *)name extention:(NSString *)extention
					fileGroup:(NSString *)fileGroup {
	NSString *reason = [NSString stringWithFormat:@"Must subclass: %@", NSStringFromSelector(_cmd)];
	@throw [NSException exceptionWithName: NSInternalInconsistencyException
								   reason: reason
								 userInfo: nil];
}

- (void)refresh {
	NSString *reason = [NSString stringWithFormat:@"Must subclass: %@", NSStringFromSelector(_cmd)];
	@throw [NSException exceptionWithName: NSInternalInconsistencyException
								   reason: reason
								 userInfo: nil];
}

- (id)debugQuickLookObject {
	return [NSString stringWithFormat:@"--%@--\n", [NSStringFromClass([self class]) uppercaseString]];
}

@end
