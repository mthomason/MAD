//
//  RptqDatabase+Extras.h
//  Reports
//
//  Created by Michael Thomason on 3/14/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_RptqDatabase_Extras_h
#define Reports_RptqDatabase_Extras_h

#import <MADAPI/MADDatabaseType.h>

#import <MAD/RptqDatabase.h>
#import <MAD/RptqStoreContext.h>

#define MADDatabaseTypeReuseIds [NSArray arrayWithObjects: @"MADDatabaseTypeSalesforceCom", @"MADDatabaseTypeDatabaseCom", @"MADDatabaseTypeMySQL", @"MADDatabaseTypeMicrosoftSqlAzure", @"MADDatabaseTypeAmazonSimpleDb", @"MADDatabaseTypeMicrosoftSqlServer", @"MADDatabaseTypeOracle", @"MADDatabaseTypeODBC", @"MADDatabaseTypeGooleAppEngine", @"MADDatabaseTypeNone", nil]

#define MADDatabaseTypeNames [NSArray arrayWithObjects: @"Salesforce.com", @"Database.com", @"MySQL", @"Microsoft SQL Azure", @"Amazon Simple DB", @"Microsoft SQL Server", @"Oracle", @"ODBC", @"Google App Engine", NSLocalizedString(@"None", @"None"), nil]

@interface RptqDatabase (Extras)

	+ (NSString *)keyOwnedByUserDriverID;
	+ (NSString *)keyOwnedByUserDatabaseName;
	+ (NSString *)keyDatabaseDriverType;
	+ (RptqDatabase *)databaseForDocument:(RptqDocument *)document
						  andConnecitonId:(int64_t)connectionId;

	+ (instancetype)newDatabaseFactoryForManagedObjectContext:(RptqStoreContext *)objectContext
												   driverType:(NSString *)driverIdentifier
												 connectionId:(int64_t)connectionId;

	@property (readonly) RptqQuery *defaultQuery;

	- (RptqDatabaseSchemaTable *)getTableWithName:(NSString *)name;
	- (MADDatabaseType)databaseType;

@end

#endif
