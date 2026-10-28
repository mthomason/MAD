//
//  MADPostgres.h
//  MADPostgres
//
//  Created by Michael Thomason on 10/28/26.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADPostgres_h
#define MADPostgres_h

#import <Foundation/Foundation.h>

//! Project version number for MADPostgres.
FOUNDATION_EXPORT double MADPostgresVersionNumber;

//! Project version string for MADPostgres.
FOUNDATION_EXPORT const unsigned char MADPostgresVersionString[];

#import <MADPostgres/MADDatabasePostgres.h>
#import <MADPostgres/MADDatabaseConnectionPostgres.h>
#import <MADPostgres/libpq-fe.h>
#import <MADPostgres/pg_type_d.h>

#endif /* MADPostgres_h */
