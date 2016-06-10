//
//  MTQuery.h
//  MAD
//
//  Created by Michael Thomason on 3/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQuery_h
#define Reports_MTQuery_h

#import <Foundation/NSObject.h>
#import "MADQueryType.h"
#import <MADFoundation/MADDataType.h>

#pragma mark Types of specific paramamters accepted for each query

typedef NSDictionary MADQueryDefinition;

@protocol MADDataProtocol;

extern NSString * const MTQueryKeyType;
extern NSString * const MTQueryKeyObject;

extern NSString * const MTQueryKeyPredicateColumn;
extern NSString * const MTQueryKeyPredicateValue;
extern NSString * const MADIdentifierROWID;

@class NSManagedObjectContext;
@class NSMutableArray;
@class NSMutableDictionary;

@class MTDatabase;
@class MTDataTable;

@class RptqQuery;

@interface MTQuery : NSObject

    @property (nonatomic, weak) id <MADDataProtocol> dataDelegate;

    @property (nonatomic, weak) MTDataTable *dataTable;
    @property (nonatomic, strong, readwrite) MTDatabase *database;

    @property (nonatomic, strong) id queryObject;
    @property (nonatomic, strong) NSMutableDictionary *fields;
    @property (nonatomic, strong) NSMutableArray *fieldKeys;
    @property (nonatomic, strong) NSMutableArray *binaryBindings;   // Used by database to bind
                                                                    //   NSData to insert statements
    @property (nonatomic, strong) NSDictionary *columns;            //MADDataColumns by key

    @property (nonatomic, assign, readonly) MADQueryType type;

    - (instancetype)initWithQueryType:(MADQueryType)type object:(id)object;

    - (NSString *)getSqlWithError:(NSError * __autoreleasing *)error;

    - (BOOL)performQueryWithError:(NSError * __autoreleasing *)error;

@end

@interface MTQuery (Private)    //Intended for use by MTQuery subclasses only

    - (instancetype)initWithObject:(id)object;

    - (NSString *)whereClauseWithRowIds:(NSArray *)rowids;
    - (NSString *)whereClauseWithParameters:(NSArray *)whereClause;             //For "cache" sqltie3
    - (NSString *)orderByClauseWithSortDescriptors:(NSArray *)sortDescriptors;  //For "cache" sqltie3
    - (MADDataType)columnTypeForColumnHanle:(NSString *)columnHandle;            //For "cache" sqltie3

    - (NSString *)fieldKeyForIndex:(NSUInteger)index;

    @property (nonatomic, readonly) BOOL returnsResults;
    @property (nonatomic, readonly) BOOL partOfTransactionSet;

    + (MADQueryDefinition *)newQueryDefinitionFull:(RptqQuery *)query;
    + (MADQueryDefinition *)newQueryDefinitionSelect:(NSDictionary *)queryDefinationSelect
                                           withLimit:(NSUInteger)limit andOffset:(NSUInteger)offset
                                           dropRowid:(BOOL)droprowid;
    + (MADQueryDefinition *)newQueryDefinitionSelect:(NSArray *)columnKeys
                                           tableName:(NSString *)tableName
                                     sortDescriptors:(NSArray *)sortDescriptors;
    + (MADQueryDefinition *)newQueryDefinitionSelect:(NSDictionary *)queryDefinationSelect
                                           withLimit:(NSUInteger)limit andOffset:(NSUInteger)offset;
    + (MADQueryDefinition *)newQueryDefinitionCacheDeleteAllFromTable:(NSString *)table;

@end

#endif
