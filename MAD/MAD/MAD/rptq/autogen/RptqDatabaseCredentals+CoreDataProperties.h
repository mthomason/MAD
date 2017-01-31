//
//  RptqDatabaseCredentals+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqDatabaseCredentals_CoreDataProperties_h
#define MAD_RptqDatabaseCredentals_CoreDataProperties_h

#import "RptqDatabaseCredentals.h"
#import <CoreData/NSFetchRequest.h>

NS_ASSUME_NONNULL_BEGIN

@interface RptqDatabaseCredentals (CoreDataProperties)

+ (NSFetchRequest<RptqDatabaseCredentals *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *driver_type;
@property (nonatomic) int64_t identifier;
@property (nullable, nonatomic, copy) NSNumber *inUse;
@property (nullable, nonatomic, copy) NSString *database;
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
