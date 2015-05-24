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

@interface MADFilesController () <MADFileCoordinatorDelegate>

/*!
 * The \c MADMetaData objects that are cached by the \c AAPLListsController to allow for users of the
 * \c AAPLListsController class to easily subscript the controller.
 */
@property (nonatomic, strong) NSMutableArray *fileMetaDatum;

/*!
 * @return A private, local queue to the \c AAPLListsController that is used to perform updates on
 *         \c listInfos.
 */
@property (nonatomic, strong) dispatch_queue_t fileMetaDataQueue;

/*!
 * The sort comparator that's set in initialization. The sort predicate ensures a strict sort ordering
 * of the \c listInfos array. If \c sortComparator is nil, the sort order is ignored.
 */
@property (nonatomic, copy) NSComparisonResult (^sortComparator)(MADMetaData *lhs, MADMetaData *rhs);

/*!
 * The queue in which the \c AAPLListsController object invokes delegate messages.
 */
@property (nonatomic, strong) NSOperationQueue *delegateQueue;

@end

@implementation MADFilesController
@synthesize listCoordinator = _listCoordinator;
@synthesize delegateQueue = _delegateQueue;

#pragma mark - Initialization

- (instancetype)initWithListCoordinator:(id<MADFileCoordinator>)listCoordinator
                          delegateQueue:(NSOperationQueue *)delegateQueue
                         sortComparator:(NSComparisonResult (^)(MADMetaData *lhs, MADMetaData *rhs))sortComparator {
    self = [super init];
    
    if (self) {
        
        _listCoordinator = listCoordinator;
        self.sortComparator = sortComparator;
        
        self.delegateQueue = delegateQueue ?: [NSOperationQueue mainQueue];
        
        dispatch_queue_t fileMetaDataQueue = dispatch_queue_create("com.everydayapps.mad.designer.queue.file.information", DISPATCH_QUEUE_SERIAL);
        self.fileMetaDataQueue = fileMetaDataQueue;
        
        NSMutableArray *fileMetaData = [[NSMutableArray alloc] init];
        self.fileMetaDatum = fileMetaData;
        
        self.listCoordinator.delegate = self;
    }
    
    return self;
}

- (void)startSearching {
    [self.listCoordinator startQuery];
}

- (void)stopSearching {
    [self.listCoordinator stopQuery];
}

#pragma mark - Property Overrides

- (NSInteger)count {
    return self.fileMetaDatum.count;
}

- (void)setListCoordinator:(id<MADFileCoordinator>)listCoordinator {
    if (![_listCoordinator isEqual:listCoordinator]) {
        id<MADFileCoordinator> oldListCoordinator = _listCoordinator;
        _listCoordinator = listCoordinator;
        
        [oldListCoordinator stopQuery];
        
        // Map the listInfo objects protected by listInfoQueue.
        __block NSArray *allURLs;
        dispatch_sync(self.fileMetaDataQueue, ^{
            allURLs = [self.fileMetaDatum valueForKey:@"URL"];
        });
        [self processContentChangesWithInsertedMetaDatum:@[] removedMetaDatum:allURLs updatedMetaDatum:@[]
                                              completion:^(BOOL success, NSError *error) {
                                                  
                                              }];
        
        _listCoordinator.delegate = self;
        oldListCoordinator.delegate = nil;
        
        [_listCoordinator startQuery];
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
    [self.listCoordinator removeFileAtURL: listInfo.URL];
}

- (void)duplicateFileInfo:(MADMetaData *)listInfo {
    [self.listCoordinator duplicateFileAtURL: listInfo.URL];
}

- (void)renameFileInfo:(MADMetaData *)listInfo toName:(NSString *)name {
    NSURL *url = listInfo.URL.copy;
    [self.listCoordinator renameFileAtURL: url toName: name];
}

- (void)createFileInfoForFile:(MADFile *)list withName:(NSString *)name {
    [self.listCoordinator createURLForFile:list withName:name];
}

- (BOOL)canCreateFileInfoWithName:(NSString *)name {
    return [self.listCoordinator canCreateFileWithName:name];
}

- (NSURL *)documentDirectory {
    return [self.listCoordinator documentsDirectory];
}

- (void)setFileInfoHasNewContents:(MADMetaData *)listInfo {
    dispatch_async(self.fileMetaDataQueue, ^{
        // Remove the old list info and replace it with the new one.
        NSInteger indexOfListInfo = [self.fileMetaDatum indexOfObject:listInfo];
        self.fileMetaDatum[indexOfListInfo] = listInfo;
        
        [self.delegateQueue addOperationWithBlock:^{
            if ([self.delegate respondsToSelector:@selector(listsControllerWillChangeContent:)]) {
                [self.delegate listsControllerWillChangeContent:self];
            }
            
            if ([self.delegate respondsToSelector:@selector(listsController:didUpdateListInfo:atIndex:)]) {
                [self.delegate listsController:self didUpdateListInfo:listInfo atIndex:indexOfListInfo];
            }
            
            if ([self.delegate respondsToSelector:@selector(listsControllerDidChangeContent:completion:)]) {
                [self.delegate listsControllerDidChangeContent:self completion:^(BOOL success, NSError *error) {
                    
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
        if ([self.delegate respondsToSelector:@selector(listsController:didFailCreatingListInfo:withError:)]) {
            [self.delegate listsController:self didFailCreatingListInfo:listInfo withError:error];
        }
    }];
}

- (void)fileCoordinatorDidFailDuplicatingFileAtURL:(NSURL *)URL withError:(NSError *)error {
    MADMetaData *listInfo = [[MADMetaData alloc] initWithURL:URL];
    [self.delegateQueue addOperationWithBlock:^{
        if ([self.delegate respondsToSelector:@selector(listsController:didFailDuplicatingListInfo:withError:)]) {
            [self.delegate listsController:self didFailDuplicatingListInfo:listInfo withError:error];
        }
    }];
}

- (void)fileCoordinatorDidFailRenamingFileAtURL:(NSURL *)URL withError:(NSError *)error {
    MADMetaData *listInfo = [[MADMetaData alloc] initWithURL:URL];
    [self.delegateQueue addOperationWithBlock:^{
        if ([self.delegate respondsToSelector:@selector(listsController:didFailRemovingListInfo:withError:)]) {
            [self.delegate listsController:self didFailRenamingListInfo:listInfo withError:error];
        }
    }];
}

- (void)fileCoordinatorDidFailRemovingFileAtURL:(NSURL *)URL withError:(NSError *)error {
    MADMetaData *listInfo = [[MADMetaData alloc] initWithURL:URL];
    [self.delegateQueue addOperationWithBlock:^{
        if ([self.delegate respondsToSelector:@selector(listsController:didFailRemovingListInfo:withError:)]) {
            [self.delegate listsController:self didFailRemovingListInfo:listInfo withError:error];
        }
    }];
}

#pragma mark - Change Processing

/*!
 * Processes changes to the \c AAPLListsController object's \c MADMetaData collection. This
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
    
    [self.delegateQueue addOperationWithBlock:^{
        
        // Filter out all lists that are already included in the tracked lists.
        __block NSArray *trackedRemovedListInfos;
        __block NSArray *untrackedInsertedListInfos;
        
        NSArray *fileMetaDatum = [NSArray arrayWithArray:self.fileMetaDatum];
 
        dispatch_sync(self.fileMetaDataQueue, ^{
            NSPredicate *containPredicate = [NSPredicate predicateWithFormat:@"self in %@", fileMetaDatum];
            trackedRemovedListInfos = [removedMetaDatum filteredArrayUsingPredicate:containPredicate];
            
            NSPredicate *doesntContainPredicate = [NSCompoundPredicate notPredicateWithSubpredicate:containPredicate];
            untrackedInsertedListInfos = [insertedMetaDatum filteredArrayUsingPredicate:doesntContainPredicate];
        });
        
        if (untrackedInsertedListInfos.count == 0 && trackedRemovedListInfos.count == 0 && updatedMetaDatum.count == 0) {
            return;
        }
        
        if ([self.delegate respondsToSelector:@selector(listsControllerWillChangeContent:)]) {
            [self.delegate listsControllerWillChangeContent:self];
        }
        
        // Remove
        for (MADMetaData *trackedRemovedListInfo in trackedRemovedListInfos) {
            __block NSInteger trackedRemovedListInfoIndex;
            
            dispatch_sync(self.fileMetaDataQueue, ^{
                trackedRemovedListInfoIndex = [self.fileMetaDatum indexOfObject:trackedRemovedListInfo];
                
                [self.fileMetaDatum removeObjectAtIndex: trackedRemovedListInfoIndex];
            });
            
            if ([self.delegate respondsToSelector:@selector(listsController:didRemoveListInfo:atIndex:)]) {
                [self.delegate listsController: self
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
            });
            
            if ([self.delegate respondsToSelector:@selector(listsController:didInsertListInfo:atIndex:)]) {
                [self.delegate listsController: self
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
                }
            });
            
            if (updatedListInfoIndex != NSNotFound && [self.delegate respondsToSelector:@selector(listsController:didUpdateListInfo:atIndex:)]) {
                [self.delegate listsController:self didUpdateListInfo:updatedListInfo atIndex:updatedListInfoIndex];
            }
        }
        
        if ([self.delegate respondsToSelector:@selector(listsControllerDidChangeContent:completion:)]) {
            [self.delegate listsControllerDidChangeContent:self completion:^(BOOL success, NSError *error) {
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
