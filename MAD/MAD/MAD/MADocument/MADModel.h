//
//  MADModel.h
//  MAD
//
//  Created by Michael on 1/22/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADModel_h
#define Reports_MADModel_h

#import <Foundation/NSObject.h>

@class NSManagedObjectID;
@class NSManagedObjectContext;

extern NSString * const MADNotificationQueryTableInsert;
extern NSString * const MADNotificationQueryTableDelete;

extern NSString * const MADNotificationQueryLinkInsert;
extern NSString * const MADNotificationQueryLinkDelete;

extern NSString * const MADKeyQuery;

extern NSString * const MADKeyQueryLink;
extern NSString * const MADKeyQueryLinkLeftField;
extern NSString * const MADKeyQueryLinkRightField;
extern NSString * const MADKeyQueryLinkLeftTable;
extern NSString * const MADKeyQueryLinkRightTable;
extern NSString * const MADKeyQueryTable;
extern NSString * const MADKeyQueryField;
extern NSString * const MADKeySchemaFieldName;
extern NSString * const MADKeySchemaTableName;
extern NSString * const MADKeySchemaTable;
extern NSString * const MADKeySchemaField;

extern NSString * const MADKeyQueryLinkID;
extern NSString * const MADKeyQueryLinkLeftFieldID;
extern NSString * const MADKeyQueryLinkRightFieldID;
extern NSString * const MADKeyQueryLinkLeftTableID;
extern NSString * const MADKeyQueryLinkRightTableID;

extern NSString * const MADKeyQueryTableID;
extern NSString * const MADKeyQueryFieldID;
extern NSString * const MADKeySchemaTableID;
extern NSString * const MADKeySchemaFieldID;

typedef NS_ENUM(short, MADModelType) {
    MADModelTypeDocument,
    MADModelTypeDatabase,
    MADModelTypeQueries,
};

@protocol MADModelIDProtocol <NSObject>
    @property (nonatomic, readonly, copy)       NSManagedObjectID *objectID;
    @property (nonatomic, readonly, assign)     int64_t identifier;
@end

@protocol MADModelDataProtocol <NSObject>
    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                          identifier:(int64_t)identifier
                managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
    @property (nonatomic, readonly, weak)      NSManagedObjectContext *managedObjectContext;
    - (void)update;
@end

@interface MADModel : NSObject
<MADModelIDProtocol> {
  @protected
    int64_t _uid;
    NSManagedObjectID *_objectID;
}

    + (instancetype)newModelDocument:(NSManagedObjectContext *)managedObjectContext;
    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                          identifier:(int64_t)identifier NS_DESIGNATED_INITIALIZER;
@end

#endif
