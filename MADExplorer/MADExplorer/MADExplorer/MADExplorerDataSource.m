//
//  MADExplorerDataSource.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/16/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADExplorerDataSource.h"

#import <UIKit/UIViewController.h>

#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADAppDelegate.h>
#import <MADFoundation/MADApplicationProtocol.h>

#import <MADFileManager/MADFilesControllerDelegate.h>
#import <MADFileManager/MADFilesController.h>
#import <MADFileManager/MADFileInfo.h>

#import "MADDocumentManagerProtocol.h"
#import "MADFileLocationManager.h"

typedef void (^MADBlockConfigureDocumentCell)(MADCollectionViewCellDocument *);

@interface MADExplorerDataSource ()
    <MADFilesControllerDelegate>

    @property (nonatomic, readwrite, strong) MADFileLocationManager *fileLocationManager;
    @property (nonatomic, readwrite, strong) NSMutableIndexSet *batchInserts;
    @property (nonatomic, readwrite, strong) NSMutableIndexSet *batchRemoves;
    @property (nonatomic, readwrite, strong) NSMutableIndexSet *batchUpdates;

    @property (nonatomic, copy) MADBlockConfigureDocumentCell handleCellConfiguration;

@end

@implementation MADExplorerDataSource {
    NSString *_extension;
}

- (instancetype)init {
    return [self initWithFileExtension:nil cellConfiguration:nil];
}

- (instancetype)initWithFileExtension:(NSString *)fileExtension
                    cellConfiguration:(MADBlockConfigureDocumentCell)cellCondiguration {
    if (self = [super init]) {

        _extension = fileExtension.copy;
        
        MADFileLocationManager *fileLocationManager;
        fileLocationManager = [[MADFileLocationManager alloc] init];
        fileLocationManager.delegate = self;
        fileLocationManager.filesController.delegate = self;
        self.fileLocationManager = fileLocationManager;
        
        NSMutableIndexSet *inserts = [[NSMutableIndexSet alloc] init],
                          *removes = [[NSMutableIndexSet alloc] init],
                          *updates = [[NSMutableIndexSet alloc] init];

        self.batchInserts = inserts,
        self.batchRemoves = removes,
        self.batchUpdates = updates;
    }
    return self;
}

- (UIViewController *)presentingController {
    return _delegate;
}

#pragma mark -
#pragma mark Public

- (NSUInteger)count {
    return _fileLocationManager.filesController.count;
}

- (MADMetaData *)metadataAtIndex:(NSUInteger)index {
    return [_fileLocationManager.filesController objectAtIndexedSubscript: index];
}

- (void)updateCloudPreferences {
    [self.fileLocationManager getUserCloudPrefs];
}

- (void)rename:(NSString *)newName itemAtIndex:(NSUInteger)index {
    MADMetaData *metadata = [_fileLocationManager.filesController objectAtIndexedSubscript: index];
    [self.fileLocationManager.filesController renameFileInfo:metadata toName:newName];

}

- (void)removeItemAtIndex:(NSUInteger)index {
    MADMetaData *metadata = [_fileLocationManager.filesController objectAtIndexedSubscript: index];
    [self.fileLocationManager.filesController removeFileInfo:metadata];
}

- (void)duplicateItemAtIndex:(NSUInteger)index {
    MADMetaData *metadata = [_fileLocationManager.filesController objectAtIndexedSubscript: index];
    [self.fileLocationManager.filesController duplicateFileInfo:metadata];
}

#pragma mark -
#pragma mark MADFileLocationManagerDelegate

- (NSString *)groupIdentifier {
    MADAppDelegate appDelegate = [MADApplication AppDelegate];
    NSString *groupIdentifier = appDelegate.groupIdentifier.copy;
    return  groupIdentifier;
}

- (NSString *)ubiquityIdentifier {
    MADAppDelegate appDelegate = [MADApplication AppDelegate];
    NSString *ubiquityIdentifier = appDelegate.ubiquityIdentifier.copy;
    return  ubiquityIdentifier;
}

- (NSString *)fileExtention { return _extension; }

- (void)didConfigureFilesController:(MADFilesController *)filesController {
    filesController.delegate = self;
}

- (void)didDisconnectFromCloud:(id)sender {
    [_delegate handleDidDisconnectFromClound:self];
}

- (void)startLongRunningActivity {
    [_delegate handleDidStartLongRunningActivity];
}

- (void)completedLongRunningActivity {
    [_delegate handleDidCompletedLongRunningActivity];
}

#pragma mark -
#pragma mark MADFilesControllerDelegate

- (void)filesControllerWillChangeContent:(MADFilesController *)filesController {
    [_batchInserts removeAllIndexes];
    [_batchRemoves removeAllIndexes];
    [_batchUpdates removeAllIndexes];
}

- (void)filesController:(MADFilesController *)filesController
      didInsertFileInfo:(MADFileInfo *)fileInfo atIndex:(NSUInteger)index {
    [self.batchInserts addIndex:index];
}

- (void)filesController:(MADFilesController *)filesController
      didRemoveFileInfo:(MADFileInfo *)fileInfo atIndex:(NSUInteger)index {
    [self.batchRemoves addIndex:index];
}

- (void)filesController:(MADFilesController *)filesController
      didUpdateFileInfo:(MADFileInfo *)fileInfo atIndex:(NSUInteger)index {
    [self.batchUpdates addIndex:index];
}

- (void)filesControllerDidChangeContent:(MADFilesController *)filesController
                             completion:(void (^)(BOOL, NSError *))completion {

    NSMutableArray *inserts = [[NSMutableArray alloc] initWithCapacity: _batchInserts.count],
                   *removes = [[NSMutableArray alloc] initWithCapacity: _batchRemoves.count],
                   *updates = [[NSMutableArray alloc] initWithCapacity: _batchUpdates.count];

    NSIndexPath *path;
    NSUInteger i;

    i = _batchInserts.firstIndex;
    while (i != NSNotFound) {
        path = [NSIndexPath indexPathForItem:(NSInteger)i inSection:0];
        [inserts addObject:path];
        i = [_batchInserts indexGreaterThanIndex: i];
    }
    
    i = _batchRemoves.firstIndex;
    while (i != NSNotFound) {
        path = [NSIndexPath indexPathForItem:(NSInteger)i inSection:0];
        [removes addObject:path];
        i = [_batchRemoves indexGreaterThanIndex: i];
    }

    i = _batchUpdates.firstIndex;
    while (i != NSNotFound) {
        path = [NSIndexPath indexPathForItem:(NSInteger)i inSection:0];
        [updates addObject:path];
        i = [_batchUpdates indexGreaterThanIndex: i];
    }

    [updates removeObjectsInArray:inserts];
    [updates removeObjectsInArray:removes];


    void (^handleCompletion)(BOOL, NSError *);
    handleCompletion = ^(BOOL success, NSError *error) { completion(YES, nil); };
    [self.delegate documentManagerDidChangeContent: inserts
                                           removes: removes
                                           updates: updates
                                        completion: handleCompletion];

}

- (void)filesController:(MADFilesController *)filesController
                didFailCreatingFileInfo:(MADFileInfo *)fileInfo withError:(NSError *)error {

}

- (void)filesController:(MADFilesController *)filesController
                didFailRemovingFileInfo:(MADFileInfo *)fileInfo withError:(NSError *)error {
    
}

- (void)filesController:(MADFilesController *)filesController
                didFailDuplicatingFileInfo:(MADFileInfo *)fileInfo withError:(NSError *)error {

}

- (NSURL *)documentsDirectory {
    return _fileLocationManager.filesController.documentDirectory;
}

#pragma mark -
#pragma mark UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView { return 1; }

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    return (NSInteger)self.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *MADIDCellDocumentIdentifier  = @"MADCollectionViewCellDocumentIdentifier";
    
    id cell;
    cell = [collectionView dequeueReusableCellWithReuseIdentifier: MADIDCellDocumentIdentifier
                                                     forIndexPath: indexPath];

    if (_handleCellConfiguration)
        _handleCellConfiguration(cell);
    
    return cell;
}

@end
