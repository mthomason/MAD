//
//  MADFilesController.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MADDesigner_MADFilesController_h
#define MADDesigner_MADFilesController_h

#import "MADStorageState.h"
#import <Foundation/NSObject.h>

@class MADFilesController, MADMetaData, MADFile;
@class NSOperationQueue;

@protocol MADFileCoordinator;

@protocol MADFilesControllerDelegate <NSObject>

@optional

    - (void)filesControllerWillChangeContent:(MADFilesController *)filesController;

    - (void)filesController:(MADFilesController *)filesController
          didInsertFileInfo:(MADMetaData *)fileInfo atIndex:(NSUInteger)index;

    - (void)filesController:(MADFilesController *)filesController
          didRemoveFileInfo:(MADMetaData *)fileInfo atIndex:(NSUInteger)index;

    - (void)filesController:(MADFilesController *)filesController
          didUpdateFileInfo:(MADMetaData *)fileInfo atIndex:(NSUInteger)index;

    - (void)filesControllerDidChangeContent:(MADFilesController *)filesController
                                 completion:(void (^)(BOOL success, NSError *error))completion;
    - (void)filesController:(MADFilesController *)filesController
    didFailCreatingFileInfo:(MADMetaData *)fileInfo
                  withError:(NSError *)error;
    - (void)filesController:(MADFilesController *)filesController
    didFailRemovingFileInfo:(MADMetaData *)fileInfo
                  withError:(NSError *)error;

    - (void)filesController:(MADFilesController *)filesController
 didFailDuplicatingFileInfo:(MADMetaData *)fileInfo
                  withError:(NSError *)error;

    - (void)filesController:(MADFilesController *)filesController
    didFailRenamingFileInfo:(MADMetaData *)fileInfo
                  withError:(NSError *)error;

@end

typedef void (^MADBlockCompletionFileStorageLocation)(BOOL cloudAvailble, NSURL *documents, NSURL *data);

@interface MADFilesController : NSObject

    @property (nonatomic, weak) id <MADFilesControllerDelegate> delegate;
    @property (readonly) NSURL *documentDirectory;

    @property (nonatomic, readonly) NSUInteger count;
    @property (nonatomic, strong) id <MADFileCoordinator> fileCoordinator;

    - (instancetype)initWithFileCoordinator:(id<MADFileCoordinator>)fileCoordinator
                              delegateQueue:(NSOperationQueue *)delegateQueue
                             sortComparator:(NSComparisonResult (^)(MADMetaData *lhs, MADMetaData *rhs))sortComparator;

    + (instancetype)newFilesControllerWithPathExtension: (NSString *)pathExtension
                                          storageOption: (MADAppStorage)storageOption
                                             identifier: (NSString *)identifier
                                      firstQueryHandler: (void (^)(void))firstQueryHandler;

    + (instancetype)newFilesControllerWithLastPathComponent: (NSString *)lastPathComponent
                                              storageOption: (MADAppStorage)storageOption
                                                 identifier: (NSString *)identifier
                                          firstQueryHandler: (void (^)(void))firstQueryHandler;


    - (MADMetaData *)objectAtIndexedSubscript:(NSUInteger)index;

    - (void)startSearching;
    - (void)stopSearching;
    - (void)removeFileInfo:(MADMetaData *)fileInfo;
    - (void)duplicateFileInfo:(MADMetaData *)fileInfo;
    - (void)renameFileInfo:(MADMetaData *)fileInfo toName:(NSString *)name;
    - (void)createFileInfoForFile:(MADFile *)list withName:(NSString *)name
                        extention:(NSString *)extention fileGroup:(NSString *)fileGroup;
    - (void)setFileInfoHasNewContents:(MADMetaData *)fileInfo;
    + (bool)isCloudAvailable;

    + (void)getFileStorageLocationsForUbiquityIdentifier: (NSString *)ubiquityIdentifier
                                         groupIdentifier: (NSString *)groupIdentifier
                                                   delay: (void (^)())handleLongRunningCall
                                              completion: (MADBlockCompletionFileStorageLocation)handleCompletion;

    - (BOOL)canCreateFileInfoWithName:(NSString *)name extention:(NSString *)extention
                            fileGroup:(NSString *)fileGroup;

@end

#endif
