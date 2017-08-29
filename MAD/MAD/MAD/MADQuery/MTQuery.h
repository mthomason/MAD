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

@interface MTQuery : NSObject

    @property (nonatomic, weak) id <MADDataProtocol> dataDelegate;

    @property (nonatomic, weak) MADDataTable *dataTable;
    @property (nonatomic, strong, readwrite) MTDatabase *database;

    @property (nonatomic, strong) id queryObject;
    @property (nonatomic, strong) NSMutableDictionary *fields;
    @property (nonatomic, strong) NSMutableArray *fieldKeys;
    @property (nonatomic, strong) NSMutableArray *binaryBindings;   // Used by database to bind
                                                                    //   NSData to insert statements
    @property (nonatomic, strong) NSDictionary *columns;            //MADDataColumns by key

    @property (nonatomic, assign, readonly) MADQueryType type;

    - (NSString *)getSqlWithError:(NSError * __autoreleasing *)error;

    - (BOOL)performQueryWithError:(NSError * __autoreleasing *)error;

    - (void)update;

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

    + (NSDictionary *)newQueryDefinitionSelect:(NSArray *)columnKeys
                                     tableName:(NSString *)tableName
                               sortDescriptors:(NSArray *)sortDescriptors;
    + (NSDictionary *)newQueryDefinitionSelect:(NSDictionary *)queryDefinationSelect
                                     withLimit:(NSUInteger)limit
                                     andOffset:(NSUInteger)offset;
@end

#endif
