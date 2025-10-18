//
//  MTTable.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 4/6/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADDataTable.h"

#import <Foundation/NSArray.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSFileManager.h>
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
#import "madlog.h"
#import <os/log.h>

NSString * const MADDataTableErrorDomain = @"com.everydayapps.MADDataTableErrorDomain";

@implementation MADDataTable

#pragma mark - Initializers

- (instancetype)init {
	return [self initWithId:0 fromCache:NO];
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
		
		self.name = @"";
		
		NSMutableArray <NSString *> *columnKeys = [[NSMutableArray <NSString *> alloc] initWithCapacity:numberOfColumns];
		self.columnKeys = columnKeys;
		
		NSMutableDictionary <NSString *, MADDataColumn *> *columns = [[NSMutableDictionary <NSString *, MADDataColumn *> alloc] initWithCapacity:numberOfColumns];
		self.columns = columns;
		
		self.rowCounter = 0;
		
		NSMutableArray <NSSortDescriptor *> *sortDescriptors = [[NSMutableArray alloc] init];
		self.sortDescriptors = sortDescriptors;
		
	}
	return self;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)decoder {
	if (self = [super init]) {
	
		NSString *name = [decoder decodeObjectForKey: [MADDataTable keyName]];
		self.name = name;

		NSMutableArray <NSString *> *columnKeys =
			[decoder decodeObjectForKey: [MADDataTable keyColumnKeys]];
		self.columnKeys = columnKeys;
		
		NSMutableDictionary <NSString *, MADDataColumn *> *columns =
			[decoder decodeObjectForKey: [MADDataTable keyColumns]];
		self.columns = columns;
		
		NSNumber *rowCounterObject = [decoder decodeObjectForKey: [MADDataTable keyRowCounter]];
		self.rowCounter = rowCounterObject.unsignedIntegerValue;
		
		NSMutableArray *sortDescriptors = [decoder decodeObjectForKey:[MADDataTable keySortDescriptors]];
		self.sortDescriptors = sortDescriptors;
		
		NSNumber *objid = [decoder decodeObjectForKey:@"objid"];
		self.tag = objid.unsignedIntegerValue;
		
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	NSNumber *tag = [[NSNumber alloc] initWithUnsignedInteger: _tag];
	NSNumber *rowCounter = [[NSNumber alloc] initWithUnsignedInteger: _rowCounter];
	[encoder encodeObject:  tag forKey: @"objid"];
	[encoder encodeObject: _sortDescriptors forKey: [MADDataTable keySortDescriptors]];
	[encoder encodeObject: _name forKey: [MADDataTable keyName]];
	[encoder encodeObject: _columnKeys forKey: [MADDataTable keyColumnKeys]];
	[encoder encodeObject: _columns forKey: [MADDataTable keyColumns]];
	[encoder encodeObject: rowCounter forKey: [MADDataTable keyRowCounter]];
}

#pragma mark - Setup

- (void)setupWithObjectId:(NSUInteger)objectId fromCache:(BOOL)fromCache {
	
	self.name = @"";
	
	NSMutableArray <NSString *> *columnKeys = [[NSMutableArray alloc] init];
	self.columnKeys = columnKeys;
	
	NSMutableArray <NSSortDescriptor *> *sortDescriptors = [[NSMutableArray alloc] init];
	self.sortDescriptors = sortDescriptors;
	
	self.rowCounter = 0;
	self.tag = objectId;

	NSMutableDictionary <__kindof NSString *, __kindof MADDataColumn *> *columns;
	columns = [[NSMutableDictionary <__kindof NSString *, __kindof MADDataColumn *> alloc] init];
	self.columns = columns;
	
}

#pragma mark - Caching

- (BOOL)loadFromCacheWithUrl:(nonnull NSURL *)url error:(NSError * _Nullable __autoreleasing * _Nullable)outError {
	if (!url) {
		NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"URL is nil.",
								   NSURLErrorKey: url ?: [NSNull null]};
		@throw [NSError errorWithDomain:NSStringFromClass([MADDataTable class])
								   code:-213
							   userInfo:userInfo];
	}
		
	NSString *path = url.path.copy;
	BOOL isFileDirectory = NO;
	BOOL fileExistAtPath = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isFileDirectory];
	if (!path || !fileExistAtPath) {
		NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"File does not exist.",
								   NSURLErrorKey: url ?: [NSNull null]};
		*outError = [NSError errorWithDomain:NSStringFromClass([MADDataTable class])
										code:-215
									userInfo:userInfo];
		return NO;
	}
	
	NSInputStream *inputStream = [[NSInputStream alloc] initWithFileAtPath: path];
	[inputStream open];
	if (inputStream.streamStatus == NSStreamStatusError) {
		if (outError) {
			*outError = [inputStream.streamError copy];
		}
		os_log_error(GetFoundationLog(), "Stream error while opening file at path: %@", path);
		return NO;
	}
	
	NSError *plistError = nil;
	NSDictionary *plist = [NSPropertyListSerialization propertyListWithStream: inputStream
																	  options: NSPropertyListImmutable
																	   format: nil
																		error: &plistError];
	[inputStream close];
	if (plistError || ![plist isKindOfClass:[NSDictionary class]]) {
		if (outError) {
			*outError = [plistError copy] ?: [NSError errorWithDomain:MADDataTableErrorDomain
																 code:-2
															 userInfo:@{NSLocalizedDescriptionKey: @"Failed to deserialize property list."}];
		}
		os_log_error(GetFoundationLog(), "Failed to deserialize plist from cache at path: %@, error: %@", path, plistError);
		return NO;
	}
	
	if (!plist) return NO;
	
	NSError *loadPlistError = nil;
	BOOL loadPlist = [self loadWithPlist:plist error:&loadPlistError];
	if (loadPlistError != nil) {
		*outError = [loadPlistError copy];
		os_log_error(GetFoundationLog(), "Plist: %@ Error: %@", plist, loadPlistError);
	}
	return loadPlist;
}

- (BOOL)cacheWithUrl:(nonnull NSURL *)url error:(NSError * _Nullable __autoreleasing * _Nullable)outError {
	if (!url) {
		NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"URL is nil.",
								   NSURLErrorKey: url ?: [NSNull null]};
		@throw [NSError errorWithDomain:NSStringFromClass([MADDataTable class])
								   code:-22
							   userInfo:userInfo];
	}
	
	NSDictionary *plist = [self copyPlist];
	NSError *error = NULL;
	NSData *cache = [NSPropertyListSerialization dataWithPropertyList: plist
															   format: NSPropertyListBinaryFormat_v1_0
															  options: 0
																error: &error];

	NSAssert(error == NULL, @"%s %@", __PRETTY_FUNCTION__, error);

	NSError *errorWriting = NULL;

	BOOL success = [cache writeToURL: url
							 options: (NSDataWritingAtomic | NSDataWritingFileProtectionCompleteUnlessOpen)
							   error: &errorWriting];

	NSAssert((!success || errorWriting == NULL), @"%s %@", __PRETTY_FUNCTION__, errorWriting);

	return success;
}

#pragma mark - Data Management

- (NSDictionary *)copyPlist {

	NSNumber *rowCounter = [[NSNumber alloc] initWithUnsignedInteger: _rowCounter];
	NSArray <NSString *> *columnKeys = [self.columnKeys copy];
	NSDictionary *columnsPlist = [self columnsPlist];
	NSString *name = [self.name copy];
	
	NSDictionary *results = @{
		[MADDataTable keyName]: name,
		[MADDataTable keyColumnKeys]: columnKeys,
		[MADDataTable keyColumns]: columnsPlist,
		[MADDataTable keyRowCounter]: rowCounter
	};
	
	return results;
}

- (BOOL)loadWithPlist:(nonnull NSDictionary *)plist error:(NSError * _Nullable __autoreleasing * _Nullable)outError {
	if (![plist isKindOfClass:[NSDictionary class]]) {
		if (outError) {
			*outError = [NSError errorWithDomain:MADDataTableErrorDomain
											code:-4
										userInfo:@{NSLocalizedDescriptionKey: @"Invalid plist format."}];
		}
		return NO;
	}
	
	NSString *name = plist[[MADDataTable keyName]] ?: @"";
	self.name = [name copy];
	
	NSArray *columnKeysArray = plist[[MADDataTable keyColumnKeys]];
	if (![columnKeysArray isKindOfClass:[NSArray class]]) {
		if (outError) {
			*outError = [NSError errorWithDomain:MADDataTableErrorDomain
											code:-5
										userInfo:@{NSLocalizedDescriptionKey: @"Missing or invalid column keys."}];
		}
		return NO;
	}
	NSMutableArray <__kindof NSString *> *columnKeys =
				[[NSMutableArray <__kindof NSString *> alloc] initWithArray: columnKeysArray
																  copyItems: YES];
	
	NSArray *sortDescriptorsArray = plist[[MADDataTable keySortDescriptors]];
	if ([sortDescriptorsArray isKindOfClass:[NSArray class]]) {
		NSMutableArray *sortDescriptors = [[NSMutableArray alloc] initWithArray: sortDescriptorsArray
																	  copyItems: YES];
		self.sortDescriptors = sortDescriptors;
	} else {
		NSMutableArray *a = [[NSMutableArray alloc] init];
		self.sortDescriptors = a;
	}

	
	NSDictionary *plistDataColumn = [plist objectForKey:NSStringFromSelector(@selector(columns))];
	if (![plistDataColumn isKindOfClass:[NSDictionary class]]) {
		if (outError) {
			*outError = [NSError errorWithDomain:MADDataTableErrorDomain
											code:-6
										userInfo:@{NSLocalizedDescriptionKey: @"Missing or invalid column data."}];
		}
		return NO;
	}
	NSDictionary *columnsPlist = [[NSDictionary alloc] initWithDictionary: plistDataColumn
																copyItems: YES];
	
	for (NSString *key in columnKeys) {
		NSDictionary *columnPlist = columnsPlist[key];
		if (![columnPlist isKindOfClass:[NSDictionary class]]) {
			os_log_error(GetFoundationLog(), "Column plist for key %@ is invalid or missing", key);
			continue;
		}
		MADDataColumn *column = [[MADDataColumn alloc] initWithPlist: columnPlist];
		if (column) {
			self.columns[key] = column;
		} else {
			os_log_error(GetFoundationLog(), "Failed to initialize column from plist for key %@", key);
		}
	}
	self.columnKeys = columnKeys;
	
	NSNumber *rowCounterObj = plist[[MADDataTable keyRowCounter]];
	self.rowCounter = rowCounterObj.unsignedIntegerValue;

	return YES;
}

- (NSDictionary *)columnsPlist {
	if (!self.columnKeys || !self.columns) {
		return @{};
	}
	NSMutableDictionary *columnsPlist = [NSMutableDictionary dictionaryWithCapacity:[self numberOfColumns]];
	for (NSString *key in self.columnKeys) {
		MADDataColumn *dataColumn = self.columns[key];
		if (dataColumn) {
			columnsPlist[key] = [dataColumn copyPlist];
		} else {
			NSLog(@"Warning: Missing column for key %@", key);
		}
	}
	return [columnsPlist copy];
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

- (NSDictionary *)dataForRow:(NSUInteger)cacheId error:(NSError * __autoreleasing *)error {
	NSAssert(NO, @"Not implemented: %s", __PRETTY_FUNCTION__);
	return nil;
}

- (NSEnumerator *)enumeratorForKeyObjectsSorted {
	NSAssert(NO, @"Not implemented: %s", __PRETTY_FUNCTION__);
	return nil;
}

- (NSString *)newFilenameMDCache {
	NSString *tag = [[NSString alloc] initWithFormat:@"%lu", (unsigned long)self.tag];
	NSString *result = [tag stringByAppendingPathExtension:@"mdcache"];
	return result;
}

- (void)addColumn:(MADDataColumn *)column {}
- (bool)addRow:(NSArray *)row error:(NSError * __autoreleasing *)error { return true; }
- (void)addRowWithDataForFieldKeys:(NSDictionary *)row {}
- (void)sortUsingDescriptors:(NSArray *)sortDescriptors {}
- (void)removeAllObjects {}
- (id)objectAtRow:(NSUInteger)row column:(NSUInteger)column { return nil; }
- (id)objectAtRow:(NSUInteger)row { return nil; }
- (NSEnumerator *)columnsEnumerator { return nil; }
- (NSEnumerator *)objectEnumerator { return nil; }
- (void)beginBulkInsert {}
- (void)endBulkInsert {}

- (NSArray *)allObjects {
	NSArray *all = [[NSArray alloc] init];
	return all;
}

- (NSArray *)objectAtRow:(NSUInteger)row limit:(NSUInteger)limit { return @[]; }
- (NSUInteger)count { return 0; }
- (NSUInteger)numberOfColumns { return 0; }
- (NSUInteger)numberOfRows { return 0; }
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
								  objects:(__unsafe_unretained id [])buffer
									count:(NSUInteger)len {
	return 0;
}

+ (NSString *)keyName { return NSStringFromSelector(@selector(name)); }
+ (NSString *)keyColumnKeys { return NSStringFromSelector(@selector(columnKeys)); }
+ (NSString *)keyColumns { return NSStringFromSelector(@selector(columns)); }
+ (NSString *)keyRowCounter { return NSStringFromSelector(@selector(rowCounter)); }
+ (NSString *)keySortDescriptors { return NSStringFromSelector(@selector(sortDescriptors)); }

@end
