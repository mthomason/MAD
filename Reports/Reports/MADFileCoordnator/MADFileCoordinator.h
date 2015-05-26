//
//  MADFileCoordinator.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADFileCoordinator_h
#define MAD_Designer_MADFileCoordinator_h

#import <Foundation/Foundation.h>

@class MADFile;

@protocol MADFileCoordinatorDelegate;

@protocol MADFileCoordinator <NSObject>

@property (nonatomic, weak) id<MADFileCoordinatorDelegate> delegate;
@property (nonatomic, strong, readonly) NSURL *documentsDirectory;

- (void)startQuery;
- (void)stopQuery;
- (void)removeFileAtURL:(NSURL *)URL;
- (void)duplicateFileAtURL:(NSURL *)URL;
- (void)renameFileAtURL:(NSURL *)URL toName:(NSString *)name;
- (void)createURLForFile:(MADFile *)list withName:(NSString *)name;
- (BOOL)canCreateFileWithName:(NSString *)name;

@end


@protocol MADFileCoordinatorDelegate <NSObject>

- (void)fileCoordinatorDidUpdateContentsWithInsertedURLs:(NSArray *)insertedURLs
                                             removedURLs:(NSArray *)removedURLs
                                             updatedURLs:(NSArray *)updatedURLs;

- (void)fileCoordinatorDidUpdateContentsWithInsertedMetaDatum:(NSArray *)insertedMetaDatum
                                             removedMetaDatum:(NSArray *)removedMetaDatum
                                             updatedMetaDatum:(NSArray *)updatedMetaDatum
                                                   completion: (void (^)(BOOL success, NSError *error))completion;

- (void)fileCoordinatorDidFailRemovingFileAtURL:(NSURL *)URL withError:(NSError *)error;
- (void)fileCoordinatorDidFailDuplicatingFileAtURL:(NSURL*)URL withError:(NSError *)error;
- (void)fileCoordinatorDidFailRenamingFileAtURL:(NSURL *)URL withError:(NSError *)error;
- (void)fileCoordinatorDidFailCreatingFileAtURL:(NSURL *)URL withError:(NSError *)error;

@end

#endif
