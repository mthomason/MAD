//
//  RptqDatabaseCredentals+Extras.m
//  Reports
//
//  Created by Michael Thomason on 11/12/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqDatabaseCredentals+Extras.h"
#import "RptqDatabase+Extras.h"
#import "RptqDataHelper.h"
#import "MADDatabaseConnection+Constructor.h"
#import "madlog.h"

#import <MADAPI/MADDatabaseType.h>
#import <MADAPI/MADDatabaseConnection.h>

#import <CoreFoundation/CFNumber.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSString.h>
#import <Foundation/NSPathUtilities.h>
#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSEntityDescription.h>

@implementation RptqDatabaseCredentals (Extras)

+ (NSFetchRequest<RptqDatabaseCredentals *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RptqDatabaseCredentals"];
}

#pragma mark - Overrides

- (void)awakeFromInsert {
	[super awakeFromInsert];
	if (self.managedObjectContext.parentContext && self.identifier <= 0) {
		[[NSNotificationCenter defaultCenter] willChangeValueForKey:NSStringFromSelector(@selector(identifier))];
		self.identifier = [RptqDataHelper nextIdentifierForClass:[self class]
											managedObjectContext:self.managedObjectContext];
		[[NSNotificationCenter defaultCenter] didChangeValueForKey:NSStringFromSelector(@selector(identifier))];
	}
}

- (NSString *)database {
	return self.dbname;
}

- (NSString *)databaseSchemaName {
	NSString *result = @"";
	MADDatabaseType databaseType = [self.inDatabase databaseType];
	switch (databaseType) {
		
		case MADDatabaseTypeMySQL:
		case MADDatabaseTypeSqlite3:
			result = self.dbname.copy;
			break;
		
		case MADDatabaseTypeTDS:
			result = self.dbname.copy;
			break;

		case MADDatabaseTypeUnknown: {
			
			if ([self.driverID isEqualToString: [RptqDatabaseCredentals driverIDMySQL]]) {
				result = self.dbname.copy;
				self.inDatabase.databaseDriverTypeEnum = MADDatabaseTypeMySQL;
				
			} else if ([self.driverID isEqualToString:[RptqDatabaseCredentals driverIDTDS]]) {
				result = self.dbname.copy;
				self.inDatabase.databaseDriverTypeEnum = MADDatabaseTypeTDS;
				
			} else if ([self.driverID isEqualToString:[RptqDatabaseCredentals driverIDSqlite3]]) {
				result = self.dbname.copy;
				self.inDatabase.databaseDriverTypeEnum = MADDatabaseTypeSqlite3;
				
			}
			
			break;
		}
		default:
			result = @"unknown";
			break;
	}
	return result.stringByDeletingPathExtension.capitalizedString;
}

#pragma mark - Static

+ (instancetype)newDatabaseCredental:(NSManagedObjectContext *)objectContext {
	NSEntityDescription *ed = [NSEntityDescription entityForName: NSStringFromClass([self class])
										  inManagedObjectContext: objectContext];
	id userCredentals = [[self alloc] initWithEntity:ed insertIntoManagedObjectContext:objectContext];
	return userCredentals;
}

+ (NSArray <RptqDatabaseCredentals *> *)newDatabaseCredentals:(NSManagedObjectContext *)context {
	NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([RptqDatabaseCredentals class])];
	request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey: NSStringFromSelector(@selector(driverID))
															  ascending: YES]];
	NSError *error = nil;
	NSArray *fetchResults = [context executeFetchRequest:request error:&error];
	if (error) {
		os_log_error(GetMadLog(), "%s Error fetching RptqDatabaseCredentals: %@", __PRETTY_FUNCTION__, error);
	}
	return [[NSArray <RptqDatabaseCredentals *> alloc] initWithArray:fetchResults];
}

+ (NSString *)driverIDMySQL {
	return [MADDatabaseConnection Identifier:MADDatabaseTypeMySQL];
}

+ (NSString *)driverIDTDS {
	return [MADDatabaseConnection Identifier:MADDatabaseTypeTDS];
}

+ (NSString *)driverIDSqlite3 {
	return [MADDatabaseConnection Identifier:MADDatabaseTypeSqlite3];
}

- (id)debugQuickLookObject {
	NSMutableString *description = [[NSMutableString alloc] init];
	[description appendFormat:@"*********   RptqDatabaseCredentals  *********\n"];
	[description appendFormat:@"Identifier:             %lld\n",    self.identifier];
	[description appendFormat:@"Type:                   %@\n",      self.driverID];
	[description appendFormat:@"Host:                   %@\n",      self.host];
	[description appendFormat:@"Database:               %@\n",      self.dbname];
	[description appendFormat:@"Port:                   %lld\n",    self.port];
	[description appendFormat:@"*********   RptqDatabaseCredentals  *********"];
	return description;
}

@end
