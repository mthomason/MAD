//
//  MADDatabaseType.h
//  MAD
//
//  Created by Michael on 1/13/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADDatabaseType_h
#define MADDatabaseType_h

typedef NS_ENUM(int16_t, MADDatabaseType) {
    MADDatabaseTypeNotSet               = -1,
    MADDatabaseTypeUnknown              = 0,
    MADDatabaseTypeDatabaseCom          = 1,
    MADDatabaseTypeMySQL                = 2,
    MADDatabaseTypeMicrosoftSqlAzure    = 3,
    MADDatabaseTypeAmazonSimpleDb       = 4,
    MADDatabaseTypeTDS                  = 5,
    MADDatabaseTypeOracle               = 6,
    MADDatabaseTypeODBC                 = 7,
    MADDatabaseTypeGooleAppEngine       = 8,
    MADDatabaseTypeNone                 = 9,
    MADDatabaseTypeSqlite3              = 10,
    MADDatabaseTypeSample1              = 11,
};

#endif /* MADDatabaseType_h */
