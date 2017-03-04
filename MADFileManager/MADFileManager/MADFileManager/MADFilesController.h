//
//  MADFilesController.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADDesigner_MADFilesController_h
#define MADDesigner_MADFilesController_h

#import <Foundation/NSObject.h>
#import <MADFileManager/MADAppStorageOption.h>

@protocol MADFileCoordinatorProtocol, MADFilesControllerDelegate;

@class NSOperationQueue, MADFilesController, MADMetaData;

typedef void (^MADBlockFileStorageLocation)(BOOL cloudAvailble, NSURL *documents, NSURL *data);

@interface MADFilesController : NSObject

    @property (nonatomic, weak) id <MADFilesControllerDelegate> delegate;
    @property (nonatomic, strong) id <MADFileCoordinatorProtocol> fileCoordinator;

    @property (readonly) NSURL *documentDirectory;

    @property (nonatomic, readonly) NSUInteger count;

    - (instancetype)initWithFileCoordinator:(id <MADFileCoordinatorProtocol>)fileCoordinator
                              delegateQueue:(NSOperationQueue *)delegateQueue
                             sortComparator:(NSComparisonResult (^)(MADMetaData *lhs,
                                                                    MADMetaData *rhs))sortComparator;

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
    - (void)setFileInfoHasNewContents:(MADMetaData *)fileInfo;

    + (BOOL)isCloudReadilyAvailable;
    + (void)getFileStorageLocationsForUbiquityIdentifier: (NSString *)ubiquityIdentifier
                                         groupIdentifier: (NSString *)groupIdentifier
                                                   delay: (void (^)())handleLongRunningCall
                                              completion: (MADBlockFileStorageLocation)handleCompletion;

    - (BOOL)canCreateFileInfoWithName:(NSString *)name extention:(NSString *)extention
                            fileGroup:(NSString *)fileGroup;

@end

#endif
