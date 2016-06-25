//
//  MADDocumentManager.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/16/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADDocumentManager.h"
#import <MADFileManager/MADFilesControllerDelegate.h>
#import <UIKit/UICollectionViewController.h>
#import <MADFileManager/MADFileInfo.h>

#import <MADExplorer/MADFileLocationManager.h>
#import <MADFileManager/MADFilesController.h>
#import <MADFileManager/MADFileLocationManagerDelegate.h>

#import <MAD/MADConstants.h>
#import "Constants.h"

#import "MADDocumentManagerProtocol.h"

@interface MADDocumentManager ()
    <MADFilesControllerDelegate,
        MADFileLocationManagerDelegate>

    @property (nonatomic, readwrite, strong) MADFileLocationManager *fileLocationManager;
    @property (nonatomic, readwrite, strong) NSMutableIndexSet *batchInserts;
    @property (nonatomic, readwrite, strong) NSMutableIndexSet *batchRemoves;
    @property (nonatomic, readwrite, strong) NSMutableIndexSet *batchUpdates;

    @property (nonatomic, copy) void (^handleCellConfiguration)(MADCollectionViewCellDocument *);

@end

@implementation MADDocumentManager

- (instancetype)initWithCellConfiguration:(void (^)(MADCollectionViewCellDocument *cell))cellCondiguration {
    if (self = [super init]) {
        _handleCellConfiguration = cellCondiguration;
        [MADDocumentManager commonInitalization:self];
    }
    return self;
}

- (instancetype)init {
    if (self = [super init]) {
        [MADDocumentManager commonInitalization:self];
    }
    return self;
}

+ (void)commonInitalization:(MADDocumentManager *)this {
    MADFileLocationManager *fileLocationManager;
    fileLocationManager = [[MADFileLocationManager alloc] init];
    fileLocationManager.delegate = this;
    fileLocationManager.filesController.delegate = this;
    this.fileLocationManager = fileLocationManager;
    
    NSMutableIndexSet *inserts = [[NSMutableIndexSet alloc] init],
    *removes = [[NSMutableIndexSet alloc] init],
    *updates = [[NSMutableIndexSet alloc] init];
    this.batchInserts = inserts,
    this.batchRemoves = removes,
    this.batchUpdates = updates;
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

- (NSString *)groupIdentifier { return MADIdentifierGroup; }

- (NSString *)ubiquityIdentifier { return MADUbiquityIdentifier; }

- (NSString *)fileExtention { return MADFileExtentionMobleApplicationDocument; }

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
    //NSLog(@"%s", __PRETTY_FUNCTION__);

    [_batchInserts removeAllIndexes];
    [_batchRemoves removeAllIndexes];
    [_batchUpdates removeAllIndexes];
}

- (void)filesController:(MADFilesController *)filesController
      didInsertFileInfo:(MADFileInfo *)fileInfo atIndex:(NSUInteger)index {

    //NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.batchInserts addIndex:index];

}

- (void)filesController:(MADFilesController *)filesController
      didRemoveFileInfo:(MADFileInfo *)fileInfo atIndex:(NSUInteger)index {

    //NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.batchRemoves addIndex:index];

}

- (void)filesController:(MADFilesController *)filesController
      didUpdateFileInfo:(MADFileInfo *)fileInfo atIndex:(NSUInteger)index {

    //NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.batchUpdates addIndex:index];

}

- (void)filesControllerDidChangeContent:(MADFilesController *)filesController
                             completion:(void (^)(BOOL, NSError *))completion {

    //NSLog(@"%s", __PRETTY_FUNCTION__);

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
    
    _handleCellConfiguration(cell);
    
    return cell;
}

@end
