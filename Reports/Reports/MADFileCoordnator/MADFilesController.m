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
#import "NSFileManager+Common.h"

@interface MADFilesController () <MADFileCoordinatorDelegate>

@property (nonatomic, strong)   NSMutableArray *fileMetaDatum;
@property (nonatomic, strong)   dispatch_queue_t fileMetaDataQueue;
@property (nonatomic, copy)     NSComparisonResult (^sortComparator)(MADMetaData *lhs, MADMetaData *rhs);
@property (nonatomic, strong)   NSOperationQueue *delegateQueue;

@end

@implementation MADFilesController
@synthesize fileCoordinator = _fileCoordinator;
@synthesize delegateQueue = _delegateQueue;

#pragma mark - Static helpers

+ (BOOL)isCloudAvailable {
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
                NSURL *dataDirectory = [ubiquityContainer URLByAppendingPathComponent:@"Data"];
                [fileManager coordinateCreateDirectoryIfDoesNotExist:documentDirectory];
                [fileManager coordinateCreateDirectoryIfDoesNotExist:dataDirectory];
                
                if (handleCompletion) handleCompletion(YES, documentDirectory, dataDirectory);
                
            });
        });
    } else {
        NSURL *documents = [[NSFileManager defaultManager] localDataDirectoryForGroupIdentifier:groupIdentifier];
        NSURL *data = [[NSFileManager defaultManager] localDocumentsDirectoryForGroupIdentifier:groupIdentifier];
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

- (instancetype)initWithFileCoordinator:(id<MADFileCoordinator>)fileCoordinator
                          delegateQueue:(NSOperationQueue *)delegateQueue
                         sortComparator:(NSComparisonResult (^)(MADMetaData *lhs, MADMetaData *rhs))sortComparator {
    self = [super init];
    
    if (self) {
        
        _fileCoordinator = fileCoordinator;
        self.sortComparator = sortComparator;
        
        self.delegateQueue = delegateQueue ?: [NSOperationQueue mainQueue];
        
        dispatch_queue_t fileMetaDataQueue = dispatch_queue_create("com.everydayapps.mad.designer.queue.file.information", DISPATCH_QUEUE_SERIAL);
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

- (NSInteger)count {
    return self.fileMetaDatum.count;
}

- (void)setFileCoordinator:(id<MADFileCoordinator>)fileCoordinator {
    if (![_fileCoordinator isEqual:fileCoordinator]) {
        id<MADFileCoordinator> oldFileCoordinator = _fileCoordinator;
        _fileCoordinator = fileCoordinator;
        
        [oldFileCoordinator stopQuery];
        
        // Map the listInfo objects protected by listInfoQueue.
        __block NSArray *allURLs;
        dispatch_sync(self.fileMetaDataQueue, ^{
            allURLs = [self.fileMetaDatum valueForKey:@"URL"];
        });
        [self processContentChangesWithInsertedMetaDatum:@[] removedMetaDatum:allURLs updatedMetaDatum:@[]
                                              completion:^(BOOL success, NSError *error) {
                                                  
                                              }];
        
        _fileCoordinator.delegate = self;
        oldFileCoordinator.delegate = nil;
        
        [_fileCoordinator startQuery];
    }
}

#pragma mark - Subscripting

- (MADMetaData *)objectAtIndexedSubscript:(NSInteger)index {
    // Fetch the appropriate list info protected by listInfoQueue.
    __block MADMetaData *listInfo = nil;
    
    dispatch_sync(self.fileMetaDataQueue, ^{
        listInfo = self.fileMetaDatum[index];
    });
    
    return listInfo;
}

#pragma mark - Inserting / Removing / Managing / Updating MADMetaData Objects

- (void)removeFileInfo:(MADMetaData *)listInfo {
    [self.fileCoordinator removeFileAtURL: listInfo.URL];
}

- (void)duplicateFileInfo:(MADMetaData *)listInfo {
    [self.fileCoordinator duplicateFileAtURL: listInfo.URL];
}

- (void)renameFileInfo:(MADMetaData *)listInfo toName:(NSString *)name {
    NSURL *url = listInfo.URL.copy;
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

- (void)setFileInfoHasNewContents:(MADMetaData *)listInfo {
    dispatch_async(self.fileMetaDataQueue, ^{
        // Remove the old list info and replace it with the new one.
        NSInteger indexOfListInfo = [self.fileMetaDatum indexOfObject:listInfo];
        self.fileMetaDatum[indexOfListInfo] = listInfo;
        
        [self.delegateQueue addOperationWithBlock:^{
            if ([self.delegate respondsToSelector:@selector(filesControllerWillChangeContent:)]) {
                [self.delegate filesControllerWillChangeContent:self];
            }
            
            if ([self.delegate respondsToSelector:@selector(filesController:didUpdateListInfo:atIndex:)]) {
                [self.delegate filesController:self didUpdateListInfo:listInfo atIndex:indexOfListInfo];
            }
            
            if ([self.delegate respondsToSelector:@selector(filesControllerDidChangeContent:completion:)]) {
                [self.delegate filesControllerDidChangeContent:self completion:^(BOOL success, NSError *error) {
                    
                }];
            }
        }];
    });
}

- (void)fileCoordinatorDidUpdateContentsWithInsertedURLs:(NSArray *)insertedURLs
                                             removedURLs:(NSArray *)removedURLs
                                             updatedURLs:(NSArray *)updatedURLs {
    NSMutableArray *insertedMetaDatum = [[NSMutableArray alloc] initWithCapacity:insertedURLs.count];
    NSMutableArray *removedMetaDatum = [[NSMutableArray alloc] initWithCapacity:insertedURLs.count];
    NSMutableArray *updatedMetaDatum = [[NSMutableArray alloc] initWithCapacity:insertedURLs.count];
    NSURL *URL;
    MADMetaData *metadata;
    for (URL in insertedURLs) {
        metadata = [[MADMetaData alloc] initWithURL:URL];
        [insertedMetaDatum addObject:metadata];
    }
    for (URL in removedURLs) {
        metadata = [[MADMetaData alloc] initWithURL:URL];
        [removedMetaDatum addObject:metadata];
    }
    for (URL in updatedURLs) {
        metadata = [[MADMetaData alloc] initWithURL:URL];
        [updatedMetaDatum addObject:metadata];
    }
    [self processContentChangesWithInsertedMetaDatum: insertedMetaDatum
                                    removedMetaDatum: removedMetaDatum
                                    updatedMetaDatum: updatedMetaDatum
                                          completion:^(BOOL success, NSError *error) {
                                              
                                          }];
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
    MADMetaData *listInfo = [[MADMetaData alloc] initWithURL:URL];
    
    [self.delegateQueue addOperationWithBlock:^{
        if ([self.delegate respondsToSelector:@selector(filesController:didFailCreatingListInfo:withError:)]) {
            [self.delegate filesController:self didFailCreatingListInfo:listInfo withError:error];
        }
    }];
}

- (void)fileCoordinatorDidFailDuplicatingFileAtURL:(NSURL *)URL withError:(NSError *)error {
    MADMetaData *listInfo = [[MADMetaData alloc] initWithURL:URL];
    [self.delegateQueue addOperationWithBlock:^{
        if ([self.delegate respondsToSelector:@selector(filesController:didFailDuplicatingListInfo:withError:)]) {
            [self.delegate filesController:self didFailDuplicatingListInfo:listInfo withError:error];
        }
    }];
}

- (void)fileCoordinatorDidFailRenamingFileAtURL:(NSURL *)URL withError:(NSError *)error {
    MADMetaData *listInfo = [[MADMetaData alloc] initWithURL:URL];
    [self.delegateQueue addOperationWithBlock:^{
        if ([self.delegate respondsToSelector:@selector(filesController:didFailRemovingListInfo:withError:)]) {
            [self.delegate filesController:self didFailRenamingListInfo:listInfo withError:error];
        }
    }];
}

- (void)fileCoordinatorDidFailRemovingFileAtURL:(NSURL *)URL withError:(NSError *)error {
    MADMetaData *listInfo = [[MADMetaData alloc] initWithURL:URL];
    [self.delegateQueue addOperationWithBlock:^{
        if ([self.delegate respondsToSelector:@selector(filesController:didFailRemovingListInfo:withError:)]) {
            [self.delegate filesController:self didFailRemovingListInfo:listInfo withError:error];
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
    
    NSArray *insertedMetaDatum = [NSArray arrayWithArray: inserts];
    NSArray *removedMetaDatum = [NSArray arrayWithArray: removes];
    NSArray *updatedMetaDatum = [NSArray arrayWithArray: updates];
    NSLog(@"Inserted %lu", (unsigned long)insertedMetaDatum.count);
    NSLog(@"Removed %lu", (unsigned long)removedMetaDatum.count);
    NSLog(@"Updated %lu", (unsigned long)updatedMetaDatum.count);
    
    [self.delegateQueue addOperationWithBlock:^{
        
        // Filter out all lists that are already included in the tracked lists.
        __block NSArray *trackedRemovedListInfos;
        __block NSArray *untrackedInsertedListInfos;
        
        NSArray *fileMetaDatum = [NSArray arrayWithArray:self.fileMetaDatum];
 
        dispatch_sync(self.fileMetaDataQueue, ^{
            NSPredicate *containPredicate = [NSPredicate predicateWithFormat:@"URL in %@.URL", fileMetaDatum];
            trackedRemovedListInfos = [removedMetaDatum filteredArrayUsingPredicate:containPredicate];
            
            NSPredicate *doesntContainPredicate = [NSCompoundPredicate notPredicateWithSubpredicate:containPredicate];
            untrackedInsertedListInfos = [insertedMetaDatum filteredArrayUsingPredicate:doesntContainPredicate];
            
        });
        
        if (untrackedInsertedListInfos.count == 0 && trackedRemovedListInfos.count == 0 && updatedMetaDatum.count == 0) {
            return;
        }
        
        if ([self.delegate respondsToSelector:@selector(filesControllerWillChangeContent:)]) {
            [self.delegate filesControllerWillChangeContent:self];
        }
        
        // Remove
        for (MADMetaData *trackedRemovedListInfo in trackedRemovedListInfos) {
            __block NSInteger trackedRemovedListInfoIndex;
            
            dispatch_sync(self.fileMetaDataQueue, ^{
                trackedRemovedListInfoIndex = [self.fileMetaDatum indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                    if ([trackedRemovedListInfo.URL isEqual:((MADMetaData *)obj).URL]) {
                        *stop = YES;
                        return YES;
                    } else {
                        return NO;
                    }
                }];
                
                [self.fileMetaDatum removeObjectAtIndex: trackedRemovedListInfoIndex];
            });
            
            if ([self.delegate respondsToSelector:@selector(filesController:didRemoveListInfo:atIndex:)]) {
                [self.delegate filesController: self
                             didRemoveListInfo: trackedRemovedListInfo
                                       atIndex: trackedRemovedListInfoIndex];
            }
        }
        
        // Sort the untracked inserted list infos
        if (self.sortComparator) {
            untrackedInsertedListInfos = [untrackedInsertedListInfos sortedArrayUsingComparator:self.sortComparator];
        }
        
        // Insert
        for (MADMetaData *untrackedInsertedListInfo in untrackedInsertedListInfos) {
            __block NSInteger untrackedInsertedListInfoIndex;
            
            dispatch_sync(self.fileMetaDataQueue, ^{
                [self.fileMetaDatum addObject:untrackedInsertedListInfo];
                
                if (self.sortComparator) {
                    [self.fileMetaDatum sortUsingComparator:self.sortComparator];
                }
                
                untrackedInsertedListInfoIndex = [self.fileMetaDatum indexOfObject:untrackedInsertedListInfo];
                
                untrackedInsertedListInfoIndex = [self.fileMetaDatum indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                    if ([untrackedInsertedListInfo.URL isEqual:((MADMetaData *)obj).URL]) {
                        *stop = YES;
                        return YES;
                    } else {
                        return NO;
                    }
                }];
            });
            
            if ([self.delegate respondsToSelector:@selector(filesController:didInsertListInfo:atIndex:)]) {
                [self.delegate filesController: self
                             didInsertListInfo: untrackedInsertedListInfo
                                       atIndex: untrackedInsertedListInfoIndex];
            }
        }
        
        // Update
        for (MADMetaData *updatedListInfo in updatedMetaDatum) {
            __block NSInteger updatedListInfoIndex;
            
            dispatch_sync(self.fileMetaDataQueue, ^{
                updatedListInfoIndex = [self.fileMetaDatum indexOfObject:updatedListInfo];
                
                // Track the new list info instead of the old one.
                if (updatedListInfoIndex != NSNotFound) {
                    self.fileMetaDatum[updatedListInfoIndex] = updatedListInfo;
                } else {
                    updatedListInfoIndex = [self.fileMetaDatum indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                        if ([updatedListInfo.URL.lastPathComponent isEqualToString:((MADMetaData *)obj).URL.lastPathComponent]) {
                            *stop = YES;
                            return YES;
                        } else {
                            return NO;
                        }
                    }];
                    if (updatedListInfoIndex != NSNotFound) {
                        self.fileMetaDatum[updatedListInfoIndex] = updatedListInfo;
                    }
                }
            });
            
            if (updatedListInfoIndex != NSNotFound && [self.delegate respondsToSelector:@selector(filesController:didUpdateListInfo:atIndex:)]) {
                [self.delegate filesController:self didUpdateListInfo:updatedListInfo atIndex:updatedListInfoIndex];
            }
        }
        
        if ([self.delegate respondsToSelector:@selector(filesControllerDidChangeContent:completion:)]) {
            [self.delegate filesControllerDidChangeContent:self completion:^(BOOL success, NSError *error) {
                completion(success, error);
            }];
        }
    }];
}

#pragma mark - Convenience

- (NSArray *)listInfosByMappingURLs:(NSArray *)URLs {
    NSMutableArray *fileMetaDatum = [NSMutableArray arrayWithCapacity:URLs.count];
    
    for (NSURL *URL in URLs) {
        MADMetaData *fileMetaData = [[MADMetaData alloc] initWithURL:URL];
        
        [fileMetaDatum addObject:fileMetaData];
    }
    
    return fileMetaDatum;
}

@end
