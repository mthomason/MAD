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

#import "MTDataTablePlist.h"

#import <Foundation/NSArray.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSPropertyList.h>
#import <Foundation/NSStream.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSEnumerator.h>

#import <MADFoundation/MADDataColumn.h>

static NSString * const StringEmpty = @"";

@interface MTDataTablePlist ()

@end

@implementation MTDataTablePlist

- (instancetype)init {
    if (self = [super init]) {
        [self setupWithObjectId:0 fromCache:NO];
    }
    return self;
}

- (instancetype)initWithId:(NSUInteger)objectId {
    return [self initWithId:objectId fromCache:YES];
}

- (instancetype)initWithId:(NSUInteger)objectId fromCache:(BOOL)fromCache {
    if (self = [super init]) {
        [self setupWithObjectId:objectId fromCache:fromCache];
    }
    return self;
}

- (instancetype)initWithNumberOfColumns:(NSUInteger)numberOfColumns {
    if (self = [super init]) {
        
        NSString *name = @"";
        self.name = name;
        
        NSMutableArray *columnKeys = [[NSMutableArray alloc] initWithCapacity:numberOfColumns];
        self.columnKeys = columnKeys;
        
        NSMutableDictionary <NSString *, MADDataColumn *> *columns;
        columns = [[NSMutableDictionary <NSString *, MADDataColumn *> alloc] initWithCapacity:numberOfColumns];
        self.columns = columns;
        
        self.rowCounter = 0;
        
        NSMutableArray *sortDescriptors = [[NSMutableArray alloc] init];
        self.sortDescriptors = sortDescriptors;
        
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
    
        id key;
        key = [MTDataTablePlist keyName];
        NSString *name = [decoder decodeObjectForKey: key];
        self.name = name;
       
        key = [MTDataTablePlist keyColumnKeys];
        NSMutableArray *columnKeys =    [decoder decodeObjectForKey: key];
        self.columnKeys = columnKeys;
        
        NSMutableDictionary <NSString *, MADDataColumn *> *columns;
        key = [MTDataTablePlist keyColumns];
        columns =  [decoder decodeObjectForKey: key];
        self.columns = columns;
        
        key = [MTDataTablePlist keyRowCounter];
        NSNumber *rowCounterObject = [decoder decodeObjectForKey: key];
        self.rowCounter = rowCounterObject.unsignedIntegerValue;
        
        NSMutableArray *sortDescriptors;
        key = [MTDataTablePlist keySortDescriptors];
        sortDescriptors = [decoder decodeObjectForKey:key];
        self.sortDescriptors = sortDescriptors;
        
        NSNumber *objid = [decoder decodeObjectForKey:@"objid"];
        self.tag = objid.unsignedIntegerValue;
        
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    
    id objid;
    NSString *key;

    objid = [[NSNumber alloc] initWithUnsignedInteger: _tag];
    [encoder encodeObject:  objid forKey: @"objid"];

    key = [MTDataTablePlist keySortDescriptors];
    objid = _sortDescriptors;
    [encoder encodeObject: objid forKey: key];

    key = [MTDataTablePlist keyName];
    [encoder encodeObject: _name forKey: key];
    
    key = [MTDataTablePlist keyColumnKeys];
    objid = _columnKeys;
    [encoder encodeObject: objid forKey: key];
    
    key = [MTDataTablePlist keyColumns];
    objid = _columns;
    [encoder encodeObject: objid forKey: key];
    
    key = [MTDataTablePlist keyRowCounter];
    objid = [[NSNumber alloc] initWithUnsignedInteger: _rowCounter];
    [encoder encodeObject: objid forKey: key];
    
}

- (void)setupWithObjectId:(NSUInteger)objectId fromCache:(BOOL)fromCache {
    
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
    NSAssert(NO, @"Not implemented: %s", __PRETTY_FUNCTION__);
    return nil;
}

- (NSArray <__kindof NSDictionary *> *)objectsForGroupKeys:(NSArray *)groupKeys {
    NSAssert(NO, @"Not implemented: %s", __PRETTY_FUNCTION__);
    return nil;
}

- (NSEnumerator *)enumeratorForAllObjectsSorted {
    NSAssert(NO, @"Not implemented: %s", __PRETTY_FUNCTION__);
    return nil;
}

- (NSDictionary *)copyDataForCacheId:(NSNumber *)cacheId {
    NSAssert(NO, @"Not implemented: %s", __PRETTY_FUNCTION__);
    return nil;
}

- (NSEnumerator *)enumeratorForKeyObjectsSorted {
    NSAssert(NO, @"Not implemented: %s", __PRETTY_FUNCTION__);
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

- (BOOL)cacheWithUrl:(NSURL *)url {
    static const NSUInteger propertyListFormat = NSPropertyListBinaryFormat_v1_0;

    NSLog(@"Writing cache to url %@.", url);

    NSDictionary *plist = [self copyPlist].copy;
    
    NSError *error = NULL;
    NSData *cache = [NSPropertyListSerialization dataWithPropertyList: plist
                                                               format: propertyListFormat
                                                              options: 0
                                                                error: &error];

    NSAssert(error == NULL, @"%s %@", __PRETTY_FUNCTION__, error);

    BOOL success = NO;
    if (url) {
        NSError *errorWriting = NULL;
        success = [cache writeToURL: url
                            options: NSDataWritingAtomic |
                                     NSDataWritingFileProtectionCompleteUnlessOpen
                              error: &errorWriting];

        NSAssert(errorWriting == NULL, @"%s %@", __PRETTY_FUNCTION__, errorWriting);

    }
    
    return success;
}

- (MADDataTablePlist *)copyPlist {
    
    NSString *keyName = [MTDataTablePlist keyName];
    NSString *keyColumnKeys = [MTDataTablePlist keyColumnKeys];
    NSString *keyColumns = [MTDataTablePlist keyColumns];
    NSString *keyRowCounter = [MTDataTablePlist keyRowCounter];
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
    NSString *name = plist[[MTDataTablePlist keyName]];
    if (name == nil) {
        name = @"";
    }

    _name = name.copy;
    
    NSString * const keyColumnKeys = [MTDataTablePlist keyColumnKeys];
    
    id columnKeysArray = plist[keyColumnKeys];
    
    NSMutableArray <__kindof NSString *> *columnKeys =
                [[NSMutableArray <__kindof NSString *> alloc] initWithArray: columnKeysArray
                                                                  copyItems: YES];
    
    NSString * const keySortDescriptors = [MTDataTablePlist keySortDescriptors];
    NSArray * __weak sortDescriptorsArray = plist[keySortDescriptors];
    NSMutableArray *sortDescriptors = [[NSMutableArray alloc] initWithArray: sortDescriptorsArray
                                                                  copyItems: YES];
    self.sortDescriptors = sortDescriptors;
    
    NSString *keyColumns = [MTDataTablePlist keyColumns];
    NSDictionary * __weak plistDataColumn = plist[keyColumns];
    NSDictionary *columnsPlist = [[NSDictionary alloc] initWithDictionary: plistDataColumn
                                                                copyItems: YES];

    for (NSString *key in columnKeys) {
            NSDictionary * __weak columnPlist = columnsPlist[key];
            MADDataColumn *column = [[MADDataColumn alloc] initWithPlist: columnPlist];
            self.columns[key] = column;
    }
    self.columnKeys = columnKeys;
    
    NSString * const keyRowCounter = [MTDataTablePlist keyRowCounter];
    NSNumber * __weak rowCounterObj = plist[keyRowCounter];
    self.rowCounter = rowCounterObj.unsignedIntegerValue;
    
}

- (NSDictionary *)columnsPlist {
    
    NSMutableDictionary *columnsPlist;
    columnsPlist = [[NSMutableDictionary alloc] initWithCapacity:[self numberOfColumns]];
    for (NSString *key in self.columnKeys) {
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
                                  objects:(__unsafe_unretained id [])buffer
                                    count:(NSUInteger)len {
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
