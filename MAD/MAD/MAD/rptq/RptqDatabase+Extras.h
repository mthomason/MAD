//
//  RptqDatabase+Extras.h
//  Reports
//
//  Created by Michael Thomason on 3/14/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqDatabase_Extras_h
#define Reports_RptqDatabase_Extras_h

#import <MAD/RptqDatabase.h>

typedef NS_ENUM(NSUInteger, MNSDatabaseType) {
	MNSDatabaseTypeUnknown              = 0,
	MNSDatabaseTypeDatabaseCom          = 1,
	MNSDatabaseTypeMySQL                = 2,
    MNSDatabaseTypeMicrosoftSqlAzure    = 3,
    MNSDatabaseTypeAmazonSimpleDb       = 4,
    MNSDatabaseTypeMicrosoftSqlServer   = 5,
    MNSDatabaseTypeOracle               = 6,
    MNSDatabaseTypeODBC                 = 7,
    MNSDatabaseTypeGooleAppEngine       = 8,
    MNSDatabaseTypeNone                 = 9,
    MNSDatabaseTypeSqlite3              = 10,
    MNSDatabaseTypeSample1              = 11,
};

#define MNSDatabaseTypeReuseIds [NSArray arrayWithObjects: @"MNSDatabaseTypeSalesforceCom", @"MNSDatabaseTypeDatabaseCom", @"MNSDatabaseTypeMySQL", @"MNSDatabaseTypeMicrosoftSqlAzure", @"MNSDatabaseTypeAmazonSimpleDb", @"MNSDatabaseTypeMicrosoftSqlServer", @"MNSDatabaseTypeOracle", @"MNSDatabaseTypeODBC", @"MNSDatabaseTypeGooleAppEngine", @"MNSDatabaseTypeNone", nil]

#define MNSDatabaseTypeNames [NSArray arrayWithObjects: @"Salesforce.com", @"Database.com", @"MySQL", @"Microsoft SQL Azure", @"Amazon Simple DB", @"Oracle", @"ODBC", @"Google App Engine", NSLocalizedString(@"None", @"None"), nil]

@interface RptqDatabase (Extras)

    + (RptqDatabase *)databaseForDocument:(RptqDocument *)document
                          andConnecitonId:(NSNumber *)connectionId;

    + (instancetype)newDatabaseFactoryForManagedObjectContext:(NSManagedObjectContext *)objectContext
                                                   driverType:(NSString *)driverIdentifier
                                                 connectionId:(NSNumber *)connectionId NS_RETURNS_RETAINED;

    @property (readonly) RptqQuery *defaultQuery;

    - (RptqDatabaseSchemaTable *)getTableWithName:(NSString *)name;
    - (MNSDatabaseType)databaseType;

@end

#endif
