//
//  MADFilesController.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MADDesigner_MADFilesController_h
#define MADDesigner_MADFilesController_h

#import <Foundation/Foundation.h>
#import <MADFoundation/NSFileManager+Common.h>

@class MADFilesController, MADMetaData, MADFile;

@protocol MADFileCoordinator;

@protocol MADFilesControllerDelegate <NSObject>

@optional

    - (void)filesControllerWillChangeContent:(MADFilesController *)filesController;
    - (void)filesController:(MADFilesController *)filesController didInsertListInfo:(MADMetaData *)listInfo atIndex:(NSInteger)index;
    - (void)filesController:(MADFilesController *)filesController didRemoveListInfo:(MADMetaData *)listInfo atIndex:(NSInteger)index;
    - (void)filesController:(MADFilesController *)filesController didUpdateListInfo:(MADMetaData *)listInfo atIndex:(NSInteger)index;
    - (void)filesControllerDidChangeContent:(MADFilesController *)filesController completion:(void (^)(BOOL success, NSError *error))completion;
    - (void)filesController:(MADFilesController *)filesController didFailCreatingListInfo:(MADMetaData *)listInfo
                  withError:(NSError *)error;
    - (void)filesController:(MADFilesController *)filesController didFailRemovingListInfo:(MADMetaData *)listInfo
                  withError:(NSError *)error;
    - (void)filesController:(MADFilesController *)filesController didFailDuplicatingListInfo:(MADMetaData *)listInfo
                  withError:(NSError *)error;
    - (void)filesController:(MADFilesController *)filesController didFailRenamingListInfo:(MADMetaData *)listInfo
                  withError:(NSError *)error;

@end

typedef void (^MADBlockCompletionFileStorageLocation)(BOOL cloudAvailble, NSURL *documents, NSURL *data);

@interface MADFilesController : NSObject

    @property (nonatomic, weak) id<MADFilesControllerDelegate> delegate;
    @property (readonly) NSURL *documentDirectory;
    @property (nonatomic, readonly) NSInteger count;
    @property (nonatomic, strong) id<MADFileCoordinator> fileCoordinator;

    - (instancetype)initWithFileCoordinator:(id<MADFileCoordinator>)fileCoordinator
                              delegateQueue:(NSOperationQueue *)delegateQueue
                             sortComparator:(NSComparisonResult (^)(MADMetaData *lhs, MADMetaData *rhs))sortComparator;

    - (void)startSearching;
    - (void)stopSearching;
    - (MADMetaData *)objectAtIndexedSubscript:(NSInteger)index;
    - (void)removeFileInfo:(MADMetaData *)listInfo;
    - (void)duplicateFileInfo:(MADMetaData *)listInfo;
    - (void)renameFileInfo:(MADMetaData *)listInfo toName:(NSString *)name;
    - (void)createFileInfoForFile:(MADFile *)list withName:(NSString *)name extention:(NSString *)extention fileGroup:(NSString *)fileGroup;
    - (BOOL)canCreateFileInfoWithName:(NSString *)name extention:(NSString *)extention fileGroup:(NSString *)fileGroup;
    - (void)setFileInfoHasNewContents:(MADMetaData *)listInfo;

    + (BOOL)isCloudAvailable;

    + (void)getFileStorageLocationsForUbiquityIdentifier: (NSString *)ubiquityIdentifier
                                         groupIdentifier: (NSString *)groupIdentifier
                                                   delay: (void (^)())handleLongRunningCall
                                              completion: (MADBlockCompletionFileStorageLocation)handleCompletion;

@end

#endif
