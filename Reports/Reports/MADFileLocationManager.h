//
//  MADFileLocationManager.h
//  MAD
//
//  Created by Michael Thomason on 9/25/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AAPLListCoordinatorDelegate <NSObject>

- (void)listCoordinatorDidUpdateContentsWithInsertedURLs:(NSArray *)insertedURLs removedURLs:(NSArray *)removedURLs updatedURLs:(NSArray *)updatedURLs;
- (void)listCoordinatorDidFailRemovingListAtURL:(NSURL *)URL withError:(NSError *)error;
- (void)listCoordinatorDidFailCreatingListAtURL:(NSURL *)URL withError:(NSError *)error;

@end

@interface MADFileLocationManager : NSObject

@property (nonatomic, weak) id<AAPLListCoordinatorDelegate> delegate;
@property (nonatomic, strong) NSMutableArray *documents;

- (instancetype)initWithPathExtension:(NSString *)pathExtension;
- (void)startQuery;
- (void)stopQuery;
//- (void)removeListAtURL:(NSURL *)URL;                                 //Should be tracked because we use UIDoc
//- (void)createURLForList:(AAPLList *)list withName:(NSString *)name;  //Should be tracked because we use UIDoc
//- (BOOL)canCreateDocumentWithName:(NSString *)name;

@end
