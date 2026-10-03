//
//  RptqDatabaseCredentals.h
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_RptqDatabaseCredentals_h
#define MAD_RptqDatabaseCredentals_h

#import "RptqObject.h"

@class RptqDatabase;

NS_ASSUME_NONNULL_BEGIN

@interface RptqDatabaseCredentals : RptqObject

@end

@interface RptqDatabaseCredentals (CoreDataProperties)

@property (nullable, nonatomic, copy) NSString *driverID;
@property (nonatomic) int64_t identifier;
@property (nullable, nonatomic, copy) NSNumber *inUse;
@property (nullable, nonatomic, copy) NSString *dbname;
@property (nullable, nonatomic, copy) NSString *host;
@property (nonatomic) int64_t port;
@property (nullable, nonatomic, copy) NSString *server;
@property (nullable, nonatomic, copy) NSString *domain;
@property (nullable, nonatomic, copy) NSString *key;
@property (nullable, nonatomic, copy) NSString *url;
@property (nullable, nonatomic, retain) RptqDatabase *inDatabase;

@end

NS_ASSUME_NONNULL_END

#endif
