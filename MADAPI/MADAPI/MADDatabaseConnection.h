//
//  MADDatabaseConnection.h
//  MAD
//
//  Created by Michael on 1/12/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MADDatabaseConnection_h
#define Reports_MADDatabaseConnection_h

#import <MADAPI/MADDatabaseType.h>
#import <Foundation/NSObject.h>

@protocol MADConnectionsPropertiesProtocol;

@protocol MADDatabaseConnectionConstructors <NSObject>
@optional
	+ (instancetype)newDatabaseConnection:(NSObject<MADConnectionsPropertiesProtocol> *)credentials;
@end

@protocol MADDatabaseConnectionsProperties <NSObject>
	@property (readonly, nonatomic, assign) MADDatabaseType databaseType;
	@property (readonly, nonatomic, copy) NSString *connectionString;
	@property (readonly, nonatomic, assign) BOOL requiresCredentials;
	@property (readonly, nonatomic, copy) NSString *identifier;
	@property (readonly, class) NSString *Identifier;
@end

@interface MADDatabaseConnection : NSObject <MADDatabaseConnectionConstructors, MADDatabaseConnectionsProperties, NSCopying, NSSecureCoding>

@end

#endif
