//
//  MADLocalFileCoordinator.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADLocalFileCoordinator.h"
#import "MADFileCoordinatorProtocol.h"
#import "MADFileCoordinatorDelegate.h"
#import "MADDirectoryMonitor.h"
#import "MADFileUtilities.h"
#import "MADDirectoryMonitorProtocol.h"
#import "madlog.h"

#import <MADFoundation/MADURLFactory.h>

#import <Foundation/NSPredicate.h>
#import <Foundation/NSCompoundPredicate.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSFileManager.h>
#import <dispatch/queue.h>

@interface MADLocalFileCoordinator () <MADDirectoryMonitorProtocol>

@property (nonatomic, copy)     NSArray *currentLocalContents;
@property (nonatomic, copy)     NSPredicate *predicate;
@property (nonatomic, copy)   void (^firstQueryUpdateHandler)(void);
@property (nonatomic, copy)     NSString *fileGroup;
@property (nonatomic, strong)   MADDirectoryMonitor *directoryMonitor;

@end

@implementation MADLocalFileCoordinator

@synthesize delegate = _delegate;
@dynamic documentsDirectory;

#pragma mark - Initialization

- (instancetype)initWithPredicate: (NSPredicate *)predicate
					   identifier: (NSString *)fileGroup
		  firstQueryUpdateHandler: (void (^)(void))firstQueryUpdateHandler {

	if (self = [super init]) {

		_fileGroup = fileGroup.copy;
		_predicate = predicate.copy;
		
		self.firstQueryUpdateHandler = firstQueryUpdateHandler;
		
		NSURL *url = [MADURLFactory newURLLocalDocumentsDirectoryForGroupIdentifier:fileGroup];
		MADDirectoryMonitor *directoryMonitor = [[MADDirectoryMonitor alloc] initWithURL:url];
		self.directoryMonitor = directoryMonitor;
		self.directoryMonitor.delegate = self;
		self.currentLocalContents = @[];
	}
	
	return self;
}

- (instancetype)initWithPathExtension: (NSString *)pathExtension
						   identifier: (NSString *)fileGroup
			  firstQueryUpdateHandler: (void (^)(void))firstQueryUpdateHandler {
	if (self = [self initWithPredicate: [NSPredicate predicateWithFormat:@"(pathExtension = %@)", pathExtension]
							identifier: fileGroup
			   firstQueryUpdateHandler: firstQueryUpdateHandler]) {
		
	}
	return self;
}

- (instancetype)initWithLastPathComponent: (NSString *)lastPathComponent
							   identifier: (NSString *)fileGroup
				  firstQueryUpdateHandler: (void (^)(void))firstQueryUpdateHandler {
	if (self = [self initWithPredicate: [NSPredicate predicateWithFormat:@"(lastPathComponent = %@)", lastPathComponent]
							identifier: fileGroup
			   firstQueryUpdateHandler: firstQueryUpdateHandler]) {
		
		self.fileGroup = fileGroup;
	}
	
	return self;
}

#pragma mark - MADFileCoordinator

- (void)refresh {
	[self processChangeToLocalDocumentsDirectory];
}

- (void)startQuery {
	[self processChangeToLocalDocumentsDirectory];
	
	[self.directoryMonitor startMonitoring];
}

- (void)stopQuery {
	[self.directoryMonitor stopMonitoring];
}

- (void)removeFileAtURL:(NSURL *)URL {

	id <MADFileCoordinatorDelegate> __weak wdelegate = _delegate;
	[MADFileUtilities removeFileAtURL:URL completion:^(NSError *error) {
		
		id <MADFileCoordinatorDelegate> delegate = wdelegate;
		if (error) {
			[delegate fileCoordinatorDidFailRemovingFileAtURL: URL
													withError: error];
		} else {
			NSArray *inserts = @[],
					*removes = @[URL],
					*updates = @[];
			[delegate fileCoordinatorDidUpdateContentsWithInsertedURLs: inserts
														   removedURLs: updates
														   updatedURLs: removes];
		}
		
	}];
}

- (void)duplicateFileAtURL:(NSURL *)URL {

	id <MADFileCoordinatorDelegate> __weak wdelegate = _delegate;
	[MADFileUtilities duplicateFileAtURL:URL completion:^(NSURL *newURL, NSError *error) {
		id <MADFileCoordinatorDelegate> delegate = wdelegate;
		if (error) {
			[delegate fileCoordinatorDidFailDuplicatingFileAtURL:URL withError:error];
		} else {
			NSArray *inserts = @[newURL],
					*removes = @[],
					*updates = @[];
			[delegate fileCoordinatorDidUpdateContentsWithInsertedURLs: inserts
														   removedURLs: removes
														   updatedURLs: updates];
		}
	}];
}

- (void)renameFileAtURL:(NSURL *)URL toName:(NSString *)name {

	id <MADFileCoordinatorDelegate> __weak wdelegate = _delegate;
	[MADFileUtilities renameFileAtURL:URL toName:name completion:^(NSURL *sourceURL,
																   NSURL *newURL,
																   NSError *error) {
		id <MADFileCoordinatorDelegate> delegate = wdelegate;
		if (error) {
			[delegate fileCoordinatorDidFailRenamingFileAtURL:URL withError:error];
		} else {
			NSArray *inserts = @[newURL],
					*removes = @[sourceURL],
					*updates = @[];
		   [delegate fileCoordinatorDidUpdateContentsWithInsertedURLs:inserts
														  removedURLs:removes
														  updatedURLs:updates];
		}
	}];
}

- (void)createURLWithName:(NSString *)name
				extention:(NSString *)extention
				fileGroup:(NSString *)fileGroup {

	NSURL *documentURL = [MADURLFactory newURLLocalDocumentWithName:name
														  extention:extention
														  fileGroup:fileGroup];

	id <MADFileCoordinatorDelegate> __weak wdelegate = _delegate;
	[MADFileUtilities createFileAtURL:documentURL completion:^(NSError *error) {

		id <MADFileCoordinatorDelegate> delegate = wdelegate;
		if (error) {
			[delegate fileCoordinatorDidFailCreatingFileAtURL:documentURL withError:error];
		}
		else {
			NSArray *inserts = @[documentURL],
					*removes = @[],
					*updates = @[];
			[delegate fileCoordinatorDidUpdateContentsWithInsertedURLs: inserts
														   removedURLs: removes
														   updatedURLs: updates];
		}
	}];
}

- (BOOL)canCreateFileWithName:(NSString *)name
					extention:(NSString *)extention
					fileGroup:(NSString *)fileGroup {
	if (name.length <= 0) {
		return NO;
	}
	NSURL *documentURL = [MADURLFactory newURLLocalDocumentWithName: name
												   extention: extention
												   fileGroup: fileGroup];
	NSString *path = documentURL.path;
	if (path == nil) return NO;

	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *directoryPath = [path stringByDeletingLastPathComponent];
	BOOL isDirectory = NO;
	if (![fileManager fileExistsAtPath:directoryPath isDirectory:&isDirectory] || !isDirectory) {
		return NO;
	}
	return ![fileManager fileExistsAtPath:path];

}

#pragma mark - MADDirectoryMonitorProtocol

- (void)directoryMonitorDidObserveChange:(MADDirectoryMonitor *)directoryMonitor {
	[self processChangeToLocalDocumentsDirectory];
}

- (NSURL *)documentsDirectory {
	NSURL *url = [MADURLFactory newURLLocalDocumentsDirectoryForGroupIdentifier:self.fileGroup];
	return url;
}

#pragma mark - Convenience

- (void)processChangeToLocalDocumentsDirectory {

	NSString *fileGroup = self.fileGroup.copy;
	NSPredicate *predicate = self.predicate.copy;

	dispatch_queue_t defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);

	__weak MADLocalFileCoordinator *wself = self;

	void (^updateContent)(void) = ^{
		
		__strong MADLocalFileCoordinator *sself = wself;
		if (sself == nil) return;
		
		NSURL *url = [MADURLFactory newURLLocalDocumentsDirectoryForGroupIdentifier: fileGroup];
		os_log_debug(GetFileManagerLog(), "Sample report directory: %@", [url path]);

		NSError *error = nil;
		NSArray <NSURL *> *urls = [[NSFileManager defaultManager] contentsOfDirectoryAtURL: url
																includingPropertiesForKeys: nil
																				   options: NSDirectoryEnumerationSkipsPackageDescendants
																					 error: &error];
		if (error != nil) {
			os_log_debug(GetFileManagerLog(), "Failed to read directory contents: %@", error.localizedDescription);
			return; // Exit early if the directory cannot be read
		}
		
		NSArray <NSURL *> *localListURLs = [urls filteredArrayUsingPredicate:predicate];
		if (localListURLs.count > 0) {
			
			NSPredicate *containPredicate = [NSPredicate predicateWithFormat:@"self in %@", sself.currentLocalContents];
			NSPredicate *doesntContainPredicate = [NSCompoundPredicate notPredicateWithSubpredicate:containPredicate];
			NSArray <NSURL *> *insertedURLs = [localListURLs filteredArrayUsingPredicate:doesntContainPredicate];
			containPredicate = [NSPredicate predicateWithFormat:@"self in %@", localListURLs];
			doesntContainPredicate = [NSCompoundPredicate notPredicateWithSubpredicate:containPredicate];
			
			NSArray <NSURL *> *removedURLs = [sself.currentLocalContents filteredArrayUsingPredicate:doesntContainPredicate];
			NSArray <NSURL *> *emptyArray = @[];
			[sself.delegate fileCoordinatorDidUpdateContentsWithInsertedURLs: insertedURLs
																 removedURLs: removedURLs
																 updatedURLs: emptyArray];
			
			@synchronized (sself) {
				sself.currentLocalContents = localListURLs;
			}
		}
		
		if (sself.firstQueryUpdateHandler) {
			sself.firstQueryUpdateHandler();
		}
	};
	dispatch_async(defaultQueue, updateContent);
}

- (id)debugQuickLookObject {
	NSMutableString *debug = [[NSMutableString alloc] init];
	NSString *uppercaseClassname = [NSStringFromClass([self class]) uppercaseString];
	[debug appendFormat:@"--%@--\n", uppercaseClassname];
	[debug appendFormat:@"File group:\t%@\n", self.fileGroup];
	[debug appendFormat:@"Current contents:\t%@", self.currentLocalContents];
	return debug;
}

@end
