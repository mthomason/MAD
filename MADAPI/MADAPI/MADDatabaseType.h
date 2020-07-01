//
//  MADDatabaseType.h
//  MAD
//
//  Created by Michael on 1/13/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MadApiMadDatabaseType_h
#define MadApiMadDatabaseType_h

typedef enum MADDatabaseType : int16_t {
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
} MADDatabaseType;

#endif /* MadApiMadDatabaseType_h */
