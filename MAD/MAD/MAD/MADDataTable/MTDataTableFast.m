//
//  MTDataTableFast.m
//  MAD
//
//  Created by Michael Thomason on 4/19/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTDataTableFast.h"

#import <Foundation/NSString.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSException.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSKeyValueCoding.h>
#import <Foundation/NSNull.h>
#import <dispatch/dispatch.h>

#import <MADFoundation/MTCacheProtocol.h>
#import <MADFoundation/MADDataProtocol.h>

#import <MADQueryCacheSelectLimitOffsetParamaters.h>

#import <MADDataStructures/MADIndex.h>
#import <MADFoundation/MADDataColumn.h>

#import "MADConstants.h"

#import "MTDataTableFastObjectEnumerator.h"
#import "MTDatabaseSqlite3.h"
#import "MTDatabaseConnectionSqlite3.h"

#import "MTQuery.h"
#import "MTQueryCacheAddRow.h"
#import "MTQueryCacheIndexDrop.h"
#import "MTQueryCacheAddColumn.h"
#import "MTQueryCacheVacuum.h"
#import "MTQueryCacheDropTable.h"
#import "MTQueryCacheDeleteAllFromTable.h"
#import "MTQuerySelectItemsForGroup.h"
#import "MTQueryCacheIndexCreate.h"
#import "MTQueryCacheSelectLimitOffset.h"

#import "MADQueryCacheAddRowParameters.h"
#import "MADQueryCacheIndexDropParameters.h"
#import "MADQuerySelectParameters.h"

#import "MADQueryCacheIndexCreateParameters.h"

#import <MADFileManager/MADFileUtilities.h>
#import <MADFileManager/NSURL+CommonURLs.h>

#import <MADSqlite3/sqlite3.h>
#import <stdio.h>

#import "madlib.h"

/*
static inline MADDataType mad_sqlite3_datatype_for_sqlite3_type(int sqlite3type);
static inline MADDataType mad_sqlite3_datatype_for_sqlite3_type(int sqlite3type) {
    switch (sqlite3type) {
        case SQLITE_INTEGER:
            return MADDataTypeInteger;
            break;
        case SQLITE_TEXT:
            return MADDataTypeString;
            break;
        case SQLITE_BLOB:
            return MADDataTypeBlob;
            break;
        case SQLITE_NULL:
            return MADDataTypeNull;
            break;
        case SQLITE_FLOAT:
            return MADDataTypeFloat;
            break;
        default:
            return MADDataTypeString;
            break;
    }
}*/

static const char * MADQueueBulkAdd = "com.everydayapps.mad.cache.fast";

@interface MTDataTableFast ()

    @property (nonatomic, strong) MTDatabaseCache *databaseForInserts;
    @property (nonatomic, strong, readwrite) MTDatabaseCache *databaseForSelects;

    @property (nonatomic, strong) NSURL *urlFastCache;

    @property (nonatomic, strong) NSMutableArray *groupKeys;    //Could used NSIndexSet
    @property (nonatomic, strong) NSArray *groupTableNames;

    @property (nonatomic, assign) bool bulkInsertLoop;
    @property (nonatomic, assign) bool sortDescriptorsSet;

    @property (nonatomic, strong) MADIndex *lastDataForCacheId;

    @property (nonatomic, strong) MTQueryCacheAddRow *bulkInsertQuery;

    @property (nonatomic, strong) dispatch_queue_t queueBulkAdd;

@end

@implementation MTDataTableFast

- (void)dealloc { }

- (instancetype)initWithId:(NSUInteger)objectId {
    return [self initWithId:objectId fromCache:YES];
}

- (instancetype)initWithId:(NSUInteger)objectId fromCache:(BOOL)fromCache {
    if (self = [super initWithId:objectId fromCache:fromCache]) {
    
        dispatch_queue_t queue = dispatch_queue_create(MADQueueBulkAdd, DISPATCH_QUEUE_SERIAL);
        self.queueBulkAdd = queue;
    
        self.bulkInsertLoop = false;
        self.tag = objectId;
        self.sortDescriptorsSet = false;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {

        dispatch_queue_t queue = dispatch_queue_create(MADQueueBulkAdd, DISPATCH_QUEUE_SERIAL);
        self.queueBulkAdd = queue;
        
        NSString *absoluteString = [decoder decodeObjectForKey: [MTDataTableFast keyUrlFastCache]];
        NSURL *url = [NSURL URLWithString:absoluteString];
        self.urlFastCache = url;
        
        NSNumber *tag = [decoder decodeObjectForKey: [MTDataTableFast keyTag]];
        self.tag = tag.unsignedIntegerValue;
        
        _bulkInsertLoop = [decoder decodeBoolForKey: [MTDataTableFast keyBulkInsertLoop]] ? true : false;
        _sortDescriptorsSet = [decoder decodeBoolForKey: [MTDataTableFast keySortDescriptorsSet]] ? true : false;
        
        NSArray *groupKeysArray = [decoder decodeObjectForKey: [MTDataTableFast keyGroupKeys]];
        NSMutableArray *groupKeys = [[NSMutableArray alloc] initWithArray: groupKeysArray];
        self.groupKeys = groupKeys;
        
        NSArray *groupTableNames = [decoder decodeObjectForKey:[MTDataTableFast keyGroupTableNames]];
        self.groupTableNames = groupTableNames;
        
        [self reopenDbConnection];
    }
    return self;
}

- (MADDataTablePlist *)copyPlist {
    
    NSDictionary *superPlist = [super copyPlist];
    NSMutableDictionary *plist = [[NSMutableDictionary alloc] initWithDictionary:superPlist];
    
    NSURL *urlFastCache = self.urlFastCache;
    NSString *urlFastCacheAbsolute = [[NSString alloc] initWithString: urlFastCache.absoluteString];
    NSString *keyUrlFastCache = [MTDataTableFast keyUrlFastCache];
    plist[keyUrlFastCache] = urlFastCacheAbsolute;
    
    NSNumber *tag = [[NSNumber alloc] initWithUnsignedInteger: self.tag];
    NSString *keyTag = [MTDataTableFast keyTag];
    plist[keyTag] = tag;
    
    NSNumber *bulkInsert = [[NSNumber alloc] initWithBool:self.bulkInsertLoop ? YES : NO];
    NSString *keyBulkInsertLoop = [MTDataTableFast keyBulkInsertLoop];
    plist[keyBulkInsertLoop] = bulkInsert;
    
    if (self.groupTableNames != nil) {
        NSString *keyGroupTableNames = [MTDataTableFast keyGroupTableNames];
        plist[keyGroupTableNames] = self.groupTableNames;
    }
    
    if (self.groupKeys != nil) {
        NSString *keyGroupKeys = [MTDataTableFast keyGroupKeys];
        plist[keyGroupKeys] = self.groupKeys;
    }
    
    NSNumber *sortSet = [[NSNumber alloc] initWithBool:self.sortDescriptorsSet ? YES : NO];
    NSString *keySortDescriptorsSet = [MTDataTableFast keySortDescriptorsSet];
    plist[keySortDescriptorsSet] = sortSet;
    
    return plist;
}

- (void)loadWithPlist:(MADDataTablePlist *)plist {
    [super loadWithPlist:plist];
    
    dispatch_queue_t queue = dispatch_queue_create(MADQueueBulkAdd, DISPATCH_QUEUE_SERIAL);
    self.queueBulkAdd = queue;

    id keyUrlFastCache = [MTDataTableFast keyUrlFastCache];
    NSString * __weak absoluteString = plist[keyUrlFastCache];
    NSURL *url = [[NSURL alloc] initWithString:absoluteString];
    self.urlFastCache = url;
    
    id keyTag = [MTDataTableFast keyTag];
    NSNumber *tagWrapper = plist[keyTag];
    self.tag = tagWrapper.unsignedIntegerValue;
    
    id keyBuildInsertLoop = [MTDataTableFast keyBulkInsertLoop];
    NSNumber * __weak bulkInsertLoopWrapper = plist[keyBuildInsertLoop];
    self.bulkInsertLoop = bulkInsertLoopWrapper.boolValue ? true : false;
    
    id keyGroupKeys = [MTDataTableFast keyGroupKeys];
    NSArray *groupKeysArray = plist[keyGroupKeys];
    NSMutableArray *groupKeys = [[NSMutableArray alloc] initWithArray: groupKeysArray];
    self.groupKeys = groupKeys;
    
    id keyGroupTableNames = [MTDataTableFast keyGroupTableNames];
    NSArray *groupTableNames = plist[keyGroupTableNames];
    NSArray *tableNames = [[NSArray alloc] initWithArray:tableNames];
    self.groupTableNames = groupTableNames;
    
    [self reopenDbConnection];
    
}

+ (NSString *)keyUrlFastCache {
    SEL sel = @selector(urlFastCache);
    return NSStringFromSelector(sel);
}

+ (NSString *)keyTag {
    SEL sel = @selector(tag);
    return NSStringFromSelector(sel);
}

+ (NSString *)keyBulkInsertLoop {
    SEL sel = @selector(bulkInsertLoop);
    return NSStringFromSelector(sel);
}

+ (NSString *)keySortDescriptorsSet {
    return NSStringFromSelector(@selector(sortDescriptorsSet));
}

+ (NSString *)keyGroupKeys {
    return NSStringFromSelector(@selector(groupKeys));
}

+ (NSString *)keyGroupTableNames {
    return NSStringFromSelector(@selector(groupTableNames));
}

+ (NSString *)keyColumns {
    SEL selColumns = @selector(columns);
    return NSStringFromSelector(selColumns);
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];

    NSString *absStr = _urlFastCache.absoluteString;
    [encoder encodeObject:  absStr                              forKey: [MTDataTableFast keyUrlFastCache]];
    NSNumber *objid = [[NSNumber alloc] initWithUnsignedInteger: self.tag];
    [encoder encodeObject: objid                                forKey: [MTDataTableFast keyTag]];
    [encoder encodeBool: _bulkInsertLoop ? YES : NO             forKey: [MTDataTableFast keyBulkInsertLoop]];
    [encoder encodeBool: _sortDescriptorsSet ? YES : NO         forKey: [MTDataTableFast keySortDescriptorsSet]];

}

- (NSString *)filenameCacheMadDB {
    NSString *tag = [NSString stringWithFormat:@"%lu", (unsigned long)self.tag];
    return [tag stringByAppendingPathExtension:@"maddb"];
}

- (NSURL *)urlFastCache {
    NSString *filename = [self filenameCacheMadDB];
    NSURL *cacheDirectory = self.cacheDelegate == nil ?
                                [NSURL newURLForLocalCacheDirectoryForGroupIdentifier:MADIdentifierGroup] :
                                [self.cacheDelegate cachedFilesDirectory];
    return [cacheDirectory URLByAppendingPathComponent:filename isDirectory:NO];
}

- (instancetype)initWithNumberOfColumns:(NSUInteger)numberOfColumns {
    NSAssert(false, @"Not implemented");
    return nil;
}

- (void)setCacheDelegate:(id<MTCacheProtocol>)cacheDelegate {
    _cacheDelegate = cacheDelegate;
    [self reopenDbConnection];
}

- (void)reopenDbConnection {

    NSURL *urlFastCache = self.urlFastCache;

    MTDatabaseCache *database; MTDatabaseConnection *connection;
    
    database = [[MTDatabaseSqlite3 alloc] init];
    connection = [[MTDatabaseConnectionSqlite3 alloc] initWithUrl:urlFastCache];
    database.databaseConnection = connection;
    
    [(MTDatabaseSqlite3 *)database openDatabaseWithFlags: SQLITE_OPEN_READWRITE |
                                                          SQLITE_OPEN_CREATE |
                                                          SQLITE_OPEN_FULLMUTEX];
    self.databaseForInserts = database;
    
    connection = [[MTDatabaseConnectionSqlite3 alloc] initWithUrl:urlFastCache];
    database = [MTDatabaseCache newDatabaseWithConnection:connection];
    self.databaseForSelects = database;
}

- (NSString *)tableName {
    char buf[12];
    buf[0] = 't';
    uitoa(self.tag, (buf+1));
    char *ptr = buf;
    NSString *tableName = [[NSString alloc] initWithCString:ptr encoding:NSUTF8StringEncoding];
    return tableName;
}

- (void)addColumn:(MADDataColumn *)column {

    BOOL createTable = self.columnKeys.count == 0;
    char buf[12];
    buf[0] = 'c';
    uitoa(column.identifier.hash, (buf+1));
    char *ptr = buf;

    NSString *columnName = [[NSString alloc] initWithCString:ptr encoding:NSUTF8StringEncoding];
    
    self.columns[columnName] = column;
    [self.columnKeys addObject:columnName];

    NSString *tableName = [self tableName];
    [self addColumn:column toTable:tableName columnName:columnName createTable:createTable
             unique:NO];
}

- (void)initializeGroupKeys {
    NSArray * __unsafe_unretained sortDescriptors = self.sortDescriptors;
    NSArray * __weak columnKeys = self.columnKeys;

    NSUInteger index = NSNotFound;
    NSMutableArray *groupKeys;
    groupKeys = [[NSMutableArray alloc] initWithCapacity: sortDescriptors.count];
    NSSortDescriptor *sortDescriptor;
    NSNumber *columnIndex;
    NSString *key;
    for (sortDescriptor in sortDescriptors) {
        @autoreleasepool {
            key = sortDescriptor.key;
            if ((index = [columnKeys indexOfObject: key]) != NSNotFound) {
                columnIndex = [[NSNumber alloc] initWithUnsignedInteger: index];
                [groupKeys addObject:columnIndex];
            }
        }
    }

    self.groupKeys = groupKeys;
    groupKeys = nil;
}

- (NSString *)idColumnKeyForGroupLocation:(NSUInteger)groupLevel {
    NSString *result = nil;
    if (self.groupKeys.count > groupLevel) {
        NSNumber *level = self.groupKeys[groupLevel];
        result = self.columnKeys[level.unsignedIntegerValue];
        NSString *rval = [NSString stringWithString:result];
        return rval;
    } else {
        return nil;
    }
}

- (MADDataColumn *)idDataColumnForGroupLevel:(NSUInteger)groupLevel {
    NSString *key = [self idColumnKeyForGroupLocation:groupLevel];
    return self.columns[key];
}

- (void)addColumn:(MADDataColumn *)column toTable:(NSString *)table
       columnName:(NSString *)columnName createTable:(BOOL)create unique:(BOOL)unique {
    
    bool success = false;
    NSError * __autoreleasing errorQuery = NULL;

    NSString *columnAffinity = [_databaseForInserts newNativeTypeForDataType: column.type];

    MTQueryCache *query = [[MTQueryCacheAddColumn alloc] initWithTableName: table
                                                                columnName: columnName
                                                                    column: column
                                                               createTable: create ? true : false
                                                          uniqueColumnHack: unique ? true : false
                                                            columnAffinity: columnAffinity];
    query.database = _databaseForInserts;
    success = [_databaseForInserts executeQuery:query withError:&errorQuery];
    NSAssert(success, @"%s at %s", sqlite3_errmsg(_databaseForInserts->_database), __PRETTY_FUNCTION__);

}

- (void)addRow:(NSArray *)row {
    self.rowCounter++;
    if (self.groupKeys == nil) {
        [self.groupKeys removeAllObjects];
        [self initializeGroupKeys];
    }
    
    
    if (self.bulkInsertLoop) {
        
        NSArray *rowData = [NSArray arrayWithArray: row];
        self.bulkInsertQuery.rowData = rowData;
        
        NSString *sql = [_bulkInsertQuery getSqlWithError:nil];
        
        id binaryBindings   = [[NSArray alloc] initWithArray: _bulkInsertQuery.binaryBindings];
        id fieldKeys        = [[NSArray alloc] initWithArray: _bulkInsertQuery.fieldKeys];
        
        MTDatabaseSqlite3 *dbForInserts = ((MTDatabaseSqlite3 *)self.databaseForInserts);
        
        [MTDatabaseSqlite3 executeQueryWithSql: sql
                                      database: (struct sqlite3 *)(dbForInserts->_database)
                           queryBinaryBindings: binaryBindings
                                queryFieldKeys: fieldKeys
                     queryPartOfTransactionSet: YES];
        
    } else {


        NSNumber *keyKeys = [[NSNumber alloc] initWithShort: MTQueryCacheAddRowColumnKeys];
        NSNumber *keyColumns = [[NSNumber alloc] initWithShort: MTQueryCacheAddRowColumns];
        NSNumber *keyData = [[NSNumber alloc] initWithShort: MTQueryCacheAddRowData];
        NSNumber *keyTableName = [[NSNumber alloc] initWithShort: MTQueryCacheAddRowTableName];
        NSString *tableName = [self tableName];
        NSDictionary *columns = self.columns;
        NSArray *columKeys = self.columnKeys;
        NSDictionary *parameters = [[NSDictionary alloc] initWithObjectsAndKeys:columKeys, keyKeys,
                                                                            columns, keyColumns,
                                                                            row, keyData,
                                                                            tableName, keyTableName,
                                                                            nil];

        MTQuery *query = self.bulkInsertLoop ? self.bulkInsertQuery :
                                               [[MTQueryCacheAddRow alloc] initWithObject:parameters];
        
        query.database = _databaseForInserts;
        bool success;
        NSError * __autoreleasing errorQuery = NULL;
        success = [_databaseForInserts executeQuery:query withError:&errorQuery];

    }
    
    
}

// FIXME: Maybe wrap in autorelease block.
- (void)addRowWithDataForFieldKeys:(NSDictionary *)row {

    @autoreleasepool {
        
        NSMutableArray *rowData = [[NSMutableArray alloc] init];
        for (id columnDefKey in self.columnKeys) {
        
            MADDataColumn *columnDef = self.columns[columnDefKey];
            id obj = row[columnDef.fieldName];
            if (obj == nil) obj = [NSNull null];
            [rowData addObject:obj];
            
        }
        [self addRow:rowData];
        
    }
    
}

- (void)sortUsingDescriptors:(NSArray *)sortDescriptors {

    [self.groupKeys removeAllObjects];
    if (self.columnKeys.count > 0 && self.columns.count > 0) {
        
        if (sortDescriptors.count > 0 /*&& self.sortDescriptorsSet == NO*/) {
            
            NSMutableArray <__kindof NSSortDescriptor *> *newSortDescriptors = [[NSMutableArray <__kindof NSSortDescriptor *> alloc] initWithCapacity:sortDescriptors.count];

            NSUInteger groupKeyCounter;
            for (NSSortDescriptor *sortDescriptor in sortDescriptors) {
                groupKeyCounter = 0;

                NSArray *columnKeys = self.columnKeys;
                for (NSString *columnKey in columnKeys) {
                    
                    @autoreleasepool {
                        MADDataColumn * __weak column = self.columns[columnKey];
                        if ([column.fieldName isEqualToString:sortDescriptor.key]) {
                        
                            SEL sortAlgo = MADDataTypeSelectorForSorting(column.type);
                            NSSortDescriptor *newSortDescriptor = [[NSSortDescriptor alloc] initWithKey: columnKey
                                                                                              ascending: sortDescriptor.ascending
                                                                                               selector: sortAlgo];
                            [newSortDescriptors addObject:newSortDescriptor];
                            
                            NSNumber *groupKey = [[NSNumber alloc] initWithUnsignedInteger: groupKeyCounter];
                            [self.groupKeys addObject:groupKey];
                            
                            break;
                        }
                    }
                    groupKeyCounter++;
                }
                if (newSortDescriptors.count == sortDescriptors.count) {
                    self.sortDescriptorsSet = true;
                    self.sortDescriptors = newSortDescriptors;
                }
            }
        }
    } else {
        NSMutableArray *sd = [[NSMutableArray alloc] initWithArray:sortDescriptors];
        self.sortDescriptors = sd;
    }
    
    // FIXME: reset cache after setting the sort descriptors    
}

- (void)removeAllObjects {

    [self reopenDbConnection];
    [self dropIndex];
    [self dropTable];
    [self vacuumCacheDb];
    
    self.lastDataForCacheId = nil;
    [self.columnKeys removeAllObjects];
    [self.columns removeAllObjects];
    self.rowCounter = 0;
    
}

- (NSArray *)sortDescriptorIndexGroupsForSortDescriptors:(NSArray *)sortDescriptors {

    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:sortDescriptors.count + 1];
    [results addObject:sortDescriptors];
    for (NSSortDescriptor *sortDescriptor in sortDescriptors) {
        NSArray *group = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
        [results addObject:group];
    }
    return results;
}

- (NSString *)cacheTableNameForGroupLevel:(NSInteger)groupLevel {
    return [NSString stringWithFormat:@"s%ld", (long)groupLevel];
}

- (NSString *)indexNameForGroupLevel:(NSUInteger)groupLevel andIndex:(NSUInteger)index {
    return [NSString stringWithFormat:@"i%ld%ld", (long)groupLevel, (long)index];
}

- (NSDictionary *)newIndexParametersForIndexName:(NSString *)indexName
                                       tableName:(NSString *)tableName
                              andSortDescriptors:(NSArray *)sortDescriptors {

    MADMapDataColumns *columns = [MADMapDataColumns dictionaryWithDictionary: self.columns];
    NSNumber *createIndexName = [[NSNumber alloc] initWithShort:MTQueryCacheIndexCreateIndexName];
    NSNumber *createTableName = [[NSNumber alloc] initWithShort:MTQueryCacheIndexCreateTableName];
    NSNumber *createSortDescriptors = [[NSNumber alloc] initWithShort:MTQueryCacheIndexCreateSortDescriptors];
    NSNumber *createColumns = [[NSNumber alloc] initWithShort:MTQueryCacheIndexCreateColumns];
    NSDictionary * parameters = [[NSDictionary alloc] initWithObjectsAndKeys:
                                            indexName, createIndexName,
                                            tableName, createTableName,
                                            sortDescriptors, createSortDescriptors,
                                            columns, createColumns, nil];
    return parameters;
}

- (void)createIndex {
    
    NSArray *sortDescriptors = [self.dataDelegate sortDescriptors];
    [self.sortDescriptors setArray:sortDescriptors];
    [self sortUsingDescriptors:self.sortDescriptors];
    
    NSUInteger sortDescCtr = self.sortDescriptors.count;
    NSArray *sortDescriptorGroups;
    sortDescriptorGroups = [self sortDescriptorIndexGroupsForSortDescriptors: self.sortDescriptors];
    
    NSUInteger groupCounter = 0;
    for (NSArray *sortDescriptorGroup in sortDescriptorGroups) {

        NSString *groupName = [self indexNameForGroupLevel:sortDescCtr andIndex:groupCounter];
        NSString *tableName = [self tableName];
        NSDictionary *parameters = [self newIndexParametersForIndexName: groupName
                                                              tableName: tableName
                                                     andSortDescriptors: sortDescriptorGroup];
  
        MTQuery *queryCreateIndex = [[MTQueryCacheIndexCreate alloc] initWithObject:parameters];
        bool success;
        NSError * __autoreleasing errorQuery = NULL;
        success = [self.databaseForInserts executeQuery:queryCreateIndex withError:&errorQuery];

        groupCounter++;
    }

    
}

- (void)dropIndex {
    NSUInteger sortDescCtr = self.sortDescriptors.count;
    NSUInteger groupCounter = 0;
    bool success;
    for (NSUInteger i = 0; i<sortDescCtr; i++) {
        NSString *groupName = [self indexNameForGroupLevel:sortDescCtr andIndex:groupCounter];
        NSDictionary *parameters = @{
                                     @(MTQueryCacheIndexDropIndexName) : groupName,
                                     };
        NSError * __autoreleasing errorQuery = NULL;
        MTQuery *query = [[MTQueryCacheIndexDrop alloc] initWithObject:parameters];
        success = [self.databaseForInserts executeQuery:query withError:&errorQuery];
        errorQuery = NULL;
    }
}

- (void)vacuumCacheDb {
    bool success;
    NSError * __autoreleasing errorQuery = NULL;
    MTQuery *queryVacuum = [[MTQueryCacheVacuum alloc] init];
    success = [self.databaseForInserts executeQuery:queryVacuum withError:&errorQuery];
}

- (void)dropTable {
    [self dropTableName:[self tableName]];
}

- (void)dropTableName:(NSString *)tableName {
    bool success;
    NSError * __autoreleasing errorQuery = NULL;
    MTQuery *queryDropTable = [[MTQueryCacheDropTable alloc] initWithObject:tableName];
    success = [self.databaseForInserts executeQuery:queryDropTable withError:&errorQuery];
}

- (void)deleteAll {
    bool success;
    NSError * __autoreleasing errorQuery = NULL;
    NSString *tableName = [self tableName];
    MTQuery *queryDeleteAllFromTable = [[MTQueryCacheDeleteAllFromTable alloc] initWithObject:tableName];
    success = [self.databaseForInserts executeQuery:queryDeleteAllFromTable withError:&errorQuery];
}

- (id)objectAtRow:(NSUInteger)row column:(NSUInteger)column {
    // FIXME: Query just this field.
    NSDictionary *objForRow = [self objectAtRow:row];
    NSString *key = self.columnKeys[0];
    MADDataColumn *columnMetaData = self.columns[key];
    NSString *fieldName = columnMetaData.fieldName;
    return objForRow[fieldName];
}

- (NSDictionary *)objectAtRow:(NSUInteger)row {
    NSArray *objectAtRow = [self objectAtRow:row limit:1];
    return objectAtRow.firstObject;
}

- (NSDictionary *)queryDefinationSelect {
    return [MTQuery newQueryDefinitionSelect:self.columnKeys tableName:[self tableName]
                             sortDescriptors:self.sortDescriptors];
}

- (NSDictionary *)queryDefinationSelectWithLimit:(NSUInteger)limit andOffset:(NSUInteger)offset {
    return [MTQuery newQueryDefinitionSelect:[self queryDefinationSelect] withLimit:limit andOffset:offset];
}

// FIXME: Return error handler... remove credentals
- (NSDictionary *)copyDataForCacheId:(NSNumber *)cacheId {
    
    if (self.lastDataForCacheId != nil) {
        if (cacheId.unsignedIntegerValue == self.lastDataForCacheId.index) {
            NSDictionary *result = [NSDictionary dictionaryWithDictionary:self.lastDataForCacheId.object];
            return result;
        }
    }
    
    NSDictionary * result = nil;
    
    NSNumber *keyRowId = [[NSNumber alloc] initWithShort: MADQuerySelectRowId];
    NSNumber *keyFieldKey = [[NSNumber alloc] initWithShort: MADQuerySelectFieldKeys];
    NSNumber *keyTableNmae = [[NSNumber alloc] initWithShort: MADQuerySelectTableName];
    NSNumber *keyFieldDef = [[NSNumber alloc] initWithShort: MADQuerySelectFieldDescriptors];
    NSDictionary *options = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    cacheId, keyRowId, self.columnKeys, keyFieldKey,
                                    [self tableName], keyTableNmae,
                                    self.columns, keyFieldDef , nil];
    
    MTQuery * query = [[MTQuery alloc] initWithQueryType: MADQueryTypeCacheSelectRowId
                                                  object: options];
    sqlite3_stmt *statement = NULL;
    NSError *error = nil;
    NSString *sql = [query getSqlWithError:&error];
    
    const char *sqlUTF8String = sql.UTF8String;
    char *queryString = sqlite3_mprintf((char *) sqlUTF8String);

    MTDatabaseCache *databaseForSelects = self.databaseForSelects;
    bool success = sqlite3_prepare_v2(databaseForSelects->_database, queryString, -1,
                                      &statement, NULL) == SQLITE_OK;
    
    if (success) {  //Expect success to == NO in normal working conditions.
        success = sqlite3_step(statement) == SQLITE_ROW;
        if (success) {
            result = [self newCurrentObject:statement];
            
            MADIndex * lastDataForCacheId = [[MADIndex alloc] initWithIndex:cacheId.unsignedIntegerValue
                                                                  andObject:result];
            self.lastDataForCacheId = lastDataForCacheId;
            
        } else {
            result = [[NSDictionary alloc] init];
        }
    }
    
    sqlite3_finalize(statement);
    sqlite3_free(queryString);

    return result;
}

- (NSArray *)whereClauseForGroupKeys:(NSArray *)groupKeys {
    [self initializeGroupKeys];
    NSMutableArray * whereClause = [[NSMutableArray alloc] initWithCapacity:groupKeys.count];
    NSUInteger groupLevel = 0;
    for (NSString *key in groupKeys) {
        @autoreleasepool {
            NSString *columnLevel = [self idColumnKeyForGroupLocation:groupLevel].copy;
            NSString *gk = key.copy;
            NSDictionary *whereStatement = @{MTQueryKeyPredicateColumn : columnLevel,
                                             MTQueryKeyPredicateValue : gk};
            [whereClause addObject:whereStatement];
            groupLevel++;
        }
    }
    return whereClause;
}

// FIXME: Return error handler... remove credentals
- (NSArray <__kindof NSDictionary *> *)objectsForGroupKeys:(NSArray *)groupKeys {
    
    [self initializeGroupKeys];

    NSArray *whereClause = [self whereClauseForGroupKeys:groupKeys];
    NSString *tableName = [self tableName];
    NSArray *sortDescriptors = self.sortDescriptors;
    MADMapDataColumns *columns = self.columns;
    NSArray *columnKeys = self.columnKeys;
    
    NSNumber *selectFieldKeys = [[NSNumber alloc] initWithShort: MADQuerySelectFieldKeys];
    NSNumber *selectTableName = [[NSNumber alloc] initWithShort: MADQuerySelectTableName];
    NSNumber *selectPredicates = [[NSNumber alloc] initWithShort: MADQuerySelectPredicates];
    NSNumber *selectSortDescriptors = [[NSNumber alloc] initWithShort: MADQuerySelectSortDescriptors];
    NSNumber *selectFieldDescriptors = [[NSNumber alloc] initWithShort: MADQuerySelectFieldDescriptors];

    id querySelect = [[NSDictionary alloc] initWithObjectsAndKeys:
                                                        columnKeys,         selectFieldKeys,
                                                        tableName,          selectTableName,
                                                        whereClause,        selectPredicates,
                                                        sortDescriptors,    selectSortDescriptors,
                                                        columns,            selectFieldDescriptors,
                                                        nil];
    
    MTQuery * query = [[MADQuerySelectItemsForGroup alloc] initWithObject:querySelect];
    sqlite3_stmt *statement = NULL;
    NSError *error = nil;
    NSString *sql = [query getSqlWithError:&error];
    
    const char *sqlc = sql.UTF8String;
    char *queryString = sqlite3_mprintf((char *) sqlc);
    
    MTDatabaseCache *databaseForSelects = self.databaseForSelects;
    
    BOOL success = sqlite3_prepare_v2(databaseForSelects->_database,
                                      queryString, -1, &statement, NULL) == SQLITE_OK;
    
    NSArray *queryBinaryBindings = query.binaryBindings;
    for (MTDatabaseDataBinding *dataBinding in queryBinaryBindings) {
        [MTDatabaseSqlite3 bindStatement: &statement withBindings: dataBinding];
    }

    NSMutableArray <__kindof NSDictionary *> *results = [[NSMutableArray alloc] init];
    if (success) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            @autoreleasepool {
                NSDictionary *result = [self newCurrentObject:statement];
                [results addObject:result];
            }
        }
    }
    NSAssert(success, @"%s at %s", sqlite3_errmsg(databaseForSelects->_database),
             __PRETTY_FUNCTION__);
    
    sqlite3_finalize(statement);
    sqlite3_free(queryString);
    return results;
}

// FIXME: Return error handler... remove credentals
- (NSArray *)objectAtRow:(NSUInteger)row limit:(NSUInteger)limit {
    
    NSDictionary *queryDefination = [self queryDefinationSelectWithLimit:limit andOffset:row];
    
    MTQuery *query = [[MTQueryCacheSelectLimitOffset alloc] initWithObject: queryDefination];

    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:limit];
    if (row != NSNotFound && limit > 0) {
        sqlite3_stmt *statement = NULL;
        NSError *error = nil;
        NSString *sql = [query getSqlWithError:&error];
        
        const char *sqlc = sql.UTF8String;
        char *queryString = sqlite3_mprintf((char *) sqlc);
        
        MTDatabaseCache *databaseForSelects = self.databaseForSelects;

        BOOL success = sqlite3_prepare_v2(databaseForSelects->_database,
                                          queryString, -1, &statement, NULL) == SQLITE_OK;
        
        NSAssert(success, @"%s", sqlite3_errmsg(databaseForSelects->_database));
        if (success) {
        
            while (sqlite3_step(statement) == SQLITE_ROW) {
                @autoreleasepool {
                    NSDictionary *currentObject = [self newCurrentObject:statement];
                    [results addObject:currentObject];
                }
            }
        }
        
        sqlite3_finalize(statement);
        sqlite3_free(queryString);
    }
    return results;
}

- (NSEnumerator *)columnsEnumerator {
    // FIXME: Implement this.
    return self.columns.keyEnumerator;
}

- (NSEnumerator *)objectEnumerator {

    if (self.columns.count <= 0) return nil;
    
    NSEnumerator *objectEnumerator = nil;
    NSDictionary *queryDefination = [self queryDefinationSelect];
    MTQuery *query = [[MTQueryCacheSelectLimitOffset alloc] initWithObject: queryDefination];
    NSURL *urlFastCache = self.urlFastCache;
    MTDatabaseConnection *databaseConnection = [MTDatabaseConnection newDatabaseConnectionForUrl: urlFastCache];
    objectEnumerator = [[MTDataTableFastObjectEnumerator alloc] initWithDatabaseConnection: databaseConnection
                                                                                   columns: self.columns
                                                                                columnKeys: self.columnKeys
                                                                                     query: query];
    return objectEnumerator;
}

- (MTQuery *)queryForAllRowsWithKeys:(NSArray *)columnKeys {
    id keyColumnKeys;
    keyColumnKeys = [[NSNumber alloc] initWithShort: MTQueryCacheSelectLimitOffsetParamatersColumnKeys];
    id keyTableNames = [[NSNumber alloc] initWithShort: MTQueryCacheSelectLimitOffsetParamatersTableNames];
    id keySortDesc   = [[NSNumber alloc] initWithShort: MTQueryCacheSelectLimitOffsetParamatersSortDesc];
    id keyColumns    = [[NSNumber alloc] initWithShort: MTQueryCacheSelectLimitOffsetParamatersColumns];
    
    NSDictionary *options = [[NSDictionary alloc] initWithObjectsAndKeys:
                             self.columns, keyColumns,
                             self.columnKeys, keyColumnKeys,
                             [self tableName], keyTableNames,
                             self.sortDescriptors, keySortDesc, nil];
    
    
    MTQuery *query = [[MTQueryCacheSelectLimitOffset alloc] initWithObject: options];
    return query;
}

- (NSEnumerator *)enumeratorForAllObjectsSortedRowIdOnly {
    
    NSNumber *keyTableNames, *keySortDesc;
    keyTableNames = [[NSNumber alloc] initWithShort:MTQueryCacheSelectLimitOffsetParamatersTableNames];
    keySortDesc = [[NSNumber alloc] initWithShort:MTQueryCacheSelectLimitOffsetParamatersSortDesc];
    id tableName = [self tableName];
    id sortDescriptors = self.sortDescriptors;
    NSDictionary *options = [[NSDictionary alloc] initWithObjectsAndKeys:
                                                            tableName, keyTableNames,
                                                            sortDescriptors, keySortDesc, nil];
    MTQuery *query = [[MTQueryCacheSelectLimitOffset alloc] initWithObject:options];

    NSURL *url = self.urlFastCache;
    MTDatabaseConnection *connection = [MTDatabaseConnection newDatabaseConnectionForUrl: url];

    MADDataColumn *rowid = [[MADDataColumn alloc] initWithIdentifier:MADIdentifierROWID];
    rowid.type = MADDataTypeInteger;
    
    NSDictionary <__kindof NSString *, __kindof MADDataColumn *> *columns;
    columns = [[NSDictionary alloc] initWithObjectsAndKeys: rowid, MADIdentifierROWID, nil];

    NSArray <__kindof NSString *> *columnKeys;
    columnKeys = [[NSArray alloc] initWithObjects: MADIdentifierROWID, nil];
    
    MTDataTableFastObjectEnumerator *enumerator;
    enumerator = [[MTDataTableFastObjectEnumerator alloc] initWithDatabaseConnection: connection
                                                                             columns: columns
                                                                          columnKeys: columnKeys
                                                                               query: query];
    enumerator.addRowId = NO;
    enumerator.singleColumnNoWrapper = YES;
    
    return enumerator;
}

- (NSArray *)columnKeysForSortDescriptors {
    NSArray *sortDescriptors = self.sortDescriptors;
    NSMutableArray *columnKeys = [[NSMutableArray alloc] initWithCapacity:sortDescriptors.count];
    for (NSSortDescriptor *sortDescriptor in sortDescriptors) {
        @autoreleasepool {
            NSString *key = sortDescriptor.key.copy;
            [columnKeys addObject:key];
        }
    }
    return columnKeys;
}

- (NSEnumerator *)enumeratorForKeyObjectsSorted {
    [self.groupKeys removeAllObjects];
    [self initializeGroupKeys];
    
    NSEnumerator *enumerator;
    NSArray *columnKeys = [self columnKeysForSortDescriptors];
    if (columnKeys.count == 0) {
    
        enumerator = [self enumeratorForAllObjectsSortedRowIdOnly];
        
    } else {
    
        MTQuery *query;
        query = [MTQueryCacheSelectLimitOffset newQueryCacheSelectLimitOffsetWithTableName: [self tableName]
                                                                                columnKeys: columnKeys
                                                                                   columns: self.columns
                                                                           sortDescriptors: self.sortDescriptors];
         [self queryForAllRowsWithKeys:columnKeys];
        
        MTDatabaseConnection *databaseConnection = [MTDatabaseConnection newDatabaseConnectionForUrl: self.urlFastCache];
        enumerator = [[MTDataTableFastObjectEnumerator alloc] initWithDatabaseConnection: databaseConnection
                                                                                 columns: self.columns
                                                                              columnKeys: columnKeys
                                                                                   query: query];
        [(MTDataTableFastObjectEnumerator *)enumerator setAddRowId:YES];
        [(MTDataTableFastObjectEnumerator *)enumerator setSingleColumnNoWrapper:NO];
    }
    return enumerator;
}

- (NSEnumerator *)enumeratorForAllObjectsSorted {
    
    MTDatabaseConnection *databaseConnection;
    MTDataTableFastObjectEnumerator *enumerator;
    
    MTQuery *query;
    query = [MTQueryCacheSelectLimitOffset newQueryCacheSelectLimitOffsetWithTableName: [self tableName]
                                                                            columnKeys: self.columnKeys
                                                                       sortDescriptors: self.sortDescriptors];
    
    databaseConnection = [MTDatabaseConnection newDatabaseConnectionForUrl: self.urlFastCache];
    enumerator = [[MTDataTableFastObjectEnumerator alloc] initWithDatabaseConnection: databaseConnection
                                                                             columns: self.columns
                                                                          columnKeys: self.columnKeys
                                                                               query: query];
    enumerator.addRowId = YES;
    enumerator.singleColumnNoWrapper = NO;
    return enumerator;
}

- (NSArray *)allObjects {
    // FIXME: Implement this.
    return nil;
}

- (NSUInteger)count {
    return [self numberOfRows];
}

- (NSUInteger)numberOfColumns { return  self.columnKeys.count; }

- (NSUInteger)numberOfRows { return self.rowCounter; }

- (NSString *)columnKeyForColumnName:(NSString *)columnName {
    NSString *key;
    for (NSString *columnKey in self.columnKeys) {
        MADDataColumn *column = self.columns[columnKey];
        if ([column.fieldName isEqualToString:columnName]) {
            key = [NSString stringWithString: columnKey];
            break;
        }
    }
    return key;
}

- (id)runSelectQuery:(MTQuery *)query {
    id result = nil;
    sqlite3_stmt *statement = NULL;
    NSError *error = nil;
    NSString *sql = [query getSqlWithError:&error];
    
    const char *sqlc = sql.UTF8String;
    char *queryString = sqlite3_mprintf((char *) sqlc);
    MTDatabaseCache *databaseForSelects = self.databaseForSelects;
    
    BOOL success = sqlite3_prepare_v2(databaseForSelects->_database,
                                      queryString, -1, &statement, NULL) == SQLITE_OK;
    
    for (MTDatabaseDataBinding *dataBinding in query.binaryBindings) {
        [MTDatabaseSqlite3 bindStatement:(void **)&statement withBindings:dataBinding];
    }
    
    if (success && sqlite3_step(statement) == SQLITE_ROW) {
        result = [self objectOfUnknownType:statement forColumnNumber:0];
    }
    NSAssert(success, @"%s", sqlite3_errmsg(databaseForSelects->_database));
    
    sqlite3_finalize(statement);
    sqlite3_free(queryString);
    return result;
}

- (NSUInteger)columnIndexForKey:(NSString *)key {
    return [self.columnKeys indexOfObject:key];
}

- (id)objectOfUnknownType:(sqlite3_stmt *)statement forColumnNumber:(int)columnIndex {
    return [MTDatabaseSqlite3 newValueForStatement:statement columnNumber:columnIndex];
}

- (id)newCurrentObject:(sqlite3_stmt *)statement {
    NSDictionary *currentObject;
    currentObject = [[NSMutableDictionary alloc] initWithCapacity:self.columns.count];
    int columnCounter = 0;
    for (NSString *key in self.columnKeys) {
        @autoreleasepool {
            id columnValue = [MTDatabaseSqlite3 newValueForStatement: statement
                                                        columnNumber: columnCounter];
            if (columnValue != nil) {
                MADDataColumn *dataColumn = self.columns[key];
                [currentObject setValue: columnValue
                                 forKey: dataColumn.identifier];
            }
            columnCounter++;
        }
    }
    if (sqlite3_column_count(statement) >= columnCounter) {
        NSNumber *rowid;
        rowid = [[NSNumber alloc] initWithInt:sqlite3_column_int(statement, columnCounter)];
        [currentObject setValue:rowid forKey:MADIdentifierROWID];
    }
    return currentObject;
}

/*! Call before bulk insert of data. */

- (void)beginBulkInsert {
    self.bulkInsertLoop = true;
    
    [self reopenDbConnection];
    
    self.sortDescriptorsSet = false;
    [self createIndex];
    
    [self.databaseForInserts beginBulkInsert];

    NSString *tableName = [self tableName];
    MADMapDataColumns *columns = self.columns;
    NSArray *columnKeys = self.columnKeys;
    
    MTQueryCacheAddRow *bulkInsertQuery;
    bulkInsertQuery = [[MTQueryCacheAddRow alloc] initWithColumnKeys: columnKeys
                                                             columns: columns
                                                        andTableName: tableName
                                                         forDatabase: self.databaseForInserts];
    self.bulkInsertQuery = bulkInsertQuery;
    
    if (self.queueBulkAdd == nil) {
        dispatch_queue_t queue = dispatch_queue_create(MADQueueBulkAdd, DISPATCH_QUEUE_SERIAL);
        self.queueBulkAdd = queue;
    }
    
}

/*! Call right after bulk insert of data. */

- (void)endBulkInsert {
    __block typeof(self) myself = self;
    dispatch_barrier_sync(self.queueBulkAdd, ^{
        myself.bulkInsertLoop = false;
        [(MTDatabaseSqlite3 *)myself.databaseForInserts endBulkInsert];
    });
}

#pragma mark - Unused

- (NSEnumerator *)enumeratorForGroupLevel:(NSUInteger)groupLevel withKeys:(NSArray *)keys
                                accending:(BOOL)accending {
    NSAssert([keys count] == groupLevel, @"Need a key for each previous group.");
    
    NSArray *columnKeys = @[[self idColumnKeyForGroupLocation:groupLevel]];
    NSMutableArray *whereClause = [[NSMutableArray alloc] initWithCapacity:keys.count];
    
    NSUInteger sortLevel;
    for (NSString *key in keys) {
        sortLevel = groupLevel >= 1 ? groupLevel - 1 : 0;
        NSDictionary *whereStatement = @{@"c" : [self idColumnKeyForGroupLocation:sortLevel],
                                         @"v" : key};
        [whereClause addObject:whereStatement];
    }
    
    NSDictionary *querySelect = @{
                                  @(MADQuerySelectFieldKeys) : columnKeys,
                                  @(MADQuerySelectTableName) : [self tableName],
                                  @(MADQuerySelectSortAccending) : @(accending),
                                  @(MADQuerySelectPredicates) : whereClause,
                                  @(MADQuerySelectColumns) : self.columns
                                  };
    MTQuery *query;
    NSURL *urlFastCache;
    MTDatabaseConnection *databaseConnection;
    MTDataTableFastObjectEnumerator *enumerator;
    
    query = [[MTQuery alloc] initWithQueryType:MADQueryTypeCacheSelectGroupKeys object: querySelect];
    urlFastCache = self.urlFastCache;
    databaseConnection = [MTDatabaseConnection newDatabaseConnectionForUrl: urlFastCache];
    enumerator = [[MTDataTableFastObjectEnumerator alloc] initWithDatabaseConnection: databaseConnection
                                                                             columns: self.columns
                                                                          columnKeys: columnKeys
                                                                               query: query];
    [enumerator setAddRowId:NO];
    [enumerator setSingleColumnNoWrapper:YES];
    return enumerator;
}

- (NSEnumerator *)enumeratorForRowIds:(NSArray *)cacheIds { //Note, software currently usues
                                                            //  NSArray for row ids
    
    NSNumber *keyRowIds = [[NSNumber alloc] initWithShort: MADQuerySelectRowIds];
    NSNumber *keyTableN = [[NSNumber alloc] initWithShort: MADQuerySelectTableName];
    NSNumber *keySortDe = [[NSNumber alloc] initWithShort: MADQuerySelectSortDescriptors];
    NSNumber *keyColumn = [[NSNumber alloc] initWithShort: MADQuerySelectColumns];
    
    NSString *tableName = [NSString stringWithString:[self tableName]];
    NSArray *sortDescs = [NSArray arrayWithArray:self.sortDescriptors];
    MADMapDataColumns *columns = [MADMapDataColumns dictionaryWithDictionary:self.columns];
    
    
    NSDictionary *options = [[NSDictionary alloc] initWithObjectsAndKeys:
                                cacheIds, keyRowIds, tableName, keyTableN,
                                sortDescs, keySortDe, columns, keyColumn, nil];
    
    MTQuery *query = [[MTQuery alloc] initWithQueryType: MADQueryTypeCacheSelectRowIds
                                                 object: options];
    
    NSArray *columnKeys = self.columnKeys;
    NSURL *urlFastCache = self.urlFastCache;
    MTDatabaseConnection *databaseConnection;
    NSEnumerator *data;
    databaseConnection = [MTDatabaseConnection newDatabaseConnectionForUrl: urlFastCache];
    data = [[MTDataTableFastObjectEnumerator alloc] initWithDatabaseConnection: databaseConnection
                                                                       columns: columns
                                                                    columnKeys: columnKeys
                                                                         query: query];
    return data;
}

- (id)debugQuickLookObject {
    NSMutableString *description = [[NSMutableString alloc] initWithString:@"Table name: "];
    [description appendString:[self tableName]];
    [description appendFormat:@"\nColumn keys: %@", self.columnKeys];
    return description;
}

@end
