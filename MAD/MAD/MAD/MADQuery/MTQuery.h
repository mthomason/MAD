//
//  MTQuery.h
//  MAD
//
//  Created by Michael Thomason on 3/18/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQuery_h
#define Reports_MTQuery_h

#import <Foundation/NSObject.h>
#import <MADFoundation/MADDataType.h>

#import "MADQueryType.h"

#pragma mark Types of specific paramamters accepted for each query

@protocol MADDataProtocol;

extern NSString * const MTQueryKeyPredicateColumn;
extern NSString * const MTQueryKeyPredicateValue;
extern NSString * const MADIdentifierROWID;

@class NSMutableArray, NSMutableDictionary,
       MTDatabase, MADDataTable, RptqQuery;

@protocol MADQueryDataBindingProtocol <NSObject>
    @property (nonatomic, strong) NSMutableArray *binaryBindings;
@end

@protocol MADQueryFieldKeysProtocol <NSObject>
    @property (nonatomic, strong) NSMutableArray *fieldKeys;
@end

@interface MTQuery : NSObject

    @property (nonatomic, weak) id <MADDataProtocol> dataDelegate;

    @property (nonatomic, weak) MADDataTable *dataTable;
    @property (nonatomic, strong, readwrite) MTDatabase *database;

    @property (nonatomic, strong) NSMutableDictionary *fields;
    @property (nonatomic, strong) NSDictionary *columns;            //MADDataColumns by key

    @property (nonatomic, assign, readonly) MADQueryType type;

    - (NSString *)getSql:(NSError * __autoreleasing *)error;
    - (NSString *)getSql:(MTDatabase *)database error:(NSError * __autoreleasing *)error;

    - (BOOL)performQueryWithError:(NSError * __autoreleasing *)error;

    - (void)update;

@end

@interface MTQuery (Private)    //Intended for use by MTQuery subclasses only

    - (instancetype)initWithObject:(id)object;

    - (NSString *)fieldKeyForIndex:(NSUInteger)index;

    @property (nonatomic, readonly) BOOL returnsResults;
    @property (nonatomic, readonly) BOOL partOfTransactionSet;

@end

@interface MTQuery (MADQueryFieldKeysProtocol)    //Intended for use by MTQuery subclasses only

    - (instancetype)initWithObject:(id)object;

    - (NSString *)fieldKeyForIndex:(NSUInteger)index;

    @property (nonatomic, readonly) BOOL returnsResults;
    @property (nonatomic, readonly) BOOL partOfTransactionSet;

@end

#endif
