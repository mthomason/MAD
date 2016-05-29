//
//  MTTable.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 4/6/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTDataTable.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSPropertyList.h>
#import <Foundation/NSStream.h>
#import <Foundation/NSURL.h>
#import "MADDataColumn.h"

static NSString * const StringEmpty = @"";

@interface MTDataTable ()

@end

@implementation MTDataTable

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
    
        id key;
        key = [MTDataTable keyName];
        NSString *name = [decoder decodeObjectForKey: key];
        self.name = name;
       
        key = [MTDataTable keyColumnKeys];
        NSMutableArray *columnKeys =    [decoder decodeObjectForKey: key];
        self.columnKeys = columnKeys;
        
        MADMutableMapDataColumns *columns;
        key = [MTDataTable keyColumns];
        columns =  [decoder decodeObjectForKey: key];
        self.columns = columns;
        
        key = [MTDataTable keyRowCounter];
        NSNumber *rowCounterObject = [decoder decodeObjectForKey: key];
        self.rowCounter = rowCounterObject.unsignedIntegerValue;
        
        NSMutableArray *sortDescriptors;
        key = [MTDataTable keySortDescriptors];
        sortDescriptors = [decoder decodeObjectForKey:key];
        self.sortDescriptors = sortDescriptors;
        
        NSNumber *objid = [decoder decodeObjectForKey:@"objid"];
        self.tag = objid.unsignedIntegerValue;
        
    }
    return self;
}

- (instancetype)initWithNumberOfColumns:(NSUInteger)numberOfColumns {
    if (self = [super init]) {
        
        NSString *name = @"";
        self.name = name;
        
        NSMutableArray *columnKeys = [[NSMutableArray alloc] initWithCapacity:numberOfColumns];
        self.columnKeys = columnKeys;
        
        MADMutableMapDataColumns *columns;
        columns = [[MADMutableMapDataColumns alloc] initWithCapacity:numberOfColumns];
        self.columns = columns;
        
        self.rowCounter = 0;
        
        NSMutableArray *sortDescriptors = [[NSMutableArray alloc] init];
        self.sortDescriptors = sortDescriptors;

    }
    return self;
}

- (instancetype)init {
    if (self = [super init]) {
        [self initializeWithObjectId:0 fromCache:NO];
    }
    return self;
}

- (instancetype)initWithId:(NSUInteger)objectId fromCache:(BOOL)fromCache {
    if (self = [super init]) {
        [self initializeWithObjectId:objectId fromCache:fromCache];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    
    id objid;
    NSString *key;

    objid = [[NSNumber alloc] initWithUnsignedInteger: _tag];
    [encoder encodeObject:  objid forKey: @"objid"];

    key = [MTDataTable keySortDescriptors];
    objid = _sortDescriptors;
    [encoder encodeObject: objid forKey: key];

    key = [MTDataTable keyName];
    [encoder encodeObject: _name forKey: key];
    
    key = [MTDataTable keyColumnKeys];
    objid = _columnKeys;
    [encoder encodeObject: objid forKey: key];
    
    key = [MTDataTable keyColumns];
    objid = _columns;
    [encoder encodeObject: objid forKey: key];
    
    key = [MTDataTable keyRowCounter];
    objid = [[NSNumber alloc] initWithUnsignedInteger: _rowCounter];
    [encoder encodeObject: objid forKey: key];
    
}

- (instancetype)initWithId:(NSUInteger)objectId {
    return [self initWithId:objectId fromCache:YES];
}

- (void)initializeWithObjectId:(NSUInteger)objectId fromCache:(BOOL)fromCache {
    
    NSString *name = StringEmpty;
    self.name = name;
    
    NSMutableArray *columnKeys = [[NSMutableArray alloc] init];
    self.columnKeys = columnKeys;
    
    NSMutableArray *sortDescriptors = [[NSMutableArray alloc] init];
    self.sortDescriptors = sortDescriptors;
    
    self.rowCounter = 0;
    self.tag = objectId;

    NSMutableDictionary <__kindof NSString *, __kindof MADDataColumn *> *columns;
    columns = [[NSMutableDictionary <__kindof NSString *, __kindof MADDataColumn *> alloc] init];
    self.columns = columns;
    
}

- (NSEnumerator *)enumeratorForAllObjectsSortedRowIdOnly {
    NSAssert(false, @"Not implemented: %s", __PRETTY_FUNCTION__);
    return nil;
}

- (NSArray <__kindof NSDictionary *> *)objectsForGroupKeys:(NSArray *)groupKeys {
    NSAssert(false, @"Not implemented: %s", __PRETTY_FUNCTION__);
    return nil;
}

- (NSEnumerator *)enumeratorForAllObjectsSorted {
    NSAssert(false, @"Not implemented: %s", __PRETTY_FUNCTION__);
    return nil;
}

- (NSEnumerator *)enumeratorForGroupLevel:(NSUInteger)groupLevel
                                 withKeys:(NSArray *)keys accending:(BOOL)accending {
    NSAssert(false, @"Not implemented: %s", __PRETTY_FUNCTION__);
    return nil;
}

- (NSDictionary *)copyDataForCacheId:(NSNumber *)cacheId {
    NSAssert(false, @"Not implemented: %s", __PRETTY_FUNCTION__);
    return nil;
}

- (NSEnumerator *)enumeratorForKeyObjectsSorted {
    NSAssert(false, @"Not implemented: %s", __PRETTY_FUNCTION__);
    return nil;    
}

+ (NSString *)keyUrl { return @"url"; }

- (NSString *)newFilenameMDCache {
    NSString *tag = [[NSString alloc] initWithFormat:@"%lu", (unsigned long)self.tag];
    NSString *result = [tag stringByAppendingPathExtension:@"mdcache"];
    return result;
}

- (void)loadFromCacheWithUrl:(NSURL *)url {
    NSString *path = url.path.copy;
    NSAssert(path != nil, @"Need a path at %s", __PRETTY_FUNCTION__);
    if (!path) return;
    
    NSInputStream *inputStream = [[NSInputStream alloc] initWithFileAtPath: path];
    [inputStream open];

    if (inputStream.streamStatus == NSStreamStatusError) return;
    
    NSPropertyListFormat format;
    NSError *error = nil;
    id plist = [NSPropertyListSerialization propertyListWithStream: inputStream options: 0
                                                            format: &format error: &error];
    NSAssert(error == nil, @"%s %@", __PRETTY_FUNCTION__, error);
    if (!plist) return;
    
    [self loadWithPlist:plist];
}

- (bool)cacheWithUrl:(NSURL *)url {

    NSLog(@"Writing cache to url %@.", url);

    NSDictionary *plist = [self copyPlist];

    NSError * __autoreleasing *error = nil;
    static const NSUInteger propertyListFormat = NSPropertyListBinaryFormat_v1_0;
    NSData *cache = [NSPropertyListSerialization dataWithPropertyList: plist
                                                               format: propertyListFormat
                                                              options: 0 error: error];

    NSAssert(error == nil, @"%s %@", __PRETTY_FUNCTION__, *error);

    bool success = false;
    if (url) {
        NSError * __autoreleasing *errorWriting = nil;
        success = [cache writeToURL: url
                            options: NSDataWritingAtomic |
                                     NSDataWritingFileProtectionCompleteUnlessOpen
                              error: errorWriting] ? true : false;

        NSAssert(errorWriting == nil, @"%s %@", __PRETTY_FUNCTION__, *error);

    }
    
    return success;
}

- (MADDataTablePlist *)copyPlist {
    
    NSString *keyName = [MTDataTable keyName];
    NSString *keyColumnKeys = [MTDataTable keyColumnKeys];
    NSString *keyColumns = [MTDataTable keyColumns];
    NSString *keyRowCounter = [MTDataTable keyRowCounter];
    NSNumber *rowCounter = [[NSNumber alloc] initWithUnsignedInteger: self.rowCounter];
    
    NSArray *ck = self.columnKeys;
    NSArray *columnKeys = [[NSArray alloc] initWithArray:ck];
    
    NSDictionary *cp = [self columnsPlist];
    NSDictionary *columnsPlist = [[NSDictionary alloc] initWithDictionary:cp];
    
    return @{
             keyName        : self.name,
             keyColumnKeys  : columnKeys,
             keyColumns     : columnsPlist,
             keyRowCounter  : rowCounter,
             };
}

- (void)loadWithPlist:(MADDataTablePlist *)plist {
    NSString *name = plist[[MTDataTable keyName]];
    if (name == nil) {
        name = @"";
    }

    _name = name.copy;
    
    NSString * const keyColumnKeys = [MTDataTable keyColumnKeys];
    
    id columnKeysArray = plist[keyColumnKeys];
    
    NSMutableArray <__kindof NSString *> *columnKeys =
                [[NSMutableArray <__kindof NSString *> alloc] initWithArray: columnKeysArray
                                                                  copyItems: YES];
    
    NSString * const keySortDescriptors = [MTDataTable keySortDescriptors];
    NSArray * __weak sortDescriptorsArray = plist[keySortDescriptors];
    NSMutableArray *sortDescriptors = [[NSMutableArray alloc] initWithArray: sortDescriptorsArray
                                                                  copyItems: YES];
    self.sortDescriptors = sortDescriptors;
    
    NSString *keyColumns = [MTDataTable keyColumns];
    NSDictionary * __weak plistDataColumn = plist[keyColumns];
    NSDictionary *columnsPlist = [[NSDictionary alloc] initWithDictionary: plistDataColumn
                                                                copyItems: YES];

    for (NSString *key in columnKeys) {
            NSDictionary * __weak columnPlist = columnsPlist[key];
            MADDataColumn *column = [[MADDataColumn alloc] initWithPlist: columnPlist];
            self.columns[key] = column;
    }
    self.columnKeys = columnKeys;
    
    NSString * const keyRowCounter = [MTDataTable keyRowCounter];
    NSNumber * __weak rowCounterObj = plist[keyRowCounter];
    self.rowCounter = rowCounterObj.unsignedIntegerValue;
    
}

- (NSDictionary *)columnsPlist {
    
    MADMutableMapPlist *columnsPlist;
    columnsPlist = [[MADMutableMapPlist alloc] initWithCapacity:[self numberOfColumns]];
    for (NSString *key in [self columnKeys]) {
        MADDataColumn *dataColumn = self.columns[key];
        columnsPlist[key] = [dataColumn copyPlist];
    }
    return columnsPlist;
}

- (void)addColumn:(MADDataColumn *)column {}
- (void)addRow:(NSArray *)row {}
- (void)addRowWithDataForFieldKeys:(NSDictionary *)row {}

- (void)sortUsingDescriptors:(NSArray *)sortDescriptors {}

- (void)removeAllObjects {}

- (id)objectAtRow:(NSUInteger)row column:(NSUInteger)column {
    return nil;
}

- (id)objectAtRow:(NSUInteger)row {
    return nil;
}

- (NSEnumerator *)columnsEnumerator {
    return nil;
}
- (NSEnumerator *)objectEnumerator {
    return nil;
}

- (void)beginBulkInsert {}
- (void)endBulkInsert {}

- (NSArray *)allObjects {
    id all = [[NSArray alloc] init];
    return all;
}

- (NSArray *)objectAtRow:(NSUInteger)row limit:(NSUInteger)limit {
    return @[];
}

- (NSUInteger)count {
    return 0;
}

- (NSUInteger)numberOfColumns {
    return 0;
}

- (NSUInteger)numberOfRows {
    return 0;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len {
    return 0;
}

+ (NSString *)keyName {
    SEL selName = @selector(name);
    return NSStringFromSelector(selName);
}

+ (NSString *)keyColumnKeys {
    SEL selColumnKeys = @selector(columnKeys);
    return NSStringFromSelector(selColumnKeys);
}

+ (NSString *)keyColumns {
    SEL selColumns = @selector(columns);
    return NSStringFromSelector(selColumns);
}

+ (NSString *)keyRowCounter {
    SEL selRowCounter = @selector(rowCounter);
    return NSStringFromSelector(selRowCounter);
}
+ (NSString *)keySortDescriptors {
    SEL selSortDescriptors = @selector(sortDescriptors);
    return NSStringFromSelector(selSortDescriptors);
}

@end
