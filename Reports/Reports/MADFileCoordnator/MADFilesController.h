//
//  MADFilesController.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MADFilesController, MADMetaData, MADFile;

@protocol MADFileCoordinator;

@protocol MADFilesControllerDelegate <NSObject>

@optional

    - (void)listsControllerWillChangeContent:(MADFilesController *)listsController;
    - (void)listsController:(MADFilesController *)listsController didInsertListInfo:(MADMetaData *)listInfo atIndex:(NSInteger)index;
    - (void)listsController:(MADFilesController *)listsController didRemoveListInfo:(MADMetaData *)listInfo atIndex:(NSInteger)index;
    - (void)listsController:(MADFilesController *)listsController didUpdateListInfo:(MADMetaData *)listInfo atIndex:(NSInteger)index;
    - (void)listsControllerDidChangeContent:(MADFilesController *)listsController completion:(void (^)(BOOL success, NSError *error))completion;
    - (void)listsController:(MADFilesController *)listsController didFailCreatingListInfo:(MADMetaData *)listInfo
                  withError:(NSError *)error;
    - (void)listsController:(MADFilesController *)listsController didFailRemovingListInfo:(MADMetaData *)listInfo
                  withError:(NSError *)error;
    - (void)listsController:(MADFilesController *)listsController didFailDuplicatingListInfo:(MADMetaData *)listInfo
                  withError:(NSError *)error;
    - (void)listsController:(MADFilesController *)listsController didFailRenamingListInfo:(MADMetaData *)listInfo
                  withError:(NSError *)error;

@end

@interface MADFilesController : NSObject

    @property (nonatomic, weak) id<MADFilesControllerDelegate> delegate;
    @property (nonatomic, readonly) NSURL *documentDirectory;
    @property (nonatomic, readonly) NSInteger count;
    @property (nonatomic, strong) id<MADFileCoordinator> listCoordinator;

    - (instancetype)initWithListCoordinator:(id<MADFileCoordinator>)listCoordinator
                              delegateQueue:(NSOperationQueue *)delegateQueue
                             sortComparator:(NSComparisonResult (^)(MADMetaData *lhs, MADMetaData *rhs))sortComparator;

    - (void)startSearching;
    - (void)stopSearching;
    - (MADMetaData *)objectAtIndexedSubscript:(NSInteger)index;
    - (void)removeFileInfo:(MADMetaData *)listInfo;
    - (void)duplicateFileInfo:(MADMetaData *)listInfo;
    - (void)renameFileInfo:(MADMetaData *)listInfo toName:(NSString *)name;
    - (void)createFileInfoForFile:(MADFile *)list withName:(NSString *)name;
    - (BOOL)canCreateFileInfoWithName:(NSString *)name;
    - (void)setFileInfoHasNewContents:(MADMetaData *)listInfo;

@end
