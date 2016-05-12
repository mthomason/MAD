//
//  MADFilesController.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADFilesController.h"
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

NSInteger finderSortWithLocale(id string1, id string2, void *locale);
NSInteger finderSortWithLocale(id string1, id string2, void *locale) {
    
    static NSStringCompareOptions comparisonOptions = NSCaseInsensitiveSearch | NSNumericSearch | NSWidthInsensitiveSearch | NSForcedOrderingSearch;
    NSRange string1Range = NSMakeRange(0, ((MADMetaData *)string1).fileSystemName.length);
    return [((MADMetaData *)string1).fileSystemName compare:((MADMetaData *)string2).fileSystemName options:comparisonOptions range:string1Range locale:(__bridge NSLocale *)locale];
    
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

+ (instancetype)newFilesControllerWithPathExtension: (NSString *)pathExtension
                                      storageOption: (MADAppStorage)storageOption
                                         identifier: (NSString *)identifier
                                  firstQueryHandler: (void (^)(void))firstQueryHandler {

    id fc = [MADFileCoordinator newFileCoordinatorWithPathExtension: pathExtension
                                                      storageOption: storageOption
                                                         identifier: identifier
                                                  firstQueryHandler: firstQueryHandler];
    
    id filesController = [[MADFilesController alloc] initWithFileCoordinator: fc
                                                               delegateQueue: [NSOperationQueue mainQueue]
                                                              sortComparator: ^NSComparisonResult(MADMetaData *lhs, MADMetaData *rhs) {
         return [lhs.name localizedCaseInsensitiveCompare:rhs.name];
    }];
    return filesController;
}

+ (instancetype)newFilesControllerWithLastPathComponent: (NSString *)lastPathComponent
                                          storageOption: (MADAppStorage)storageOption
                                             identifier: (NSString *)identifier
                                      firstQueryHandler: (void (^)(void))firstQueryHandler {

    id coordinator = [MADFileCoordinator newFileCoordinatorWithLastPathComponent: lastPathComponent
                                                                   storageOption: storageOption
                                                                      identifier: identifier
                                                               firstQueryHandler: firstQueryHandler];

    id filesController = [[MADFilesController alloc] initWithFileCoordinator: coordinator
                                                               delegateQueue: [NSOperationQueue mainQueue]
                                                              sortComparator: ^NSComparisonResult(MADMetaData *lhs, MADMetaData *rhs) {
                                                                  return [lhs.name localizedCaseInsensitiveCompare:rhs.name];
                                                              }];
    return filesController;
}

+ (bool)isCloudAvailable {
    return [[NSFileManager defaultManager] ubiquityIdentityToken] != nil;
}

+ (void)getFileStorageLocationsForUbiquityIdentifier: (NSString *)ubiquityIdentifier
                                     groupIdentifier: (NSString *)groupIdentifier
                                               delay: (void (^)())handleLongRunningCall
                                          completion: (MADBlockCompletionFileStorageLocation)handleCompletion {

    if ([self isCloudAvailable]) {
        
        void (^longRunningCallBlock)() = [handleLongRunningCall copy];
        
        [NSTimer timerWithTimeInterval: (NSTimeInterval)0.5000
                                target: self
                              selector: @selector(handleLongRunningCloudUrlLookup:)
                              userInfo: longRunningCallBlock
                               repeats: NO];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            //This call may be SLOW, so only do on BACKGROUND thread.
            
            NSURL *ubiquityContainer = [fileManager URLForUbiquityContainerIdentifier: ubiquityIdentifier];
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                
                NSURL *documentDirectory = [ubiquityContainer URLByAppendingPathComponent:@"Documents"];
                [MADFileUtilities coordinateCreateDirectoryIfDoesNotExist:documentDirectory];
                
                NSURL *dataDirectory = [ubiquityContainer URLByAppendingPathComponent:@"Data"];
                [MADFileUtilities coordinateCreateDirectoryIfDoesNotExist:dataDirectory];
                
                if (handleCompletion) handleCompletion(YES, documentDirectory, dataDirectory);
                
            });
        });
        
    } else {
    
        NSURL *documents = [MADFileUtilities localDataDirectoryForGroupIdentifier:groupIdentifier];
        NSURL *data = [MADFileUtilities localDocumentsDirectoryForGroupIdentifier:groupIdentifier];
        if (handleCompletion) handleCompletion(NO, documents, data);
    
    }
    
}

+ (void)handleLongRunningCloudUrlLookup:(NSTimer *)timer {
    if(timer.userInfo) {
        void (^block)() = (void (^)())timer.userInfo;
        block();
    }
}

#pragma mark - Initialization

- (instancetype)initWithFileCoordinator: (id <MADFileCoordinator>)fileCoordinator
                          delegateQueue: (NSOperationQueue *)delegateQueue
                         sortComparator: (NSComparisonResult (^)(MADMetaData *, MADMetaData *))sortComparator {

    if (self = [super init]) {
        
        _fileCoordinator = fileCoordinator;
        
        self.delegateQueue = delegateQueue ?: [NSOperationQueue mainQueue];
        
        dispatch_queue_t fileMetaDataQueue = dispatch_queue_create(QueueFileInfoID, DISPATCH_QUEUE_SERIAL);
        self.fileMetaDataQueue = fileMetaDataQueue;
        
        NSMutableArray *fileMetaData = [[NSMutableArray alloc] init];
        self.fileMetaDatum = fileMetaData;
        
        self.fileCoordinator.delegate = self;
    }
    
    return self;
}

- (void)startSearching {
    [self.fileCoordinator startQuery];
}

- (void)stopSearching {
    [self.fileCoordinator stopQuery];
}

#pragma mark - Property Overrides

- (NSUInteger)count { return self.fileMetaDatum.count; }

- (void)setFileCoordinator:(id<MADFileCoordinator>)fileCoordinator {

    if (![_fileCoordinator isEqual:fileCoordinator]) {

        id<MADFileCoordinator> oldFileCoordinator = _fileCoordinator;
        _fileCoordinator = fileCoordinator;
        
        [oldFileCoordinator stopQuery];
        
        // Map the fileInfo objects protected by fileInfoQueue.
        __block NSArray *allURLs;
        dispatch_sync(self.fileMetaDataQueue, ^{
            allURLs = [self.fileMetaDatum valueForKey:@"URL"];
        });
        
        NSArray *removed = allURLs.copy;
        NSArray *inserted = [[NSArray alloc] initWithObjects: nil];
        NSArray *updated = [[NSArray alloc] initWithObjects: nil];
        [self processContentChangesWithInsertedMetaDatum: inserted
                                        removedMetaDatum: removed
                                        updatedMetaDatum: updated
                                              completion: ^(BOOL success, NSError *error) { }];
        
        _fileCoordinator.delegate = self;
        oldFileCoordinator.delegate = nil;
        
        [_fileCoordinator startQuery];
    }
}

#pragma mark - Subscripting

- (MADMetaData *)objectAtIndexedSubscript:(NSUInteger)index {

    dispatch_queue_t fileMetaDataQueue = self.fileMetaDataQueue;
    __block MADMetaData *fileInfo = nil;
    __unsafe_unretained typeof(self) weakSelf = self;

    dispatch_sync(fileMetaDataQueue, ^{
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

- (void)createFileInfoForFile:(MADFile *)list withName:(NSString *)name extention:(NSString *)extention fileGroup:(NSString *)fileGroup {
    [self.fileCoordinator createURLForFile:list withName:name extention:extention fileGroup:fileGroup];
}

- (BOOL)canCreateFileInfoWithName:(NSString *)name extention:(NSString *)extention fileGroup:(NSString *)fileGroup {
    return [self.fileCoordinator canCreateFileWithName:name extention:extention fileGroup:fileGroup];
}

- (NSURL *)documentDirectory {
    return [self.fileCoordinator documentsDirectory];
}

- (void)setFileInfoHasNewContents:(MADMetaData *)fileInfo {

    dispatch_queue_t fileMetaDataQueue = self.fileMetaDataQueue;

    __unsafe_unretained typeof(self) weakSelf = self;
    dispatch_async(fileMetaDataQueue, ^{

        NSUInteger indexOfFileInfo = [weakSelf.fileMetaDatum indexOfObject:fileInfo];
        weakSelf.fileMetaDatum[indexOfFileInfo] = fileInfo;
        
        [weakSelf.delegateQueue addOperationWithBlock:^{

            MADFilesController *sself = weakSelf;
            if ([sself.delegate respondsToSelector:@selector(filesControllerWillChangeContent:)]) {
                [sself.delegate filesControllerWillChangeContent:sself];
            }
            
            if ([sself.delegate respondsToSelector:@selector(filesController:didUpdateFileInfo:atIndex:)]) {
                [sself.delegate filesController:sself didUpdateFileInfo:fileInfo
                                       atIndex:indexOfFileInfo];
            }
            
            if ([sself.delegate respondsToSelector:@selector(filesControllerDidChangeContent:completion:)]) {
                [sself.delegate filesControllerDidChangeContent:sself
                                                    completion:^(BOOL success, NSError *error) { }];
            }
        }];
    });
}

- (void)fileCoordinatorDidUpdateContentsWithInsertedURLs:(NSArray *)insertedURLs
                                             removedURLs:(NSArray *)removedURLs
                                             updatedURLs:(NSArray *)updatedURLs {

    NSMutableArray *insertedMetaDatum = [[NSMutableArray alloc] initWithCapacity:insertedURLs.count];
    NSMutableArray *removedMetaDatum = [[NSMutableArray alloc] initWithCapacity:removedURLs.count];
    NSMutableArray *updatedMetaDatum = [[NSMutableArray alloc] initWithCapacity:updatedURLs.count];

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

    [self processContentChangesWithInsertedMetaDatum: insertedMetaDatum
                                    removedMetaDatum: removedMetaDatum
                                    updatedMetaDatum: updatedMetaDatum
                                          completion:^(BOOL success, NSError *error) { }];
}

- (void)fileCoordinatorDidUpdateContentsWithInsertedMetaDatum:(NSArray *)insertedMetaDatum
                                             removedMetaDatum:(NSArray *)removedMetaDatum
                                             updatedMetaDatum:(NSArray *)updatedMetaDatum
                                                   completion:(void (^)(BOOL success, NSError *error))completion {
    NSArray *inserts = [NSArray arrayWithArray: insertedMetaDatum];
    NSArray *removes = [NSArray arrayWithArray: removedMetaDatum];
    NSArray *updates = [NSArray arrayWithArray: updatedMetaDatum];
    [self processContentChangesWithInsertedMetaDatum: inserts
                                    removedMetaDatum: removes
                                    updatedMetaDatum: updates
                                          completion:^(BOOL success, NSError *error) {
                                              completion(success, error);
                                          }];
}

- (void)fileCoordinatorDidFailCreatingFileAtURL:(NSURL *)URL withError:(NSError *)error {
    __unsafe_unretained typeof(self) weakSelf = self;
    [self.delegateQueue addOperationWithBlock:^{
        MADMetaData *fileInfo = [[MADMetaData alloc] initWithURL:URL];
        SEL didFailCreatingFile = @selector(filesController:didFailCreatingFileInfo:withError:);
        if ([weakSelf.delegate respondsToSelector:didFailCreatingFile]) {
            [weakSelf.delegate filesController:weakSelf didFailCreatingFileInfo:fileInfo withError:error];
        }
        
    }];
}

- (void)fileCoordinatorDidFailDuplicatingFileAtURL:(NSURL *)URL withError:(NSError *)error {
    __unsafe_unretained typeof(self) weakSelf = self;
    [self.delegateQueue addOperationWithBlock:^{
        MADMetaData *fileInfo = [[MADMetaData alloc] initWithURL:URL];
        SEL didFailDuplicatingFile = @selector(filesController:didFailDuplicatingFileInfo:withError:);
        if ([weakSelf.delegate respondsToSelector:didFailDuplicatingFile]) {
            [weakSelf.delegate filesController:weakSelf didFailDuplicatingFileInfo:fileInfo withError:error];
        }
    }];
}

- (void)fileCoordinatorDidFailRenamingFileAtURL:(NSURL *)URL withError:(NSError *)error {
    __unsafe_unretained typeof(self) weakSelf = self;
    [self.delegateQueue addOperationWithBlock:^{
        MADMetaData *fileInfo = [[MADMetaData alloc] initWithURL:URL];
        SEL didFailRemovingFile = @selector(filesController:didFailRemovingFileInfo:withError:);
        if ([weakSelf.delegate respondsToSelector:didFailRemovingFile]) {
            [weakSelf.delegate filesController:weakSelf didFailRenamingFileInfo:fileInfo withError:error];
        }
    }];
}

- (void)fileCoordinatorDidFailRemovingFileAtURL:(NSURL *)URL withError:(NSError *)error {
    __unsafe_unretained typeof(self) weakSelf = self;
    [self.delegateQueue addOperationWithBlock:^{
        MADMetaData *fileInfo = [[MADMetaData alloc] initWithURL:URL];
        SEL didFailRemovingFile = @selector(filesController:didFailRemovingFileInfo:withError:);
        if ([weakSelf.delegate respondsToSelector:didFailRemovingFile]) {
            [weakSelf.delegate filesController:weakSelf didFailRemovingFileInfo:fileInfo withError:error];
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
    [weakSelf.delegateQueue addOperationWithBlock:^{

        MADFilesController *sself = weakSelf;

        __block NSArray *trackedRemovedFileInfos;
        __block NSArray *untrackedInsertedFileInfos;
        
        NSArray *fileMetaDatum = [[NSArray alloc] initWithArray:sself.fileMetaDatum];
 
        dispatch_sync(sself.fileMetaDataQueue, ^{
            
            id contains = [NSPredicate predicateWithFormat:@"URL in %@.URL", fileMetaDatum];
            trackedRemovedFileInfos = [removedMetaDatum filteredArrayUsingPredicate:contains];

            id excludes = [NSCompoundPredicate notPredicateWithSubpredicate:contains];
            untrackedInsertedFileInfos = [insertedMetaDatum filteredArrayUsingPredicate:excludes];
            
        });
        
        if (untrackedInsertedFileInfos.count == 0 && trackedRemovedFileInfos.count == 0 &&
            updatedMetaDatum.count == 0) {
            return;
        }
        
        if ([sself.delegate respondsToSelector:@selector(filesControllerWillChangeContent:)]) {
            [sself.delegate filesControllerWillChangeContent:sself];
        }
        
        // Remove
        for (MADMetaData *trackedRemovedFileInfo in trackedRemovedFileInfos) {
            __block NSUInteger trackedRemovedFileInfoIndex;
            
            MADFilesController * __weak wself = sself;
            dispatch_sync(wself.fileMetaDataQueue, ^{
            
                trackedRemovedFileInfoIndex = [wself.fileMetaDatum indexOfObject:trackedRemovedFileInfo];
                [wself.fileMetaDatum removeObjectAtIndex: trackedRemovedFileInfoIndex];
                
            });
            
            SEL didRemoveFileInfo = @selector(filesController:didRemoveFileInfo:atIndex:);
            if ([sself.delegate respondsToSelector:didRemoveFileInfo]) {
            
                [sself.delegate filesController: sself
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
            dispatch_sync(wself.fileMetaDataQueue, ^{
                untrackedInsertedFileInfoIndex = [wself.fileMetaDatum indexOfObject:untrackedInsertedFileInfo];
            });
            
            if ([sself.delegate respondsToSelector:@selector(filesController:didInsertFileInfo:atIndex:)]) {
                [sself.delegate filesController: sself didInsertFileInfo: untrackedInsertedFileInfo
                                       atIndex: untrackedInsertedFileInfoIndex];
            }
        }
        
        // Update
        for (MADMetaData *updatedFileInfo in updatedMetaDatum) {

            __block NSUInteger updatedFileInfoIndex;
            
            MADFilesController *__weak wself = sself;
            dispatch_sync(wself.fileMetaDataQueue, ^{

                updatedFileInfoIndex = [self.fileMetaDatum indexOfObject:updatedFileInfo];
                
                if (updatedFileInfoIndex != NSNotFound) {
                    wself.fileMetaDatum[updatedFileInfoIndex] = updatedFileInfo;
                }
                
            });
            
            SEL didUpdateFileInfo = @selector(filesController:didUpdateFileInfo:atIndex:);
            if (updatedFileInfoIndex != NSNotFound &&
                [sself.delegate respondsToSelector:didUpdateFileInfo]) {
                
                [sself.delegate filesController:sself didUpdateFileInfo:updatedFileInfo
                                        atIndex:updatedFileInfoIndex];

            }
        }
        
        SEL didChangeContent = @selector(filesControllerDidChangeContent:completion:);
        if ([sself.delegate respondsToSelector:didChangeContent]) {

                [sself.delegate filesControllerDidChangeContent: sself
                                                     completion: ^(BOOL success, NSError *error) {
                    completion(success, nil);
                }];
                
            
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

@end
