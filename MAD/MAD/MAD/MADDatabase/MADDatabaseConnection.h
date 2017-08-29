//
//  MADDatabaseConnection.h
//  MAD
//
//  Created by Michael on 1/12/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADDatabaseConnection_h
#define Reports_MADDatabaseConnection_h

#import <Foundation/NSObject.h>
#import "MADDatabaseType.h"

@protocol MADDatabaseConnectionsPropertiesCredentals;

@protocol MADDatabaseConnectionConstructors <NSObject>
    + (instancetype)newDatabaseConnectionWithCredentals:(NSObject <MADDatabaseConnectionsPropertiesCredentals> *)credentals;
@end

@protocol MADDatabaseConnectionsProperties <NSObject>
    @property (readonly, nonatomic, assign) MADDatabaseType databaseType;
    @property (readonly, nonatomic, copy) NSString *connectionString;
    @property (readonly, nonatomic, assign) BOOL requiresCredientals;
    @property (readonly, nonatomic, copy) NSString *identifier;
    @property (readonly, class) NSString *Identifier;
@end

@interface MADDatabaseConnection : NSObject
    <MADDatabaseConnectionConstructors, MADDatabaseConnectionsProperties, NSCopying>

    + (instancetype)newDatabaseConnectionWithType:(MADDatabaseType)databaseType
                                             host:(NSString *)host
                                         database:(NSString *)database
                                             port:(NSInteger)port;

    + (instancetype)newDatabaseConnectionForUrl:(NSURL *)url;

    + (NSString *)Identifier:(MADDatabaseType)databaseType;

@end

#endif
