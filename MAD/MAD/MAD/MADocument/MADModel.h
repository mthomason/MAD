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

@class MADModelDocument;
@class MADModelDatabase;
@class MADModelTable;
@class MADModelField;
@class MADModelQuery;
@class MADModelQueryTable;
@class MADModelQueryLink;
@class MADModelQueryField;

typedef NS_ENUM(short, MADModelType) {
    MADModelTypeDocument,
    MADModelTypeDatabase,
    MADModelTypeQueries,
};

@protocol MADModelIDProtocol <NSObject>
    @property (nonatomic, readonly, copy)      NSManagedObjectID *objectID;
@end

@protocol MADModelDataProtocol <NSObject>
    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
    @property (nonatomic, readonly, weak)      NSManagedObjectContext *managedObjectContext;
    - (void)update;
@end

@interface MADObjectID : NSObject
    <MADModelIDProtocol>
@end

@interface MADModelDocument : MADObjectID
    <MADModelDataProtocol>
    - (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
    @property (nonatomic, readonly, strong)     NSOrderedSet <MADModelDatabase *> *databases;
    @property (nonatomic, readonly, weak)       MADModelDatabase *firstDatabase;
    @property (nonatomic, readonly, weak)       MADModelQuery *firstQuery;
@end

@interface MADModelDatabase : MADObjectID
    <MADModelDataProtocol>
    @property (nonatomic, readonly, strong)     NSOrderedSet <MADModelQuery *> *queries;
    @property (nonatomic, readonly, strong)     NSOrderedSet <MADModelTable *> *tables;
    @property (nonatomic, readonly, weak)       MADModelQuery *firstQuery;
@end

@interface MADModelTable : MADObjectID
    @property (nonatomic, readonly, strong)     NSString *name;
    @property (nonatomic, readonly, strong)     NSOrderedSet <MADModelField *> *fields;
@end

@interface MADModelField : MADObjectID
@end

@interface MADModelQuery : MADObjectID
    <MADModelDataProtocol>
    @property (nonatomic, readonly, strong)     NSOrderedSet <MADModelQueryTable *> *tables;
    @property (nonatomic, readonly, strong)     NSOrderedSet <MADModelQueryLink *> *links;
@end

@interface MADModelQueryTable : MADObjectID
    @property (nonatomic, readonly, strong)     NSMapTable <NSManagedObjectID *, MADModelQueryField *> *fields;
@end

@interface MADModelQueryField : MADObjectID

@end

@interface MADModelQueryLink : MADObjectID
    @property (nonatomic, readonly, strong)      MADModelQueryField *leftField;
    @property (nonatomic, readonly, strong)      MADModelQueryField *rightField;
@end

#endif
