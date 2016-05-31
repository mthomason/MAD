//
//  MADLocalFileCoordinator.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADLocalFileCoordinator.h"
#import "MADFileCoordinatorProtocol.h"

#import <Foundation/NSPredicate.h>
#import <Foundation/NSCompoundPredicate.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSFileManager.h>
#import "MADDirectoryMonitor.h"
#import "MADFileUtilities.h"
#import "NSURL+CommonURLs.h"
#import "NSURL+ConvenienceConstructors.h"
#import <dispatch/queue.h>

NSString * const MADPredicateFormatSelfInObject                 = @"self in %@";
NSString * const MADPredicateFormatComparsonPathExtension       = @"(pathExtension = %@)";
NSString * const MADPredicateFormatComparsonLastPathComponent   = @"(lastPathComponent = %@)";

@interface MADLocalFileCoordinator ()
            <MADDirectoryMonitorDelegate>

    @property (nonatomic, copy)     NSArray *currentLocalContents;
    @property (nonatomic, copy)   NSPredicate *predicate;
    @property (nonatomic, strong)   void (^firstQueryUpdateHandler)(void);
    @property (nonatomic, strong)   MADDirectoryMonitor *directoryMonitor;
    @property (nonatomic, copy)   NSString *fileGroup;

@end

@implementation MADLocalFileCoordinator

@synthesize delegate = _delegate;
@dynamic documentsDirectory;

#pragma mark - Initialization

- (instancetype)initWithPredicate:(NSPredicate *)predicate identifier:(NSString *)fileGroup
          firstQueryUpdateHandler:(void (^)(void))firstQueryUpdateHandler {

    if (self = [super init]) {

        _fileGroup = fileGroup.copy;
        _predicate = predicate.copy;
        
        self.firstQueryUpdateHandler = firstQueryUpdateHandler;
        
        NSURL *url = [NSURL newURLLocalDocumentsDirectoryForGroupIdentifier:fileGroup];
        
        MADDirectoryMonitor *directoryMonitor = [[MADDirectoryMonitor alloc] initWithURL:url];
        self.directoryMonitor = directoryMonitor;
        self.directoryMonitor.delegate = self;
        
        NSArray *currentLocalContents = [[NSArray alloc] init];
        self.currentLocalContents = currentLocalContents;

    }
    
    return self;
}

- (instancetype)initWithPathExtension:(NSString *)pathExtension identifier:(NSString *)fileGroup
              firstQueryUpdateHandler:(void (^)(void))firstQueryUpdateHandler {

    NSPredicate *predicate;
    predicate = [NSPredicate predicateWithFormat:MADPredicateFormatComparsonPathExtension,
                                                 pathExtension];
    
    if (self = [self initWithPredicate:predicate identifier:fileGroup
               firstQueryUpdateHandler:firstQueryUpdateHandler]) {
        self.fileGroup = fileGroup;
    }
    
    return self;
}

- (instancetype)initWithLastPathComponent:(NSString *)lastPathComponent
                               identifier:(NSString *)fileGroup
                  firstQueryUpdateHandler:(void (^)(void))firstQueryUpdateHandler {
    
    NSPredicate *predicate;
    predicate = [NSPredicate predicateWithFormat:MADPredicateFormatComparsonLastPathComponent,
                                                 lastPathComponent];
    
    if (self = [self initWithPredicate:predicate identifier:fileGroup
               firstQueryUpdateHandler:firstQueryUpdateHandler]) {
        self.fileGroup = fileGroup;
    }
    
    return self;
}

#pragma mark - MADFileCoordinator

- (void)startQuery {
    [self processChangeToLocalDocumentsDirectory];
    
    [self.directoryMonitor startMonitoring];
}

- (void)stopQuery {
    [self.directoryMonitor stopMonitoring];
}

- (void)removeFileAtURL:(NSURL *)URL {

    id <MADFileCoordinatorDelegate> __unsafe_unretained wdelegate = _delegate;
    [MADFileUtilities removeFileAtURL:URL withCompletionHandler:^(NSError *error) {
        if (error) {
            id <MADFileCoordinatorDelegate> __weak delegate = wdelegate;
            [delegate fileCoordinatorDidFailRemovingFileAtURL: URL
                                                    withError: error];
        } else {
            id <MADFileCoordinatorDelegate> __weak delegate = wdelegate;
            NSArray *inserts = [[NSArray alloc] init],
                    *removes = [[NSArray alloc] initWithObjects:URL, nil],
                    *updates = [[NSArray alloc] init];
            [delegate fileCoordinatorDidUpdateContentsWithInsertedURLs: inserts
                                                           removedURLs: updates
                                                           updatedURLs: removes];
        }
    }];
}

- (void)duplicateFileAtURL:(NSURL *)URL {

    id <MADFileCoordinatorDelegate> __unsafe_unretained wdelegate = _delegate;
    [MADFileUtilities duplicateFileAtURL:URL withCompletionHandler:^(NSURL *newURL, NSError *error) {
        if (error) {
            id <MADFileCoordinatorDelegate> __weak delegate = wdelegate;
            [delegate fileCoordinatorDidFailDuplicatingFileAtURL:URL withError:error];
        } else {
            id <MADFileCoordinatorDelegate> __weak delegate = wdelegate;
            NSArray *inserts = [[NSArray alloc] initWithObjects:newURL, nil],
                    *removes = [[NSArray alloc] init],
                    *updates = [[NSArray alloc] init];
            [delegate fileCoordinatorDidUpdateContentsWithInsertedURLs: inserts
                                                           removedURLs: removes
                                                           updatedURLs: updates];
        }
    }];
}

- (void)renameFileAtURL:(NSURL *)URL toName:(NSString *)name {

    id <MADFileCoordinatorDelegate> __unsafe_unretained wdelegate = _delegate;
    [MADFileUtilities renameFileAtURL:URL toName:name withCompletionHandler:^(NSURL *sourceURL,
                                                                              NSURL *newURL,
                                                                              NSError *error) {
        if (error) {
            id <MADFileCoordinatorDelegate> __weak delegate = wdelegate;
            [delegate fileCoordinatorDidFailRenamingFileAtURL:URL withError:error];
        } else {
            NSArray *inserts = [[NSArray alloc] initWithObjects:newURL, nil],
                    *removes = [[NSArray alloc] initWithObjects:sourceURL, nil],
                    *updates = [[NSArray alloc] init];
            id <MADFileCoordinatorDelegate> __weak delegate = wdelegate;
           [delegate fileCoordinatorDidUpdateContentsWithInsertedURLs:inserts
                                                          removedURLs:removes
                                                          updatedURLs:updates];
        }
    }];
}

- (void)createURLForFile:(MADFile *)list withName:(NSString *)name extention:(NSString *)extention
               fileGroup:(NSString *)fileGroup {

    NSURL *documentURL = [NSURL newURLLocalDocumentWithName:name extention:extention
                                                  fileGroup:fileGroup];
    
    id <MADFileCoordinatorDelegate> __unsafe_unretained wdelegate = _delegate;
    [MADFileUtilities createFile:list atURL:documentURL withCompletionHandler:^(NSError *error) {

        if (error) {
            id <MADFileCoordinatorDelegate> __weak delegate = wdelegate;
            [delegate fileCoordinatorDidFailCreatingFileAtURL:documentURL withError:error];
        }
        else {
            NSArray *inserts = [[NSArray alloc] initWithObjects:documentURL, nil],
                    *removes = [[NSArray alloc] init],
                    *updates = [[NSArray alloc] init];
            id <MADFileCoordinatorDelegate> __weak delegate = wdelegate;
            [delegate fileCoordinatorDidUpdateContentsWithInsertedURLs: inserts
                                                                removedURLs: removes
                                                                updatedURLs: updates];
        }
    }];
}

- (BOOL)canCreateFileWithName:(NSString *)name extention:(NSString *)extention
                    fileGroup:(NSString *)fileGroup {
    if (name.length <= 0) {
        return NO;
    }
    NSURL *documentURL = [NSURL newURLLocalDocumentWithName:name extention:extention
                                                  fileGroup:fileGroup];
    NSString *path = documentURL.path;
    if (path == nil) return NO;
    return ![[NSFileManager defaultManager] fileExistsAtPath:path];

}

#pragma mark - MADDirectoryMonitorDelegate

- (void)directoryMonitorDidObserveChange:(MADDirectoryMonitor *)directoryMonitor {
    [self processChangeToLocalDocumentsDirectory];
}

- (NSURL *)documentsDirectory {
    NSURL *url = [NSURL newURLLocalDocumentsDirectoryForGroupIdentifier:self.fileGroup];
    return url;
}

#pragma mark - Convenience

- (void)processChangeToLocalDocumentsDirectory {

    NSString *fileGroup = self.fileGroup.copy;
    NSPredicate *predicate = self.predicate.copy;

    id __weak wself = self;
    dispatch_queue_t defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(defaultQueue, ^{
    
        MADLocalFileCoordinator *sself = wself;
        if (sself == nil) return;
        
        NSURL *url = [NSURL newURLLocalDocumentsDirectoryForGroupIdentifier: fileGroup];
        
        NSArray *URLs;
        URLs = [[NSFileManager defaultManager] contentsOfDirectoryAtURL: url
                                             includingPropertiesForKeys: nil
                                                                options: NSDirectoryEnumerationSkipsPackageDescendants
                                                                  error: nil];
        
        NSArray *localListURLs = [URLs filteredArrayUsingPredicate:predicate];
        
        if (localListURLs.count > 0) {
            NSPredicate *containPredicate, *doesntContainPredicate;
            NSArray *insertedURLs, *removedURLs, *emptyArray;

            containPredicate = [NSPredicate predicateWithFormat:MADPredicateFormatSelfInObject,
                                                                sself.currentLocalContents];
            doesntContainPredicate = [NSCompoundPredicate notPredicateWithSubpredicate:containPredicate];
            
            insertedURLs = [localListURLs filteredArrayUsingPredicate:doesntContainPredicate];
            
            containPredicate = [NSPredicate predicateWithFormat:MADPredicateFormatSelfInObject, localListURLs];
            doesntContainPredicate = [NSCompoundPredicate notPredicateWithSubpredicate:containPredicate];
            
            removedURLs = [sself.currentLocalContents filteredArrayUsingPredicate:doesntContainPredicate];
            
            emptyArray = [[NSArray alloc] init];
            [sself.delegate fileCoordinatorDidUpdateContentsWithInsertedURLs: insertedURLs
                                                                 removedURLs: removedURLs
                                                                 updatedURLs: emptyArray];
            
            sself.currentLocalContents = localListURLs;
        }
        
        if (sself.firstQueryUpdateHandler) {
            sself.firstQueryUpdateHandler();
            sself.firstQueryUpdateHandler = nil;
        }
    });
}

@end
