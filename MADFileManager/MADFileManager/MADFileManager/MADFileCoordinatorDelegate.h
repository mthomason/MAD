//
//  MADFileCoordinatorDelegate.h
//  MADFileManager
//
//  Created by Michael Thomason on 5/31/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MADFileCoordinatorDelegate_h
#define MADFileCoordinatorDelegate_h

@protocol MADFileCoordinatorDelegate <NSObject>

    - (void)fileCoordinatorDidUpdateContentsWithInsertedURLs: (NSArray *)insertedURLs
                                                 removedURLs: (NSArray *)removedURLs
                                                 updatedURLs: (NSArray *)updatedURLs;

    - (void)fileCoordinatorDidUpdateContentsWithInsertedMetaDatum: (NSArray *)insertedMetaDatum
                                                 removedMetaDatum: (NSArray *)removedMetaDatum
                                                 updatedMetaDatum: (NSArray *)updatedMetaDatum
                                                       completion: (void (^)(BOOL success,
                                                                             NSError *error))completion;

    - (void)fileCoordinatorDidFailRemovingFileAtURL:(NSURL *)URL withError:(NSError *)error;
    - (void)fileCoordinatorDidFailDuplicatingFileAtURL:(NSURL*)URL withError:(NSError *)error;
    - (void)fileCoordinatorDidFailRenamingFileAtURL:(NSURL *)URL withError:(NSError *)error;
    - (void)fileCoordinatorDidFailCreatingFileAtURL:(NSURL *)URL withError:(NSError *)error;

@end

#endif /* MADFileCoordinatorDelegate_h */
