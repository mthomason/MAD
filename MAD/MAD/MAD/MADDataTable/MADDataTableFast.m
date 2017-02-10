//
//  MADDataTableFast.m
//  MAD
//
//  Created by Michael Thomason on 4/19/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADDataTableFast.h"

#import <Foundation/NSKeyedArchiver.h>
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
#import <Foundation/NSIndexSet.h>

#import <dispatch/dispatch.h>

#import <MADSqlite3/sqlite3.h>

#import <MADFileManager/MADFileUtilities.h>

#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADAppDelegate.h>
#import <MADFoundation/MADApplicationProtocol.h>
#import <MADFoundation/MADURL.h>
#import <MADFoundation/MADCacheProtocol.h>
#import <MADFoundation/MADDataProtocol.h>
#import <MADDataStructures/MADIndex.h>
#import <MADFoundation/MADDataColumn.h>

#import <MADQueryCacheSelectLimitOffsetParamaters.h>

#import "MADConstants.h"

#import "MADDataTableObjectEnumerator.h"
#import "MTDatabaseSqlite3.h"
#import "MADDatabaseConnection.h"

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

#import "MTDatabaseSqlite3.h"

#import "MADQueryCacheIndexCreateParameters.h"

#import "MTDatabase.h"
#import "MADDatabaseProtocol.h"

#import "MADQueryCacheIndexCreateParameters.h"

#import <stdio.h>

#import "madlib.h"

#import "MADQueryParameters.h"
#import "MADDataTablePlist.h"
#import "MADDatabaseDataBinding.h"

static const char * MADQueueBulkAdd = "com.everydayapps.mad.cache.fast";

@interface MADDataTableFast () <MADQueryParametersStandardProtocol,
        MADQueryParametersColumnKeysProtocol,
        MADQueryParametersColumnMetaProtocol,
        MADQueryParametersColumnDataProtocol>

    @property (nonatomic, readwrite, strong) MTDatabaseSqlite3 *databaseForInserts;
    @property (nonatomic, readwrite, strong) MTDatabaseSqlite3 *databaseForSelects;

    @property (nonatomic, readwrite, strong) NSURL *urlFastCache;
    @property (nonatomic, readwrite, strong) NSMutableIndexSet *groupKeyIndexes;

    @property (nonatomic, readwrite, strong) MADIndex *lastDataForCacheId;

    @property (nonatomic, readwrite, strong) MTQueryCacheAddRow *bulkInsertQuery;

    @property (nonatomic, readwrite, strong) dispatch_queue_t queueBulkAdd;

    @property (nonatomic, readwrite, strong) id rowDataLastInserted;

    @property (nonatomic, readwrite, strong) NSMutableArray <MADDatabaseDataBinding *> *binaryBindings;

@end

@implementation MADDataTableFast {
    BOOL _bulkInsertLoop;
    BOOL _sortDescriptorsSet;
    sqlite3_stmt *_statementInsert;
}

- (void)dealloc {

}

- (instancetype)initWithId:(NSUInteger)objectId {
    return [self initWithId:objectId fromCache:YES];
}

- (instancetype)initWithId:(NSUInteger)objectId fromCache:(BOOL)fromCache {
    if (self = [super initWithId:objectId fromCache:fromCache]) {
    
        dispatch_queue_t queue = dispatch_queue_create(MADQueueBulkAdd, DISPATCH_QUEUE_SERIAL);
        self.queueBulkAdd = queue;
    
        _bulkInsertLoop = NO;
        self.tag = objectId;
        _sortDescriptorsSet = NO;
        
        NSMutableIndexSet *groupKeyIndexes = [[NSMutableIndexSet alloc] init];
        self.groupKeyIndexes = groupKeyIndexes;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {

        dispatch_queue_t queue = dispatch_queue_create(MADQueueBulkAdd, DISPATCH_QUEUE_SERIAL);
        self.queueBulkAdd = queue;
        
        NSString *absoluteString = [decoder decodeObjectForKey: [MADDataTableFast keyUrlFastCache]];
        NSURL *url = [NSURL URLWithString:absoluteString];
        self.urlFastCache = url;
        
        NSNumber *tag = [decoder decodeObjectForKey: [MADDataTableFast keyTag]];
        self.tag = tag.unsignedIntegerValue;
        
        _bulkInsertLoop = [decoder decodeBoolForKey: [MADDataTableFast keyBulkInsertLoop]];
        _sortDescriptorsSet = [decoder decodeBoolForKey: [MADDataTableFast keySortDescriptorsSet]];
        
        NSIndexSet *groupKeysArray = [decoder decodeObjectForKey: [MADDataTableFast keyGroupKeys]];
        NSMutableIndexSet *groupKeys = [[NSMutableIndexSet alloc] initWithIndexSet: groupKeysArray];
        self.groupKeyIndexes = groupKeys;
    
    }
    return self;
}

- (NSDictionary *)copyPlist {
    
    NSDictionary *superPlist = [super copyPlist];
    NSMutableDictionary *plist = [[NSMutableDictionary alloc] initWithDictionary:superPlist];
    
    NSURL *urlFastCache = self.urlFastCache;
    NSString *absoluteString = urlFastCache.absoluteString;
    NSAssert(absoluteString != nil, @"We need a path.");
    NSString *urlFastCacheAbsolute = [[NSString alloc] initWithString: absoluteString];
    NSString *keyUrlFastCache = [MADDataTableFast keyUrlFastCache];
    plist[keyUrlFastCache] = urlFastCacheAbsolute;
    
    NSNumber *tag = [[NSNumber alloc] initWithUnsignedInteger: self.tag];
    NSString *keyTag = [MADDataTableFast keyTag];
    plist[keyTag] = tag;
    
    NSNumber *bulkInsert = [[NSNumber alloc] initWithBool:_bulkInsertLoop];
    NSString *keyBulkInsertLoop = [MADDataTableFast keyBulkInsertLoop];
    plist[keyBulkInsertLoop] = bulkInsert;
    
    if (self.groupKeyIndexes != nil) {
        NSString *keyGroupKeys = [MADDataTableFast keyGroupKeys];
        plist[keyGroupKeys] = [NSKeyedArchiver archivedDataWithRootObject: _groupKeyIndexes];
    }
    
    NSNumber *sortSet = [[NSNumber alloc] initWithBool:_sortDescriptorsSet];
    NSString *keySortDescriptorsSet = [MADDataTableFast keySortDescriptorsSet];
    plist[keySortDescriptorsSet] = sortSet;
    
    return plist;
}

- (void)loadWithPlist:(NSDictionary *)plist {
    [super loadWithPlist:plist];
    
    dispatch_queue_t queue = dispatch_queue_create(MADQueueBulkAdd, DISPATCH_QUEUE_SERIAL);
    self.queueBulkAdd = queue;

    id keyUrlFastCache = [MADDataTableFast keyUrlFastCache];
    NSString *absoluteString = plist[keyUrlFastCache];
    NSURL *url = [[NSURL alloc] initWithString:absoluteString];
    self.urlFastCache = url;
    
    id keyTag = [MADDataTableFast keyTag];
    NSNumber *tagWrapper = plist[keyTag];
    self.tag = tagWrapper.unsignedIntegerValue;
    
    id keyBuildInsertLoop = [MADDataTableFast keyBulkInsertLoop];
    NSNumber * __weak bulkInsertLoopWrapper = plist[keyBuildInsertLoop];
    _bulkInsertLoop = bulkInsertLoopWrapper.boolValue;
    
    id keyGroupKeys = [MADDataTableFast keyGroupKeys];
    NSData *groupKeysData = plist[keyGroupKeys];
    NSIndexSet *groupKeysArray = [NSKeyedUnarchiver unarchiveObjectWithData:groupKeysData];
    NSMutableIndexSet *groupKeys;
    if (groupKeysArray) {
        groupKeys = [[NSMutableIndexSet alloc] initWithIndexSet: groupKeysArray];
    } else {
        groupKeys = [[NSMutableIndexSet alloc] init];
    }
    self.groupKeyIndexes = groupKeys;
    
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
    return NSStringFromSelector(@selector(groupKeyIndexes));
}

+ (NSString *)keyColumns {
    SEL selColumns = @selector(columns);
    return NSStringFromSelector(selColumns);
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];

    NSString *absStr = _urlFastCache.absoluteString;
    [encoder encodeObject: absStr forKey: [MADDataTableFast keyUrlFastCache]];
    
    NSNumber *objid = [[NSNumber alloc] initWithUnsignedInteger: self.tag];
    [encoder encodeObject: objid forKey: [MADDataTableFast keyTag]];
    [encoder encodeBool: _bulkInsertLoop forKey: [MADDataTableFast keyBulkInsertLoop]];
    [encoder encodeBool: _sortDescriptorsSet forKey: [MADDataTableFast keySortDescriptorsSet]];

}

- (NSString *)filenameCacheMadDB {
    NSString *tag = [[NSString alloc] initWithFormat:@"%lu", (unsigned long)self.tag];
    return [tag stringByAppendingPathExtension:@"maddb"];
}

- (NSURL *)urlFastCache {
    NSString *filename = [self filenameCacheMadDB];
    NSURL *cacheDirectory, *urlFastCache;

    if (self.cacheDelegate == nil) {
        MADAppDelegate appDelegate = [MADApplication AppDelegate];
        id groupIdentifier = [appDelegate groupIdentifier].copy;
        cacheDirectory = [MADURL newURLForLocalCacheDirectoryForGroupIdentifier:groupIdentifier];
    } else {
        cacheDirectory = [self.cacheDelegate cachedFilesDirectory].copy;
    }
    urlFastCache = [cacheDirectory URLByAppendingPathComponent:filename isDirectory:NO];
    return urlFastCache;
}

- (instancetype)initWithNumberOfColumns:(NSUInteger)numberOfColumns {
    NSAssert(NO, @"Not implemented");
    return nil;
}

- (void)setCacheDelegate:(id<MADCacheProtocol>)cacheDelegate {
    _cacheDelegate = cacheDelegate;
    [self reopenDbConnection];
}

- (void)reopenDbConnection {

    NSURL *urlFastCache = self.urlFastCache;

    MTDatabaseSqlite3 *database; MADDatabaseConnection *connection;
    
    id <MADCacheProtocol> cacheDelegate = _cacheDelegate;
    
    database = [[MTDatabaseSqlite3 alloc] init];
    database.delegate = (id <MADDatabaseProtocol>)cacheDelegate;

    connection = [MADDatabaseConnection newDatabaseConnectionForUrl:urlFastCache];
    database.databaseConnection = connection;
    
    [(MTDatabaseSqlite3 *)database openDatabaseWithFlags: SQLITE_OPEN_READWRITE |
                                                          SQLITE_OPEN_CREATE |
                                                          SQLITE_OPEN_FULLMUTEX];
    self.databaseForInserts = database;
    
    connection = [MADDatabaseConnection newDatabaseConnectionForUrl:urlFastCache];
    database = [MTDatabaseSqlite3 newDatabaseWithConnection:connection];
    database.delegate = (id <MADDatabaseProtocol>)cacheDelegate;
    self.databaseForSelects = database;
}

- (NSString *)tableName {
    char buf[17];
    buf[0] = 't';
    ultoa(self.tag, (buf+1));
    char *ptr = buf;
    NSString *tableName = [[NSString alloc] initWithCString:ptr encoding:NSUTF8StringEncoding];
    return tableName;
}

- (NSString *)columnNameForIdentifier:(NSString *)identifier {
    char buf[17];
    buf[0] = 'c';
    ultoa(identifier.hash, (buf+1));
    char *ptr = buf;
    NSString *tableName = [[NSString alloc] initWithCString:ptr encoding:NSUTF8StringEncoding];
    return tableName;
}
- (NSString *)queryTableName {
    return [self tableName];
}
- (NSArray <NSString *> *)queryColumnKeys {
    return [self columnKeys];
}
- (NSDictionary *)queryColumns {
    return [self columns];
}
- (NSArray *)queryRowData {
    return [self rowDataLastInserted];
}
- (void)addColumn:(MADDataColumn *)column {

    BOOL createTable = self.columnKeys.count == 0;
    NSString *columnName = [self columnNameForIdentifier:column.identifier];
    
    self.columns[columnName] = column;
    [self.columnKeys addObject:columnName];

    NSString *tableName = [self tableName];
    [self addColumn:column toTable:tableName columnName:columnName createTable:createTable
             unique:NO];
}

- (void)setupGroupKeyIndexes {
    NSArray *sortDescriptors = self.sortDescriptors;
    NSArray *columnKeys = self.columnKeys;
    
    [_groupKeyIndexes removeAllIndexes];
    
    NSMutableArray *groupKeys;
    groupKeys = [[NSMutableArray alloc] initWithCapacity: sortDescriptors.count];
    NSSortDescriptor *sortDescriptor;
    NSNumber *columnIndex;
    NSString *key;
    NSUInteger index = NSNotFound;
    for (sortDescriptor in sortDescriptors) {
        @autoreleasepool {
            key = sortDescriptor.key;
            if ((index = [columnKeys indexOfObject: key]) != NSNotFound) {
                columnIndex = [[NSNumber alloc] initWithUnsignedInteger: index];

                [_groupKeyIndexes addIndex:index];
                [groupKeys addObject:columnIndex];
            }
        }
    }
}

- (void)addColumn:(MADDataColumn *)column toTable:(NSString *)table
       columnName:(NSString *)columnName createTable:(BOOL)create unique:(BOOL)unique {
    
    BOOL success = NO;
    NSError * __autoreleasing *errorQuery = NULL;

    NSString *columnAffinity;
    columnAffinity = [MADSqlite3NativeType newSqlite3NativeType: column.type];

    MTQueryCache *query;
    query = [[MTQueryCacheAddColumn alloc] initWithTableName: table
                                                  columnName: columnName
                                                      column: column
                                                 createTable: create
                                            uniqueColumnHack: unique
                                              columnAffinity: columnAffinity];
    query.database = _databaseForInserts;
    success = [_databaseForInserts executeQuery:query withError:errorQuery];
    NSAssert(success, @"%s at %s", sqlite3_errmsg(_databaseForInserts->_database),
             __PRETTY_FUNCTION__);

}



- (void)addRow:(NSArray <id> *)row {

    _rowDataLastInserted = row;
    
    self.rowCounter++;

    if (self.groupKeyIndexes == nil) {
        [self setupGroupKeyIndexes];
    }
    
    sqlite3 *sqlite_database = _databaseForInserts->_database;

    if (_bulkInsertLoop) {
        
        [self.bulkInsertQuery update];
        
        BOOL success = YES;
        
        if (self.binaryBindings == nil) {
            NSMutableArray <MADDatabaseDataBinding *> *binaryBindings;
            binaryBindings = [[NSMutableArray alloc] init];
            self.binaryBindings = binaryBindings;
        }
        
        if (_statementInsert == NULL) {
            NSString *sql = [[NSString alloc] initWithString: [_bulkInsertQuery getSqlWithError:nil]];
            char *csql = sqlite3_mprintf(sql.UTF8String);
            int prepare_result = sqlite3_prepare_v2(sqlite_database, csql, -1, &_statementInsert, NULL);
            NSAssert(prepare_result == SQLITE_OK, @"ExecuteQueryWithSql failed (%s).",
                     (char *)sqlite3_errmsg(sqlite_database));
            success = prepare_result == SQLITE_OK;
            sqlite3_free(csql);
            csql = NULL;
            
        }
        
        NSUInteger columnCounter = 0;
        for (id docObject in row) {
            @autoreleasepool {
                NSString *fieldName = self.columnKeys[columnCounter];
                MADDataColumn *column = self.queryColumns[fieldName];
                
                id databinding = [[MADDatabaseDataBinding alloc] initWithDataType: column.type
                                                                      fieldIndex: columnCounter
                                                                           value: docObject];
                [_databaseForInserts bindStatement:(void **)&_statementInsert withBindings:databinding];
            }
            columnCounter++;
        }
        
        NSAssert(success, @"ExecuteQueryWithSql failed (%s).", (char *)sqlite3_errmsg(sqlite_database));
        
        int step_result = sqlite3_step(_statementInsert);
        
        NSAssert(Sqlite3StepResultOK(step_result), @"sqlite3_step failed (%s).", (char *)sqlite3_errmsg(sqlite_database));
        
        step_result = sqlite3_clear_bindings(_statementInsert);
        step_result = sqlite3_reset(_statementInsert);
        
        NSAssert(step_result == SQLITE_OK, @"sqlite3_finalize failed (%s).", (char *)sqlite3_errmsg(sqlite_database));
        
    } else {

        MTQuery *query;
        query = [[MTQueryCacheAddRow alloc] initWithObject: self];
        NSError * __autoreleasing *errorQuery = NULL;
        BOOL success = [_databaseForInserts executeQuery:query withError:errorQuery];
        NSAssert(success, @"%s at %s", sqlite3_errmsg(sqlite_database),
                 __PRETTY_FUNCTION__);
    }
}

// FIXME: Maybe wrap in autorelease block.
- (void)addRowWithDataForFieldKeys:(NSDictionary <NSString *, id> *)row {

    //@autoreleasepool {
        
    NSArray <NSString *> *columnKeys = self.columnKeys;
    NSMutableArray *rowData = [[NSMutableArray alloc] initWithCapacity:columnKeys.count];
    for (id columnDefKey in columnKeys) {
        
        MADDataColumn *columnDef = self.columns[columnDefKey];
        id obj = row[columnDef.fieldName];
        if (obj == nil) obj = [NSNull null];
        [rowData addObject:obj];
        
    }
    [self addRow:rowData];
    
    //}
    
}

- (void)sortUsingDescriptors:(NSArray <NSSortDescriptor *> *)sortDescriptors {

    [_groupKeyIndexes removeAllIndexes];
    
    if (self.columnKeys.count > 0 && self.columns.count > 0 && sortDescriptors.count > 0) {
            
        NSMutableArray <__kindof NSSortDescriptor *> *newSortDescriptors;
        newSortDescriptors = [[NSMutableArray <__kindof NSSortDescriptor *> alloc] initWithCapacity:sortDescriptors.count];

            NSUInteger groupKeyCounter;
        NSArray *columnKeys;
        
        for (NSSortDescriptor *sortDescriptor in sortDescriptors) {
                groupKeyCounter = 0;

                columnKeys = self.columnKeys;
                for (NSString *columnKey in columnKeys) {
                    
                    @autoreleasepool {
                        MADDataColumn *column = self.columns[columnKey];
                        NSString *key = sortDescriptor.key;
                        if (key.length > 0 && [column.fieldName isEqualToString: key]) {
                        
                            SEL sortAlgo = MADDataTypeSelectorForSorting(column.type);
                            NSSortDescriptor *newSortDescriptor;
                            newSortDescriptor = [[NSSortDescriptor alloc] initWithKey: columnKey
                                                                            ascending: sortDescriptor.ascending
                                                                             selector: sortAlgo];
                            [newSortDescriptors addObject:newSortDescriptor];
                            
                            [_groupKeyIndexes addIndex:groupKeyCounter];
                            
                            break;
                        }
                    }
                    groupKeyCounter++;
                }
                if (newSortDescriptors.count == sortDescriptors.count) {
                    _sortDescriptorsSet = YES;
                    self.sortDescriptors = newSortDescriptors;
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

- (NSString *)cacheTableNameForGroupLevel:(NSUInteger)groupLevel {
    char buf[17];
    buf[0] = 's';
    ultoa(groupLevel, (buf+1));
    char *ptr = buf;
    id result = [[NSString alloc] initWithCString:ptr encoding:NSUTF8StringEncoding];
    return result;
}

- (NSString *)indexNameForGroupLevel:(NSUInteger)groupLevel andIndex:(NSUInteger)index {
    char buf[17];
    buf[0] = 'i';
    ultoa(groupLevel, (buf+1));
    ultoa(index, (buf+1));
    char *ptr = buf;
    id result = [[NSString alloc] initWithCString:ptr encoding:NSUTF8StringEncoding];
    return result;
}

- (void)createIndex {
    id <MADDataProtocol> dataDelegate = self.dataDelegate;
    
    NSArray <NSSortDescriptor *> *sortDescriptors = [dataDelegate sortDescriptors];
    [self.sortDescriptors setArray:sortDescriptors];
    [self sortUsingDescriptors:self.sortDescriptors];
    
    NSUInteger sortDescCtr = self.sortDescriptors.count;
    NSArray *sortDescriptorGroups;
    sortDescriptorGroups = [self sortDescriptorIndexGroupsForSortDescriptors: self.sortDescriptors];
    
    NSUInteger groupCounter = 0;
    NSMutableArray *queries = [[NSMutableArray alloc] initWithCapacity:sortDescriptorGroups.count];
    
    MADQueryCacheIndexCreateParameters *parameters;
    parameters = [[MADQueryCacheIndexCreateParameters alloc] init];
    parameters.columns = self.columns;
    parameters.tableName = self.tableName.copy;
    
    for (NSArray *sortDescriptorGroup in sortDescriptorGroups) {
        
        if (sortDescriptorGroup.count > 0) {
            parameters.sortDescriptors = sortDescriptorGroup;
            parameters.groupName = [self indexNameForGroupLevel: sortDescCtr
                                                      andIndex: groupCounter].copy;
            
            MTQuery *queryCreateIndex = [[MTQueryCacheIndexCreate alloc] initWithObject:parameters];
            queryCreateIndex.dataDelegate = dataDelegate;
            
            NSError * __autoreleasing *sqlError = NULL;
            NSString *sqlResult = [queryCreateIndex getSqlWithError: sqlError];
            if (sqlResult.length > 0) {
                queries[groupCounter] = sqlResult.copy;
            }
            groupCounter++;
        }
    }
    NSString *queryString = [queries componentsJoinedByString:@";\n"];
    char *zErr = NULL;
    int exec_result = sqlite3_exec(self.databaseForInserts.databaseHandle, queryString.UTF8String, NULL, NULL, &zErr);
    NSAssert(exec_result != SQLITE_ABORT, @"%s at %s", sqlite3_errmsg(self.databaseForInserts.databaseHandle), __PRETTY_FUNCTION__);
}

- (void)dropIndex {
    NSUInteger sortDescCtr = self.sortDescriptors.count;
    NSUInteger groupCounter = 0;
    BOOL success;
    NSString *groupName;
    NSNumber *key;
    NSDictionary *parameters;
    MTQuery *query;
    for (NSUInteger i = 0; i<sortDescCtr; i++) {
        groupName = [self indexNameForGroupLevel:sortDescCtr andIndex:groupCounter];
        key = [[NSNumber alloc] initWithUnsignedInteger: MTQueryCacheIndexDropIndexName];
        parameters = [[NSDictionary alloc] initWithObjectsAndKeys: groupName, key, nil];
        NSError * __autoreleasing *errorQuery = NULL;
        query = [[MTQueryCacheIndexDrop alloc] initWithObject:parameters];
        success = [self.databaseForInserts executeQuery:query withDataTable:self andError:errorQuery];
        NSAssert(success, @"%s at %s", sqlite3_errmsg(_databaseForInserts->_database), __PRETTY_FUNCTION__);
        errorQuery = NULL;
    }
}

- (void)vacuumCacheDb {
    BOOL success;
    NSError * __autoreleasing *errorQuery = NULL;
    MTQuery *queryVacuum = [[MTQueryCacheVacuum alloc] init];
    success = [self.databaseForInserts executeQuery:queryVacuum withError:errorQuery];
    NSAssert(success, @"%s at %s", sqlite3_errmsg(_databaseForInserts->_database),
             __PRETTY_FUNCTION__);
}

- (void)dropTable {
    [self dropTableName:[self tableName]];
}

- (void)dropTableName:(NSString *)tableName {
    BOOL success;
    NSError * __autoreleasing *errorQuery = NULL;
    MTQuery *queryDropTable = [[MTQueryCacheDropTable alloc] initWithObject:tableName];
    success = [self.databaseForInserts executeQuery: queryDropTable
                                          withError: errorQuery];
    NSAssert(success, @"%s at %s", sqlite3_errmsg(_databaseForInserts->_database),
             __PRETTY_FUNCTION__);
}

- (void)deleteAll {
    BOOL success;
    NSError * __autoreleasing *errorQuery = NULL;
    NSString *tableName = [self tableName];
    MTQuery *queryDeleteAllFromTable;
    queryDeleteAllFromTable = [[MTQueryCacheDeleteAllFromTable alloc] initWithObject:tableName];
    success = [self.databaseForInserts executeQuery: queryDeleteAllFromTable
                                          withError: errorQuery];
    NSAssert(success, @"%s at %s", sqlite3_errmsg(_databaseForInserts->_database),
             __PRETTY_FUNCTION__);
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

- (NSDictionary *)copyDataForCacheId:(NSUInteger)cacheId andColumnIdentifier:(NSString *)columnIdentifier {
    NSString *columnName = [self columnNameForIdentifier:columnIdentifier];
    NSArray *columnKeys = [[NSArray alloc] initWithObjects:columnName, nil];
    NSAssert([self.columnKeys containsObject:columnName], @"Searching for a field that doesn't exist");

    NSDictionary * result = nil;
    NSString *tableName = [self tableName].copy;
    
    NSNumber *keyRowId = [[NSNumber alloc] initWithShort: MADQuerySelectRowId];
    NSNumber *keyFieldKey = [[NSNumber alloc] initWithShort: MADQuerySelectFieldKeys];
    NSNumber *keyTableNmae = [[NSNumber alloc] initWithShort: MADQuerySelectTableName];
    
    NSNumber *cacheID = [[NSNumber alloc] initWithUnsignedInteger:cacheId];
    NSDictionary *options = [[NSDictionary alloc] initWithObjectsAndKeys:
                             cacheID,           keyRowId,
                             columnKeys,         keyFieldKey,
                             tableName,          keyTableNmae, nil];
    
    MTQuery * query = [[MTQuery alloc] initWithQueryType: MADQueryTypeCacheSelectRowId
                                                  object: options];
    sqlite3_stmt *statement = NULL;
    NSError *error = nil;
    NSString *sql = [query getSqlWithError:&error];
    
    const char *sqlUTF8String = sql.UTF8String;
    char *queryString = sqlite3_mprintf((char *) sqlUTF8String);
    
    MTDatabaseSqlite3 *databaseForSelects = self.databaseForSelects;
    BOOL success = sqlite3_prepare_v2(databaseForSelects->_database, queryString, -1,
                                      &statement, NULL) == SQLITE_OK;
    
    if (success) {  //Expect success to == NO in normal working conditions.
        int stepResult = sqlite3_step(statement);
        if (stepResult == SQLITE_ROW || stepResult == SQLITE_DONE) {
            result = [self newCurrentObject:statement fieldKey:columnName];
            
            //MADIndex * lastDataForCacheId = [[MADIndex alloc] initWithIndex:cacheId
            //                                                      andObject:result];
            //self.lastDataForCacheId = lastDataForCacheId;
            
        } else {
            // FIXME: Log error.
            result = [[NSDictionary alloc] init];
        }
    }
    
    sqlite3_finalize(statement);
    sqlite3_free(queryString);
    
    return result;
}

// FIXME: Return error handler... remove credentals
- (NSDictionary *)copyDataForCacheId:(NSUInteger)cacheId {
    
    if (self.lastDataForCacheId != nil) {
        if (cacheId == self.lastDataForCacheId.index) {
            NSDictionary *result = [NSDictionary dictionaryWithDictionary:self.lastDataForCacheId.object];
            return result;
        }
    }
    
    NSDictionary * result = nil;
    NSString *tableName = [self tableName].copy;
    
    NSNumber *keyRowId = [[NSNumber alloc] initWithShort: MADQuerySelectRowId];
    NSNumber *keyFieldKey = [[NSNumber alloc] initWithShort: MADQuerySelectFieldKeys];
    NSNumber *keyTableNmae = [[NSNumber alloc] initWithShort: MADQuerySelectTableName];
    NSNumber *cacheID = [[NSNumber alloc] initWithUnsignedInteger:cacheId];

    NSDictionary *options = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    cacheID,            keyRowId,
                                    self.columnKeys,    keyFieldKey,
                                    tableName,          keyTableNmae, nil];
    
    MTQuery * query = [[MTQuery alloc] initWithQueryType: MADQueryTypeCacheSelectRowId
                                                  object: options];
    sqlite3_stmt *statement = NULL;
    NSError *error = nil;
    NSString *sql = [query getSqlWithError:&error];
    
    const char *sqlUTF8String = sql.UTF8String;
    char *queryString = sqlite3_mprintf((char *) sqlUTF8String);

    MTDatabaseSqlite3 *databaseForSelects = self.databaseForSelects;
    BOOL success = sqlite3_prepare_v2(databaseForSelects->_database, queryString, -1,
                                      &statement, NULL) == SQLITE_OK;
    
    if (success) {  //Expect success to == NO in normal working conditions.
        int stepResult = sqlite3_step(statement);
        if (stepResult == SQLITE_ROW || stepResult == SQLITE_DONE) {
            result = [self newCurrentObject:statement];
            
            MADIndex * lastDataForCacheId = [[MADIndex alloc] initWithIndex:cacheId
                                                                  andObject:result];
            self.lastDataForCacheId = lastDataForCacheId;
            
        } else {
// FIXME: Log error.
            result = [[NSDictionary alloc] init];
        }
    }
    
    sqlite3_finalize(statement);
    sqlite3_free(queryString);

    return result;
}

- (NSArray *)whereClauseForGroupKeys:(NSArray *)groupKeys {
    [self setupGroupKeyIndexes];
    NSMutableArray * whereClause = [[NSMutableArray alloc] initWithCapacity:groupKeys.count];
    NSUInteger groupLevel = 0,
               groupIndex = [_groupKeyIndexes firstIndex];
    NSDictionary *whereStatement;
    NSString *columnLevel, *gk;
    while(groupIndex != NSNotFound && groupLevel < groupKeys.count) {
        @autoreleasepool {
            columnLevel = ((NSString *)self.columnKeys[groupIndex]).copy;
            gk = ((NSString *)groupKeys[groupLevel]).copy;
            whereStatement = [[NSDictionary alloc] initWithObjectsAndKeys:
                              columnLevel, MTQueryKeyPredicateColumn,
                              gk, MTQueryKeyPredicateValue, nil];
            [whereClause addObject:whereStatement];
            groupLevel++;
        }
        groupIndex = [_groupKeyIndexes indexGreaterThanIndex: groupIndex];
    }
    return whereClause;
}

// FIXME: Return error handler... remove credentals
- (NSArray <__kindof NSDictionary *> *)objectsForGroupKeys:(NSArray *)groupKeys {

    NSArray *whereClause = [self whereClauseForGroupKeys:groupKeys];
    NSString *tableName = [self tableName].copy;
    NSArray *sortDescriptors = self.sortDescriptors;
    NSDictionary <NSString *, MADDataColumn *> *columns = self.columns;
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
    
    char *queryString = sqlite3_mprintf(sql.UTF8String);
    
    MTDatabaseSqlite3 *databaseForSelects = self.databaseForSelects;
    
    BOOL success = sqlite3_prepare_v2(databaseForSelects->_database,
                                      queryString, -1, &statement, NULL) == SQLITE_OK;
    
    NSArray *queryBinaryBindings = query.binaryBindings;
    for (MADDatabaseDataBinding *dataBinding in queryBinaryBindings) {
        [databaseForSelects bindStatement: (void **)&statement withBindings: dataBinding];
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
    sqlite3_clear_bindings(statement);
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
        
        MTDatabaseSqlite3 *databaseForSelects = self.databaseForSelects;

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
    MADDatabaseConnection *databaseConnection = [MADDatabaseConnection newDatabaseConnectionForUrl: urlFastCache];
    objectEnumerator = [[MADDataTableObjectEnumerator alloc] initWithDatabaseConnection: databaseConnection
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
    MADDatabaseConnection *connection = [MADDatabaseConnection newDatabaseConnectionForUrl: url];

    MADDataColumn *rowid = [[MADDataColumn alloc] initWithIdentifier:MADIdentifierROWID];
    rowid.type = MADDataTypeInteger;
    
    NSDictionary <__kindof NSString *, __kindof MADDataColumn *> *columns;
    columns = [[NSDictionary alloc] initWithObjectsAndKeys: rowid, MADIdentifierROWID, nil];

    NSArray <__kindof NSString *> *columnKeys;
    columnKeys = [[NSArray alloc] initWithObjects: MADIdentifierROWID, nil];
    
    MADDataTableObjectEnumerator *enumerator;
    enumerator = [[MADDataTableObjectEnumerator alloc] initWithDatabaseConnection: connection
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
    [self setupGroupKeyIndexes];
    
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
        
        MADDatabaseConnection *databaseConnection = [MADDatabaseConnection newDatabaseConnectionForUrl: self.urlFastCache];
        enumerator = [[MADDataTableObjectEnumerator alloc] initWithDatabaseConnection: databaseConnection
                                                                              columns: self.columns
                                                                           columnKeys: columnKeys
                                                                                query: query];
        [(MADDataTableObjectEnumerator *)enumerator setAddRowId:YES];
        [(MADDataTableObjectEnumerator *)enumerator setSingleColumnNoWrapper:NO];
    }
    return enumerator;
}

- (NSEnumerator *)enumeratorForAllObjectsSorted {
    
    MADDatabaseConnection *databaseConnection;
    MADDataTableObjectEnumerator *enumerator;
    
    MTQuery *query;
    query = [MTQueryCacheSelectLimitOffset newQueryCacheSelectLimitOffsetWithTableName: [self tableName]
                                                                            columnKeys: self.columnKeys
                                                                       sortDescriptors: self.sortDescriptors];
    
    databaseConnection = [MADDatabaseConnection newDatabaseConnectionForUrl: self.urlFastCache];
    enumerator = [[MADDataTableObjectEnumerator alloc] initWithDatabaseConnection: databaseConnection
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
    MTDatabaseSqlite3 *databaseForSelects = self.databaseForSelects;
    
    BOOL success = sqlite3_prepare_v2(databaseForSelects->_database,
                                      queryString, -1, &statement, NULL) == SQLITE_OK;
    
    NSAssert(success, @"%s", sqlite3_errmsg(databaseForSelects->_database));
    
    for (MADDatabaseDataBinding *dataBinding in query.binaryBindings) {
        [databaseForSelects bindStatement:(void **)&statement withBindings:dataBinding];
    }
    
    if (success && sqlite3_step(statement) == SQLITE_ROW) {
        result = [self objectOfUnknownType:statement forColumnNumber:0];
    }
    NSAssert(success, @"%s", sqlite3_errmsg(databaseForSelects->_database));

    sqlite3_clear_bindings(statement);
    sqlite3_finalize(statement);
    sqlite3_free(queryString);
    return result;
}

- (NSUInteger)columnIndexForKey:(NSString *)key {
    return [self.columnKeys indexOfObject:key];
}

- (id <NSCopying>)objectOfUnknownType:(sqlite3_stmt *)statement forColumnNumber:(int)columnIndex {
    id <NSCopying> result =  [MADDatabaseResultValue newDatabaseResultValue:statement columnNumber:columnIndex];
    return result;
}

- (id)newCurrentObject:(sqlite3_stmt *)statement fieldKey:(NSString *)fieldKey {
    NSDictionary *currentObject;
    currentObject = [[NSMutableDictionary alloc] initWithCapacity:2];
    id <NSCopying> columnValue = [MADDatabaseResultValue newDatabaseResultValue: statement
                                                                   columnNumber: 0];
    if (columnValue != nil) {
        MADDataColumn *dataColumn = self.columns[fieldKey];
        [currentObject setValue: columnValue
                         forKey: dataColumn.identifier];
    }
    NSNumber *rowid;
    rowid = [[NSNumber alloc] initWithInt:sqlite3_column_int(statement, 1)];
    [currentObject setValue:rowid forKey:MADIdentifierROWID];
    return currentObject;
}

- (id)newCurrentObject:(sqlite3_stmt *)statement {
    NSDictionary *currentObject;
    currentObject = [[NSMutableDictionary alloc] initWithCapacity:self.columns.count + 1];
    int columnCounter = 0;
    for (NSString *key in self.columnKeys) {
        @autoreleasepool {
            id <NSCopying> columnValue = [MADDatabaseResultValue newDatabaseResultValue: statement
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
    _bulkInsertLoop = YES;
    
    [self reopenDbConnection];
    
    _sortDescriptorsSet = NO;
    [self createIndex];
    
    [self.databaseForInserts beginBulkInsert];
    
    MTQueryCacheAddRow *bulkInsertQuery;
    bulkInsertQuery = [[MTQueryCacheAddRow alloc] initWithObject: self];
    self.bulkInsertQuery = bulkInsertQuery;
    
    if (self.queueBulkAdd == nil) {
        dispatch_queue_t queue = dispatch_queue_create(MADQueueBulkAdd, DISPATCH_QUEUE_SERIAL);
        self.queueBulkAdd = queue;
    }
    
}

/*! Call right after bulk insert of data. */

- (void)endBulkInsert {

    sqlite3_finalize(_statementInsert);
    _statementInsert = NULL;

    __block typeof(self) myself = self;
    __block BOOL internalBulkInsertLoop = _bulkInsertLoop;
    dispatch_barrier_sync(self.queueBulkAdd, ^{
        internalBulkInsertLoop = NO;
        [(MTDatabaseSqlite3 *)myself.databaseForInserts endBulkInsert];
    });
    _bulkInsertLoop = internalBulkInsertLoop;
}

- (NSEnumerator *)enumeratorForRowIds:(NSArray *)cacheIds { //Note, software currently usues
                                                            //  NSArray for row ids
    
    NSNumber *keyRowIds = [[NSNumber alloc] initWithShort: MADQuerySelectRowIds];
    NSNumber *keyTableN = [[NSNumber alloc] initWithShort: MADQuerySelectTableName];
    NSNumber *keySortDe = [[NSNumber alloc] initWithShort: MADQuerySelectSortDescriptors];
    NSNumber *keyColumn = [[NSNumber alloc] initWithShort: MADQuerySelectColumns];
    
    NSString *tableName = [NSString stringWithString:[self tableName]];
    NSArray *sortDescs = [NSArray arrayWithArray:self.sortDescriptors];
    NSDictionary <NSString *, MADDataColumn *> *columns = [NSDictionary dictionaryWithDictionary:self.columns];
    
    
    NSDictionary *options = [[NSDictionary alloc] initWithObjectsAndKeys:
                                cacheIds, keyRowIds, tableName, keyTableN,
                                sortDescs, keySortDe, columns, keyColumn, nil];
    
    MTQuery *query = [[MTQuery alloc] initWithQueryType: MADQueryTypeCacheSelectRowIds
                                                 object: options];
    
    NSArray *columnKeys = self.columnKeys;
    NSURL *urlFastCache = self.urlFastCache;
    MADDatabaseConnection *databaseConnection;
    NSEnumerator *data;
    databaseConnection = [MADDatabaseConnection newDatabaseConnectionForUrl: urlFastCache];
    data = [[MADDataTableObjectEnumerator alloc] initWithDatabaseConnection: databaseConnection
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
