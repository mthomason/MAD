//
//  MADFileLocationManager.h
//  MAD
//
//  Created by Michael Thomason on 9/25/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADFileLocationManager_h
#define Reports_MADFileLocationManager_h

#import <Foundation/Foundation.h>

extern NSString * const MADUtiType;

@protocol MADFileLocationManagerDelegate <NSObject>

- (void)listCoordinatorDidUpdateContentsWithInsertedItems:(NSIndexSet *)insertedItems
                                             removedItems:(NSIndexSet *)removedItems
                                             updatedItems:(NSIndexSet *)updatedItems;
- (void)listCoordinatorDidFailRemovingListAtURL:(NSURL *)URL withError:(NSError *)error;
- (void)listCoordinatorDidFailCreatingListAtURL:(NSURL *)URL withError:(NSError *)error;

@end

@interface MADFileLocationManager : NSObject

@property (nonatomic, weak) id<MADFileLocationManagerDelegate> delegate;
@property (nonatomic, strong, readonly) NSMetadataQuery *metadataQuery;
@property (nonatomic, strong, readonly) NSMutableDictionary *results;

- (instancetype)initWithPathExtension:(NSString *)pathExtension;
- (BOOL)startQuery;
- (void)stopQuery;
- (NSArray *)calculatedUrls;

@end

#endif
