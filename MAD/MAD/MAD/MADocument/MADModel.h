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
@class NSMapTable <KeyType, ObjectType>;
@class NSOrderedSet <__covariant ObjectType>;
@class NSMutableDictionary <KeyType, ObjectType>;
@class MADModelDocument;
@class MADModelDatabase;
@class MADModelTable;
@class MADModelField;
@class MADModelQuery;
@class MADModelQueryTable;
@class MADModelQueryLink;
@class MADModelQueryField;

extern NSString * const MADNotificationQueryTableInsert;
extern NSString * const MADNotificationQueryTableDelete;

extern NSString * const MADNotificationQueryLinkInsert;
extern NSString * const MADNotificationQueryLinkDelete;

extern NSString * const MADKeyQuery;
//extern NSString * const MADKeyQueryLink;


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

@interface MADTableFieldReference : NSObject

- (instancetype)initWithTableID:(NSManagedObjectID *)tableID
                     andFieldID:(NSManagedObjectID *)fieldID NS_DESIGNATED_INITIALIZER;

    @property (readonly, nonatomic, copy) NSManagedObjectID *tableID;
    @property (readonly, nonatomic, copy) NSManagedObjectID *fieldID;

@end

@interface MADTableFieldIdentifier : NSObject

- (instancetype)initWithTableID:(int64_t)tableID
                     andFieldID:(int64_t)fieldID NS_DESIGNATED_INITIALIZER;

    @property (readonly, nonatomic, assign) int64_t tableID;
    @property (readonly, nonatomic, assign) int64_t fieldID;

@end

@interface MADObjectID : NSObject
    <MADModelIDProtocol>
    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID identifier:(int64_t)identifier;
@end

@interface MADModelTable : MADObjectID
    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                          identifier:(int64_t)identifier
                                name:(NSString *)name;
    @property (nonatomic, readonly, strong)     NSString *name;
    @property (nonatomic, readonly, strong)     NSOrderedSet <MADModelField *> *fields;
    - (void)addFieldWithID:(NSManagedObjectID *)objectID
                identifier:(int64_t)identifier
                      name:(NSString *)name
      managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
@end

@interface MADModelField : MADObjectID
@end

@interface MADModelQuery : MADObjectID
    <MADModelDataProtocol>
    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                          identifier:(int64_t)identifier
                            database:(MADModelDatabase *)database;
    @property (nonatomic, readonly, strong) NSOrderedSet <NSManagedObjectID *> *queryTableIDs;
    @property (nonatomic, readonly, strong) NSOrderedSet <NSManagedObjectID *> *queryLinkIDs;
    @property (nonatomic, readonly, strong) NSMutableDictionary <NSManagedObjectID *, MADModelQueryTable *> *tables;
    @property (nonatomic, readonly, strong) NSMutableDictionary <NSManagedObjectID *, MADModelTable *> *tableSchemas;
    @property (nonatomic, readonly, strong) NSMutableDictionary <NSManagedObjectID *, MADModelQueryLink *> *links;
    - (NSSet <NSManagedObjectID *> *)tablesInLinks;
    - (NSSet <NSManagedObjectID *> *)orphanedQueryTables;
    - (void)deleteQueryLinkID:(NSManagedObjectID *)queryLink;
    - (void)deleteQueryTableID:(NSManagedObjectID *)queryTable;
    - (void)insertQueryTableID:(NSManagedObjectID *)queryTableID;
    - (void)insertQueryLinkID:(NSManagedObjectID *)queryLinkID;
    - (void)addFieldWithID:(NSManagedObjectID *)objectID
                identifier:(int64_t)identifier
                      name:(NSString *)name
      managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end

@interface MADModelQueryTable : MADObjectID
    @property (nonatomic, readonly, strong)     NSMutableDictionary <NSManagedObjectID *, MADModelQueryField *> *fields;
@end

@interface MADModelQueryField : MADObjectID

@end

@interface MADModelQueryLink : MADObjectID
    @property (nonatomic, readonly, strong)      MADTableFieldReference *leftFieldReference;
    @property (nonatomic, readonly, strong)      MADTableFieldReference *rightFieldReference;
@end

#endif
