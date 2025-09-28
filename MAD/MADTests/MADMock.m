//
//  MADMock.m
//  MADTests
//
//  Created by Michael on 9/26/25.
//  Copyright © 2025 Everyday Apps LLC. All rights reserved.
//

#import "MADMock.h"
#import "RptqDocument.h"
#import "RptqDocument+Extras.h"
#import <MADAPI/MADDatabase.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface MADMockDatabase : MADDatabase
@end

@implementation MADMockDatabase
- (NSString *)queryKey:(NSString *)fieldName table:(NSString *)tableName {
	return [NSString stringWithFormat:@"%@.%@", tableName, fieldName];
}
@end

@implementation MADMock

+ (NSManagedObjectContext *)createMockManagedObjectContext {
	// This helper sets up an in-memory Core Data stack, which is a standard
	// practice for testing Core Data-related logic without hitting the disk.
	NSBundle *bundle = [NSBundle bundleForClass:[RptqDocument class]];
	NSURL *modelURL = [[bundle resourceURL] URLByAppendingPathComponent:@"Reports.momd"];
	NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
	
	NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
	[coordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:NULL];
	
	NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
	context.persistentStoreCoordinator = coordinator;
	
	return context;
}

+ (RptqDocument *)createMockDocument {
	NSManagedObjectContext *context = [self createMockManagedObjectContext];
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"RptqDocument" inManagedObjectContext:context];
	RptqDocument *document = (RptqDocument *)[[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
	
	// To allow methods like `addQuery` and `addSection` to work, the document
	// needs a valid managedObjectContext. We can set this private property
	// using Key-Value Coding for the purpose of this test.
	[document setValue:context forKey:@"managedObjectContext"];
	
	return document;
}

+ (MADDatabase *)mockDatabase {
	// Return an instance of our simple, stable mock database class.
	return [[MADMockDatabase alloc] init];
}

@end

NS_ASSUME_NONNULL_END
