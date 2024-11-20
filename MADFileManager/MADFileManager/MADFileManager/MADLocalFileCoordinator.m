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

#import <dispatch/queue.h>

#import <Foundation/NSPredicate.h>
#import <Foundation/NSCompoundPredicate.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSFileManager.h>

#import <MADFoundation/MADURL.h>

#import "MADDirectoryMonitor.h"
#import "MADFileUtilities.h"
#import "MADDirectoryMonitorProtocol.h"

@interface MADLocalFileCoordinator ()
            <MADDirectoryMonitorProtocol>

    @property (nonatomic, copy)     NSArray *currentLocalContents;
    @property (nonatomic, copy)     NSPredicate *predicate;
    @property (nonatomic, strong)   void (^firstQueryUpdateHandler)(void);
    @property (nonatomic, strong)   MADDirectoryMonitor *directoryMonitor;
    @property (nonatomic, copy)     NSString *fileGroup;

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
        
        NSURL *url = [MADURL newURLLocalDocumentsDirectoryForGroupIdentifier:fileGroup];
        
        MADDirectoryMonitor *directoryMonitor = [[MADDirectoryMonitor alloc] initWithURL:url];
        self.directoryMonitor = directoryMonitor;
        self.directoryMonitor.delegate = self;
        
        NSArray *currentLocalContents = [[NSArray alloc] init];
        self.currentLocalContents = currentLocalContents;

    }
    
    return self;
}

- (instancetype)initWithPathExtension: (NSString *)pathExtension
                           identifier: (NSString *)fileGroup
              firstQueryUpdateHandler: (void (^)(void))firstQueryUpdateHandler {

    NSString * const MADPredicateFormatComparsonPathExtension = @"(pathExtension = %@)";
    NSPredicate *predicate;
    predicate = [NSPredicate predicateWithFormat:MADPredicateFormatComparsonPathExtension,
                                                 pathExtension];
    
    if (self = [self initWithPredicate: predicate
                            identifier: fileGroup
               firstQueryUpdateHandler: firstQueryUpdateHandler]) {
        
        self.fileGroup = fileGroup;
        
    }
    
    return self;
}

- (instancetype)initWithLastPathComponent: (NSString *)lastPathComponent
                               identifier: (NSString *)fileGroup
                  firstQueryUpdateHandler: (void (^)(void))firstQueryUpdateHandler {
    
    NSString *MADPredicateFormatComparsonLastPathComponent = @"(lastPathComponent = %@)";
    NSPredicate *predicate;
    predicate = [NSPredicate predicateWithFormat:MADPredicateFormatComparsonLastPathComponent,
                                                 lastPathComponent];
    
    if (self = [self initWithPredicate: predicate
                            identifier: fileGroup
               firstQueryUpdateHandler: firstQueryUpdateHandler]) {
        
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

    id <MADFileCoordinatorDelegate> __weak wdelegate = _delegate;
    [MADFileUtilities removeFileAtURL:URL completion:^(NSError *error) {
        
        id <MADFileCoordinatorDelegate> delegate = wdelegate;
        if (error) {
            [delegate fileCoordinatorDidFailRemovingFileAtURL: URL
                                                    withError: error];
        } else {
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

    id <MADFileCoordinatorDelegate> __weak wdelegate = _delegate;
    [MADFileUtilities duplicateFileAtURL:URL completion:^(NSURL *newURL, NSError *error) {
        id <MADFileCoordinatorDelegate> delegate = wdelegate;
        if (error) {
            [delegate fileCoordinatorDidFailDuplicatingFileAtURL:URL withError:error];
        } else {
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

    id <MADFileCoordinatorDelegate> __weak wdelegate = _delegate;
    [MADFileUtilities renameFileAtURL:URL toName:name completion:^(NSURL *sourceURL,
                                                                   NSURL *newURL,
                                                                   NSError *error) {
        id <MADFileCoordinatorDelegate> delegate = wdelegate;
        if (error) {
            [delegate fileCoordinatorDidFailRenamingFileAtURL:URL withError:error];
        } else {
            NSArray *inserts = [[NSArray alloc] initWithObjects:newURL, nil],
                    *removes = [[NSArray alloc] initWithObjects:sourceURL, nil],
                    *updates = [[NSArray alloc] init];
           [delegate fileCoordinatorDidUpdateContentsWithInsertedURLs:inserts
                                                          removedURLs:removes
                                                          updatedURLs:updates];
        }
    }];
}

- (void)createURLWithName:(NSString *)name
                extention:(NSString *)extention
                fileGroup:(NSString *)fileGroup {

    NSURL *documentURL = [MADURL newURLLocalDocumentWithName:name extention:extention
                                                   fileGroup:fileGroup];
    
    id <MADFileCoordinatorDelegate> __weak wdelegate = _delegate;
    [MADFileUtilities createFileAtURL:documentURL completion:^(NSError *error) {

        id <MADFileCoordinatorDelegate> delegate = wdelegate;
        if (error) {
            [delegate fileCoordinatorDidFailCreatingFileAtURL:documentURL withError:error];
        }
        else {
            NSArray *inserts = [[NSArray alloc] initWithObjects:documentURL, nil],
                    *removes = [[NSArray alloc] init],
                    *updates = [[NSArray alloc] init];
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
    NSURL *documentURL = [MADURL newURLLocalDocumentWithName: name
                                                   extention: extention
                                                   fileGroup: fileGroup];
    NSString *path = documentURL.path;
    if (path == nil) return NO;
    return ![[NSFileManager defaultManager] fileExistsAtPath:path];

}

#pragma mark - MADDirectoryMonitorProtocol

- (void)directoryMonitorDidObserveChange:(MADDirectoryMonitor *)directoryMonitor {
    [self processChangeToLocalDocumentsDirectory];
}

- (NSURL *)documentsDirectory {
    NSURL *url = [MADURL newURLLocalDocumentsDirectoryForGroupIdentifier:self.fileGroup];
    return url;
}

#pragma mark - Convenience

- (void)processChangeToLocalDocumentsDirectory {

    NSString *fileGroup = self.fileGroup.copy;
    NSPredicate *predicate = self.predicate.copy;

    dispatch_queue_t defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);

    typeof(self) __weak wself = self;

    void (^updateContent)(void);
    updateContent = ^{
        
        MADLocalFileCoordinator *sself = wself;
        if (sself == nil) return;
        
        NSURL *url = [MADURL newURLLocalDocumentsDirectoryForGroupIdentifier: fileGroup];
        
        NSArray <NSURL *> *urls;
        urls = [[NSFileManager defaultManager] contentsOfDirectoryAtURL: url
                                             includingPropertiesForKeys: nil
                                                                options: NSDirectoryEnumerationSkipsPackageDescendants
                                                                  error: nil];
        
        NSArray <NSURL *> *localListURLs = [urls filteredArrayUsingPredicate:predicate];
        
        if (localListURLs.count > 0) {
            
            NSString *MADPredicateFormatSelfInObject = @"self in %@";
            NSPredicate *containPredicate, *doesntContainPredicate;
            
            NSArray <NSURL *> *insertedURLs;
            NSArray <NSURL *> *removedURLs;
            NSArray <NSURL *> *emptyArray;
            
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
    };
    dispatch_async(defaultQueue, updateContent);
}

- (id)debugQuickLookObject {
    NSMutableString *debug = [[NSMutableString alloc] init];
    NSString *classname = NSStringFromClass([self class]);
    id uppercaseClassname = [classname uppercaseString];
    [debug appendFormat:@"--%@--\n", uppercaseClassname];
    [debug appendFormat:@"File group:\t%@\n", self.fileGroup];
    [debug appendFormat:@"Current contents:\t%@", self.currentLocalContents];
    return debug;
}

@end
