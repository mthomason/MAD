//
//  MADFilesControllerDelegate.h
//  MADFileManager
//
//  Created by Michael Thomason on 5/24/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADFilesControllerDelegate_h
#define MADFilesControllerDelegate_h

@class MADFilesController, MADMetaData;

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

#endif /* MADFilesControllerDelegate_h */
