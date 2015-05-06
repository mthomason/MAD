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
extern NSString * const MADNotificationCloudActivityStarted;
extern NSString * const MADNotificationCloudActivityCompleted;
extern NSString * const MADKeyMetadataShort;

@protocol MADFileLocationManagerDelegate <NSObject>

- (void)fileCoordinatorDidUpdateContentsWithInsertedItems:(NSIndexSet *)insertedItems
                                             removedItems:(NSIndexSet *)removedItems
                                             updatedItems:(NSIndexSet *)updatedItems;
- (void)fileCoordinatorDidFailRemovingFileAtURL:(NSURL *)URL withError:(NSError *)error;
- (void)fileCoordinatorDidFailCreatingFileAtURL:(NSURL *)URL withError:(NSError *)error;

@end

@interface MADMetadataQueryManager : NSObject

@property (nonatomic, weak) id<MADFileLocationManagerDelegate> delegate;
@property (nonatomic, strong, readonly) NSMetadataQuery *metadataQuery;
@property (nonatomic, strong, readonly) NSMutableDictionary *results;
@property (nonatomic, strong, readonly) NSArray *metadata;

- (instancetype)initWithPathExtension:(NSString *)pathExtension;
- (BOOL)startQuery;
- (void)stopQuery;
+ (NSString *)keyResults;

@end

#endif
