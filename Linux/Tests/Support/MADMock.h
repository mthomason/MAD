//
//  MADMock.h
//  Linux/Tests/Support
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  The portable half of MAD/MADTests/MADMock: +mockDatabase, the MADDatabase
//  subclass whose only override is queryKey:table: ("<table>.<field>"), which
//  is what the SQL generators hand around.  The Xcode MADMock.m also carries
//  +createMockDocument, and that is the piece that keeps the file on Apple: it
//  builds its document through Core Data (NSManagedObjectContext imported
//  wholesale).  The ported suites build their document through RptqStoreContext
//  instead, exactly as the existing Linux suites do, so no document fixture is
//  needed here.
//
//  One class per test executable (each ported suite is its own translation
//  unit), so this lives in a header rather than a file the recipe would have to
//  link a second time.
//

#ifndef MADMock_h
#define MADMock_h

#import <MADAPI/MADDatabase.h>

@interface MADMockDatabase : MADDatabase
@end

@implementation MADMockDatabase

- (NSString *)queryKey:(NSString *)fieldName table:(NSString *)tableName {
	return [[[NSString alloc] initWithFormat:@"%@.%@", tableName, fieldName] autorelease];
}

@end

@interface MADMock : NSObject

+ (MADDatabase *)mockDatabase;

@end

@implementation MADMock

+ (MADDatabase *)mockDatabase {
	return [[[MADMockDatabase alloc] init] autorelease];
}

@end

#endif /* MADMock_h */
