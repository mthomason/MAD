//
//  MADFilesController.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADFilesController.h"
#import "MADFileCoordinatorProtocol.h"
#import "MADFileCoordinatorDelegate.h"
#import "MADFilesControllerDelegate.h"

#import "MADFileCoordinator.h"
#import "MADMetaData.h"
#import <Foundation/NSTimer.h>
#import <Foundation/NSOperation.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSLocale.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSCompoundPredicate.h>
#import <Foundation/NSKeyValueCoding.h>
#import <dispatch/dispatch.h>

#import "MADFileUtilities.h"
#import <MADFoundation/MADURLFactory.h>

NSInteger finderSortWithLocale(id, id, void *);
NSInteger finderSortWithLocale(id string1, id string2, void *locale) {
	return [((MADMetaData *)string1).fileSystemName compare: ((MADMetaData *)string2).fileSystemName
													options: (NSStringCompareOptions)(NSCaseInsensitiveSearch | NSNumericSearch | NSWidthInsensitiveSearch | NSForcedOrderingSearch)
													  range: NSMakeRange(0, ((MADMetaData *)string1).fileSystemName.length)
													 locale: (__bridge NSLocale *)locale];
}

static const char *QueueFileInfoID = "com.everydayapps.mad.designer.queue.file.information";

@interface MADFilesController () <MADFileCoordinatorDelegate>

	@property (nonatomic, strong)   NSMutableArray *fileMetaDatum;
	@property (nonatomic, strong)   dispatch_queue_t fileMetaDataQueue;
	@property (nonatomic, strong)   NSOperationQueue *delegateQueue;

@end

@implementation MADFilesController

@synthesize fileCoordinator = _fileCoordinator;
@synthesize delegateQueue = _delegateQueue;

#pragma mark - Static helpers

NSComparisonResult (^sortComparator)(MADMetaData *, MADMetaData *) = ^NSComparisonResult(MADMetaData *lhs,MADMetaData *rhs){
	return [lhs.name localizedCaseInsensitiveCompare:rhs.name];
};

+ (instancetype)newFilesControllerWithPathExtension: (NSString *)pathExtension
									  storageOption: (MADAppStorage)storageOption
										 identifier: (NSString *)identifier
								  firstQueryHandler: (void (^)(void))firstQueryHandler {
	id coordinator, controller;
	coordinator = [MADFileCoordinator newFileCoordinatorWithPathExtension: pathExtension
															storageOption: storageOption
															   identifier: identifier
														firstQueryHandler: firstQueryHandler];
	
	controller = [[MADFilesController alloc] initWithFileCoordinator: coordinator
													   delegateQueue: [NSOperationQueue mainQueue]
													  sortComparator: sortComparator];
	return controller;
}

+ (instancetype)newFilesControllerWithLastPathComponent: (NSString *)lastPathComponent
										  storageOption: (MADAppStorage)storageOption
											 identifier: (NSString *)identifier
									  firstQueryHandler: (void (^)(void))firstQueryHandler {
	id coordinator, controller;
	coordinator = [MADFileCoordinator newFileCoordinatorWithLastPathComponent: lastPathComponent
																storageOption: storageOption
																   identifier: identifier
															firstQueryHandler: firstQueryHandler];


	controller = [[MADFilesController alloc] initWithFileCoordinator: coordinator
													   delegateQueue: [NSOperationQueue mainQueue]
													  sortComparator: sortComparator];
	return controller;
}

+ (BOOL)isCloudDesired {
	return NO;
}

+ (BOOL)isCloudReadilyAvailable {
	if (![self isCloudDesired]) {
		return NO;
	}
	return [NSFileManager defaultManager].ubiquityIdentityToken != nil;
}

+ (void)getFileStorageLocationsForUbiquityIdentifier: (NSString *)ubiquityIdentifier
									 groupIdentifier: (NSString *)groupIdentifier
											   delay: (void (^)(void))handleLongRunningCall
										  completion: (MADBlockFileStorageLocation)handleCompletion {

	if ([self isCloudReadilyAvailable]) {
		void (^longRunningCallBlock)(void) = [handleLongRunningCall copy];
		
		[NSTimer timerWithTimeInterval: (NSTimeInterval)0.5000
								target: self
							  selector: @selector(handleLongRunningCloudUrlLookup:)
							  userInfo: longRunningCallBlock
							   repeats: NO];
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
			
			NSFileManager *fileManager = [[NSFileManager alloc] init];
			NSURL *ubiquityContainer = [fileManager URLForUbiquityContainerIdentifier: ubiquityIdentifier];

			dispatch_queue_t main_queue = dispatch_get_main_queue();
			dispatch_sync(main_queue, ^{
				
				NSURL *documentDirectory = [ubiquityContainer URLByAppendingPathComponent:@"Documents"];
				[MADFileUtilities coordinateCreateDirectoryIfDoesNotExist:documentDirectory];
				
				NSURL *dataDirectory = [ubiquityContainer URLByAppendingPathComponent:@"Data"];
				[MADFileUtilities coordinateCreateDirectoryIfDoesNotExist:dataDirectory];
				
				if (handleCompletion) handleCompletion(YES, documentDirectory, dataDirectory);
				
			});
		});
		
	} else {
	
		NSURL *documents = [MADURLFactory newURLForLocalDataDirectoryForGroupIdentifier:groupIdentifier];
		NSURL *data = [MADURLFactory newURLLocalDocumentsDirectoryForGroupIdentifier:groupIdentifier];
		if (handleCompletion) handleCompletion(NO, documents, data);
	
	}
	
}

+ (void)handleLongRunningCloudUrlLookup:(NSTimer *)timer {
	if(timer.userInfo) {
		void (^block)(void) = (void (^)(void))timer.userInfo;
		block();
	}
}

#pragma mark - Initialization

- (instancetype)initWithFileCoordinator: (id <MADFileCoordinatorProtocol>)fileCoordinator
						  delegateQueue: (NSOperationQueue *)delegateQueue
						 sortComparator: (NSComparisonResult (^)(MADMetaData *,
																 MADMetaData *))sortComparator {

	if (self = [super init]) {
		
		_fileCoordinator = fileCoordinator;
		_delegateQueue = delegateQueue ?: [NSOperationQueue mainQueue];
		
		dispatch_queue_t fileMetaDataQueue = dispatch_queue_create(QueueFileInfoID, DISPATCH_QUEUE_SERIAL);
		self.fileMetaDataQueue = fileMetaDataQueue;
				
		NSMutableArray *fileMetaData = [[NSMutableArray alloc] init];
		self.fileMetaDatum = fileMetaData;
		
		_fileCoordinator.delegate = self;
	}
	
	return self;
}

- (void)startSearching {
	[self.fileCoordinator startQuery];
}

- (void)stopSearching {
	[self.fileCoordinator stopQuery];
}

- (void)refresh {
	[self.fileCoordinator refresh];
}

#pragma mark - Property Overrides

- (NSUInteger)count {
	return self.fileMetaDatum.count;
}

- (void)setFileCoordinator:(id <MADFileCoordinatorProtocol>)fileCoordinator {
	
	if (![_fileCoordinator isEqual:fileCoordinator]) {

		id <MADFileCoordinatorProtocol> oldFileCoordinator = _fileCoordinator;
		_fileCoordinator = fileCoordinator;
		
		[oldFileCoordinator stopQuery];
		
		__block NSArray *allURLs;
		dispatch_sync(self.fileMetaDataQueue, ^{
			allURLs = [self.fileMetaDatum valueForKey:@"URL"];
		});
		
		NSArray *removed = allURLs.copy;
		NSArray *inserted = [[NSArray alloc] init];
		NSArray *updated = [[NSArray alloc] init];
		[self processContentChangesWithInsertedMetaDatum: inserted
										removedMetaDatum: removed
										updatedMetaDatum: updated
											  completion: ^(BOOL success, NSError *error) {
											  
		}];
		
		_fileCoordinator.delegate = self;
		oldFileCoordinator.delegate = nil;
		
		[_fileCoordinator startQuery];
	}
}

#pragma mark - Subscripting

- (MADMetaData *)objectAtIndexedSubscript:(NSUInteger)index {
	__block MADMetaData *fileInfo = nil;
	__weak typeof(self) weakSelf = self;

	dispatch_sync(_fileMetaDataQueue, ^{
		fileInfo = weakSelf.fileMetaDatum[index];
	});
	
	return fileInfo;
}

#pragma mark - Inserting / Removing / Managing / Updating MADMetaData Objects

- (void)removeFileInfo:(MADMetaData *)fileInfo {
	[self.fileCoordinator removeFileAtURL: fileInfo.URL];
}

- (void)duplicateFileInfo:(MADMetaData *)fileInfo {
	[self.fileCoordinator duplicateFileAtURL: fileInfo.URL];
}

- (void)renameFileInfo:(MADMetaData *)fileInfo toName:(NSString *)name {
	NSURL *url = fileInfo.URL.copy;
	[self.fileCoordinator renameFileAtURL: url toName: name];
}

- (BOOL)canCreateFileInfoWithName:(NSString *)name extention:(NSString *)extention
						fileGroup:(NSString *)fileGroup {
	return [self.fileCoordinator canCreateFileWithName:name extention:extention
											 fileGroup:fileGroup];
}

- (NSURL *)documentDirectory {
	return (self.fileCoordinator).documentsDirectory;
}

- (void)setFileInfoHasNewContents:(MADMetaData *)fileInfo {

	dispatch_queue_t fileMetaDataQueue = self.fileMetaDataQueue;

	__weak typeof(self) weakSelf = self;
	dispatch_async(fileMetaDataQueue, ^{
		
		typeof(self) sself = weakSelf;
		NSUInteger indexOfFileInfo = [sself.fileMetaDatum indexOfObject:fileInfo];
		sself.fileMetaDatum[indexOfFileInfo] = fileInfo;
		
		[sself.delegateQueue addOperationWithBlock:^{

			MADFilesController *sself = weakSelf;
			id <MADFilesControllerDelegate> delegate = sself.delegate;

			SEL willChangeContent = @selector(filesControllerWillChangeContent:);
			if ([delegate respondsToSelector:willChangeContent]) {
				[delegate filesControllerWillChangeContent:sself];
			}
			
			SEL didUpdateFileInfo = @selector(filesController:didUpdateFileInfo:atIndex:);
			if ([delegate respondsToSelector:didUpdateFileInfo]) {
				[delegate filesController:sself didUpdateFileInfo:fileInfo
								  atIndex:indexOfFileInfo];
			}
			
			SEL didChangeContent = @selector(filesControllerDidChangeContent:completion:);
			if ([delegate respondsToSelector: didChangeContent]) {
				[delegate filesControllerDidChangeContent:sself
											   completion:^(BOOL success, NSError *error) { }];
			}
		}];
	});
}

- (void)fileCoordinatorDidUpdateContentsWithInsertedURLs:(NSArray <NSURL *> *)insertedURLs
											 removedURLs:(NSArray <NSURL *> *)removedURLs
											 updatedURLs:(NSArray <NSURL *> *)updatedURLs {
	
	NSMutableArray <MADMetaData *> *insertedMetaDatum = [[NSMutableArray alloc] initWithCapacity:insertedURLs.count],
								   *removedMetaDatum = [[NSMutableArray alloc] initWithCapacity:removedURLs.count],
								   *updatedMetaDatum = [[NSMutableArray alloc] initWithCapacity:updatedURLs.count];

	NSURL *URL;
	MADMetaData *metadata;
	for (URL in insertedURLs) {
		@autoreleasepool {
			metadata = [[MADMetaData alloc] initWithURL:URL];
			[insertedMetaDatum addObject:metadata];
		}
	}
	
	for (URL in removedURLs) {
		@autoreleasepool {
			metadata = [[MADMetaData alloc] initWithURL:URL];
			[removedMetaDatum addObject:metadata];
		}
	}

	for (URL in updatedURLs) {
		@autoreleasepool {
			metadata = [[MADMetaData alloc] initWithURL:URL];
			[updatedMetaDatum addObject:metadata];
		}
	}

	//void (^handleProcessCompletion)(BOOL success, NSError *error);
	//handleProcessCompletion = ^(BOOL success, NSError *error) { };
	
	[self processContentChangesWithInsertedMetaDatum: insertedMetaDatum
									removedMetaDatum: removedMetaDatum
									updatedMetaDatum: updatedMetaDatum
										  completion: ^(BOOL success, NSError *error) { }];
}

- (void)fileCoordinatorDidUpdateContentsWithInsertedMetaDatum:(NSArray *)insertedMetaDatum
											 removedMetaDatum:(NSArray *)removedMetaDatum
											 updatedMetaDatum:(NSArray *)updatedMetaDatum
												   completion:(void (^)(BOOL success,
																		NSError *error))completion {
	
	//NSLog(@"(MetaDatam) File Coordinator Did Update Contents With \n"
	//      @"\t%@\n" @"\t%@\n" @"\t%@", insertedMetaDatum, removedMetaDatum, updatedMetaDatum);

	NSArray *inserts = [NSArray arrayWithArray: insertedMetaDatum];
	NSArray *removes = [NSArray arrayWithArray: removedMetaDatum];
	NSArray *updates = [NSArray arrayWithArray: updatedMetaDatum];
	
	//void (^handleProcessCompletion)(BOOL success, NSError *error);
	//handleProcessCompletion = ^(BOOL success, NSError *error) {
	//    completion(success, error);
	//};

	[self processContentChangesWithInsertedMetaDatum: inserts
									removedMetaDatum: removes
									updatedMetaDatum: updates
										  completion: ^(BOOL success, NSError *error) {
											  completion(success, error);
										  }];
}

- (void)fileCoordinatorDidFailCreatingFileAtURL:(NSURL *)URL withError:(NSError *)error {
	typeof(self) __weak weakSelf = self;
	/*void (^handleFailure)(void);
	handleFailure = ^{
		MADFilesController *sself = weakSelf;
		id <MADFilesControllerDelegate> delegate = sself.delegate;
		MADMetaData *fileInfo = [[MADMetaData alloc] initWithURL:URL];
		SEL didFailCreatingFile = @selector(filesController:didFailCreatingFileInfo:withError:);
		if ([delegate respondsToSelector:didFailCreatingFile]) {
			[delegate filesController:sself didFailCreatingFileInfo:fileInfo withError:error];
		}
		
	};*/
	[self.delegateQueue addOperationWithBlock:^{
		MADFilesController *sself = weakSelf;
		id <MADFilesControllerDelegate> delegate = sself.delegate;
		MADMetaData *fileInfo = [[MADMetaData alloc] initWithURL:URL];
		SEL didFailCreatingFile = @selector(filesController:didFailCreatingFileInfo:withError:);
		if ([delegate respondsToSelector:didFailCreatingFile]) {
			[delegate filesController:sself didFailCreatingFileInfo:fileInfo withError:error];
		}
	}];
}

- (void)fileCoordinatorDidFailDuplicatingFileAtURL:(NSURL *)URL withError:(NSError *)error {
	//NSLog(@"File Coordinator did fail duplicating URL: %@", URL);
	typeof(self) __weak weakSelf = self;
	[self.delegateQueue addOperationWithBlock:^{
		MADFilesController *sself = weakSelf;
		id <MADFilesControllerDelegate> delegate = sself.delegate;
		MADMetaData *fileInfo = [[MADMetaData alloc] initWithURL:URL];
		SEL didFailDuplicating = @selector(filesController:didFailDuplicatingFileInfo:withError:);
		if ([delegate respondsToSelector:didFailDuplicating]) {
			[delegate filesController:sself didFailDuplicatingFileInfo:fileInfo withError:error];
		}
	}];
}

- (void)fileCoordinatorDidFailRenamingFileAtURL:(NSURL *)URL withError:(NSError *)error {
	//NSLog(@"File Coordinator did fail renaming URL: %@", URL);
	typeof(self) __weak weakSelf = self;
	[self.delegateQueue addOperationWithBlock:^{
		MADFilesController *sself = weakSelf;
		id <MADFilesControllerDelegate> delegate = sself.delegate;
		MADMetaData *fileInfo = [[MADMetaData alloc] initWithURL:URL];
		SEL didFailRemovingFile = @selector(filesController:didFailRemovingFileInfo:withError:);
		if ([delegate respondsToSelector:didFailRemovingFile]) {
			[delegate filesController:sself didFailRenamingFileInfo:fileInfo withError:error];
		}
	}];
}

- (void)fileCoordinatorDidFailRemovingFileAtURL:(NSURL *)URL withError:(NSError *)error {
	//NSLog(@"File Coordinator did fail removing URL: %@", URL);

	typeof(self) __weak weakSelf = self;
	//void (^handleFailure)(void);
	/*handleFailure = ^{
		MADFilesController *sself = weakSelf;
		id <MADFilesControllerDelegate> delegate = sself.delegate;
		
		MADMetaData *fileInfo = [[MADMetaData alloc] initWithURL:URL];
		SEL didFailRemovingFile = @selector(filesController:didFailRemovingFileInfo:withError:);
		if ([delegate respondsToSelector:didFailRemovingFile]) {
			[delegate filesController:sself didFailRemovingFileInfo:fileInfo withError:error];
		}
	};*/
	[self.delegateQueue addOperationWithBlock:^{
		MADFilesController *sself = weakSelf;
		id <MADFilesControllerDelegate> delegate = sself.delegate;
		
		MADMetaData *fileInfo = [[MADMetaData alloc] initWithURL:URL];
		SEL didFailRemovingFile = @selector(filesController:didFailRemovingFileInfo:withError:);
		if ([delegate respondsToSelector:didFailRemovingFile]) {
			[delegate filesController:sself didFailRemovingFileInfo:fileInfo withError:error];
		}
	}];
}

#pragma mark - Change Processing

/*!
 * Processes changes to the \c AAPLFilesController object's \c MADMetaData collection. This
 * implementation performs the updates and determines where each of these URLs were located so that
 * the controller can forward the new / removed / updated indexes as well.
 *
 * @param insertedURLs The \c NSURL instances that are newly tracked.
 * @param removedURLs The \c NSURL instances that have just been untracked.
 * @param updatedURLs The \c NSURL instances that have had their underlying model updated.
 */
- (void)processContentChangesWithInsertedMetaDatum:(NSArray *)inserts
								  removedMetaDatum:(NSArray *)removes
								  updatedMetaDatum:(NSArray *)updates
										completion:(void (^)(BOOL success, NSError *error))completion {

	NSArray *insertedMetaDatum = inserts.copy;
	NSArray *removedMetaDatum = removes.copy;
	NSArray *updatedMetaDatum = updates.copy;
	
	MADFilesController * __weak weakSelf = self;
	
	[self.delegateQueue addOperationWithBlock:^{
		
		MADFilesController *sself = weakSelf;

		dispatch_queue_t fileMetaDataQueue = sself.fileMetaDataQueue;
		id <MADFilesControllerDelegate> delegate = sself.delegate;
		
		__block NSArray *trackedRemovedFileInfos;
		__block NSArray *untrackedInsertedFileInfos;
		NSArray *fileMetaDatum = [[NSArray alloc] initWithArray:sself.fileMetaDatum];
		
		dispatch_sync(fileMetaDataQueue, ^{
			NSPredicate *contains = [NSPredicate predicateWithFormat:@"URL in %@.URL", fileMetaDatum];
			trackedRemovedFileInfos = [removedMetaDatum filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"URL in %@.URL", fileMetaDatum]];
			untrackedInsertedFileInfos = [insertedMetaDatum filteredArrayUsingPredicate:[NSCompoundPredicate notPredicateWithSubpredicate:contains]];
		});
		
		if (untrackedInsertedFileInfos.count == 0 && trackedRemovedFileInfos.count == 0 &&
			updatedMetaDatum.count == 0) {
			return;
		}
		
		if ([delegate respondsToSelector:@selector(filesControllerWillChangeContent:)]) {
			[delegate filesControllerWillChangeContent:sself];
		}
		
		
		// Remove
		for (MADMetaData *trackedRemovedFileInfo in trackedRemovedFileInfos) {
			__block NSUInteger trackedRemovedFileInfoIndex;
			
			MADFilesController * __weak wself = sself;
			dispatch_sync(fileMetaDataQueue, ^{
				MADFilesController *sself2 = wself;
				trackedRemovedFileInfoIndex =
				[sself2.fileMetaDatum indexOfObject:trackedRemovedFileInfo];
				[sself2.fileMetaDatum removeObjectAtIndex: trackedRemovedFileInfoIndex];
			});
			
			if ([delegate respondsToSelector:@selector(filesController:didRemoveFileInfo:atIndex:)]) {
				[delegate filesController: sself
						didRemoveFileInfo: trackedRemovedFileInfo
								  atIndex: trackedRemovedFileInfoIndex];
			}
		}
		
		// Sort the untracked inserted list infos
		NSLocale *currentLocale = [NSLocale currentLocale];
		untrackedInsertedFileInfos = [untrackedInsertedFileInfos sortedArrayUsingFunction:finderSortWithLocale
																				  context:(__bridge void *)(currentLocale)];
		
		// Insert
		[sself.fileMetaDatum addObjectsFromArray:untrackedInsertedFileInfos];
		NSArray *fileMetaDatumSorted = [sself.fileMetaDatum sortedArrayUsingFunction:finderSortWithLocale
																			 context:(__bridge void *)(currentLocale)];
		
		sself.fileMetaDatum = fileMetaDatumSorted.mutableCopy;
		
		for (MADMetaData *untrackedInsertedFileInfo in untrackedInsertedFileInfos) {
			__block NSUInteger untrackedInsertedFileInfoIndex;
			
			MADFilesController *__weak wself = sself;
			dispatch_block_t findInsertedIndexes = ^{
				untrackedInsertedFileInfoIndex =
				[wself.fileMetaDatum indexOfObject:untrackedInsertedFileInfo];
			};
			dispatch_sync(fileMetaDataQueue, findInsertedIndexes);
			
			if ([delegate respondsToSelector:@selector(filesController:didInsertFileInfo:atIndex:)]) {
				[delegate filesController: sself didInsertFileInfo: untrackedInsertedFileInfo
								  atIndex: untrackedInsertedFileInfoIndex];
			}
		}
		
		// Update
		for (MADMetaData *updatedFileInfo in updatedMetaDatum) {
			
			__block NSUInteger updatedFileInfoIndex;
			MADFilesController *__weak wself = sself;
			dispatch_block_t findUpdatedIndex = ^{
				MADFilesController *sself2 = wself;
				updatedFileInfoIndex = [sself2.fileMetaDatum indexOfObject:updatedFileInfo];
				if (updatedFileInfoIndex != NSNotFound) {
					sself2.fileMetaDatum[updatedFileInfoIndex] = updatedFileInfo;
				}
			};
			
			dispatch_sync(fileMetaDataQueue, findUpdatedIndex);
			if (updatedFileInfoIndex != NSNotFound && [delegate respondsToSelector:@selector(filesController:didUpdateFileInfo:atIndex:)]) {
				[delegate filesController: sself
						didUpdateFileInfo: updatedFileInfo
								  atIndex: updatedFileInfoIndex];
			}
		}
		
		if ([delegate respondsToSelector:@selector(filesControllerDidChangeContent:completion:)]) {
			void (^handleCompletion)(BOOL, NSError *) = ^(BOOL success, NSError *error) { };
			[delegate filesControllerDidChangeContent: sself
										   completion: handleCompletion];
			completion(YES, nil);
		} else {
			completion(YES, nil);
		}
	}];
}

#pragma mark - Convenience

- (NSArray *)fileInfosByMappingURLs:(NSArray *)URLs {
	NSMutableArray *fileMetaDatum = [NSMutableArray arrayWithCapacity:URLs.count];
	for (NSURL *URL in URLs) {
		MADMetaData *fileMetaData = [[MADMetaData alloc] initWithURL:URL];
		[fileMetaDatum addObject:fileMetaData];
	}
	return fileMetaDatum;
}

- (id)debugQuickLookObject {
	NSMutableString *debug = [[NSMutableString alloc] init];
	NSString *classname = NSStringFromClass([self class]);
	id uppercaseClassname = [classname uppercaseString];
	[debug appendFormat:@"--%@--\n", uppercaseClassname];
	[debug appendFormat:@"Delegate:         %@--\n", _delegate];
	[debug appendFormat:@"File coordinator: %@--\n", _fileCoordinator];
	[debug appendFormat:@"Directory:        %@--\n", self.documentDirectory];
	[debug appendFormat:@"File count:       %lu--\n", (unsigned long)self.count];
	[debug appendFormat:@"%@", _fileMetaDatum];
	return debug;
}

@end
