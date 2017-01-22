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

@class NSOrderedSet <__covariant ObjectType>;

@class MADModelDocument;
@class MADModelDatabase;
@class MADModelQuery;
@class MADModelQueryTable;
@class MADModelQueryLink;
@class MADModelQueryField;

typedef NS_ENUM(short, MADModelType) {
    MADModelTypeDocument,
    MADModelTypeDatabase,
    MADModelTypeQueries,
};

@protocol MADObjectIDProtocol <NSObject>
    @property (nonatomic, readonly, weak)      NSManagedObjectContext *managedObjectContext;
    @property (nonatomic, readonly, copy)      NSManagedObjectID *objectID;
@end

@interface MADObjectID : NSObject
    <MADObjectIDProtocol>
@end

@interface MADModelDocument : MADObjectID
    <MADObjectIDProtocol>
    - (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
    @property (nonatomic, readonly, strong)     NSOrderedSet <MADModelDatabase *> *databaseIDs;
    @property (nonatomic, readonly, weak)       MADModelDatabase *firstDatabase;
    @property (nonatomic, readonly, weak)       MADModelQuery *firstQuery;
@end

@interface MADModelDatabase : MADObjectID
    <MADObjectIDProtocol>
    @property (nonatomic, readonly, strong)     NSOrderedSet <MADModelQuery *> *queryIDs;
    @property (nonatomic, readonly, weak)       MADModelQuery *firstQuery;
@end

@interface MADModelQuery : MADObjectID
    <MADObjectIDProtocol>
    @property (nonatomic, readonly, strong)     NSOrderedSet <MADModelQueryTable *> *tableIDs;
    @property (nonatomic, readonly, strong)     NSOrderedSet <MADModelQueryLink *> *linkIDs;
@end

@interface MADModelQueryTable : MADObjectID
    <MADObjectIDProtocol>
@end

@interface MADModelQueryLink : MADObjectID
    <MADObjectIDProtocol>
    @property (nonatomic, readonly, strong)      MADModelQueryField *leftFieldIDs;
    @property (nonatomic, readonly, strong)      MADModelQueryField *rightFieldIDs;
@end

@interface MADModelQueryField : MADObjectID
    <MADObjectIDProtocol>
    @property (nonatomic, readonly, strong)        MADModelQueryTable *table;
@end

#endif
