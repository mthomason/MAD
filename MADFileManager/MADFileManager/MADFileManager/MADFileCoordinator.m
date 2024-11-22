//
//  MADFileCoordinator.m
//  MADFileManager
//
//  Created by Michael Thomason on 4/25/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//
#import "MADFileCoordinator.h"
#import "MADLocalFileCoordinator.h"
#import "MADCloudFileCoordinator.h"
#import <MADFileManager/MADAppStorageOption.h>

#import <MADFoundation/MADAssert.h>
#import <Foundation/NSURL.h>

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
		fileCoordinator = [[MADCloudFileCoordinator alloc] initWithPathExtension: pathExtension
																	  identifier: identifier
														 firstQueryUpdateHandler: firstQueryHandler];
	}
	return fileCoordinator;
}

+ (instancetype)newFileCoordinatorWithLastPathComponent: (NSString *)lastPathComponent
										  storageOption: (MADAppStorage)storageOption
											 identifier: (NSString *)identifier
									  firstQueryHandler: (void (^)(void))firstQueryHandler {
	id fileCoordinator;
	fileCoordinator = storageOption != MADAppStorageCloud ?
				[[MADLocalFileCoordinator alloc] initWithLastPathComponent: lastPathComponent
																identifier: identifier
												   firstQueryUpdateHandler: firstQueryHandler] :
				[[MADCloudFileCoordinator alloc] initWithLastPathComponent: lastPathComponent
																identifier: identifier
												   firstQueryUpdateHandler: firstQueryHandler];
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

- (id)debugQuickLookObject {
	NSMutableString *debug = [[NSMutableString alloc] init];
	NSString *classname = NSStringFromClass([self class]);
	id uppercaseClassname = [classname uppercaseString];
	[debug appendFormat:@"--%@--\n", uppercaseClassname];
	return debug;
}

@end
