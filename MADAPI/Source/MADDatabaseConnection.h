//
//  MADDatabaseConnection.h
//  MAD
//
//  Created by Michael on 1/12/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
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

/*
 * A concrete driver keeps the standard connection properties in these protected
 * ivars: it sets them in its designated initializer and reads them back from the
 * accessors it overrides (the base class's accessors are abstract).  The base
 * class's -copyWithZone: and coding methods carry the ivars, so a driver whose
 * whole state is these properties needs no copying or coding code.  A driver
 * with additional parameters (a host, a port, a file URL) overrides
 * -copyWithZone: and the coding methods, calls super, and carries its own state.
 */
@interface MADDatabaseConnection : NSObject <MADDatabaseConnectionConstructors, MADDatabaseConnectionsProperties, NSCopying, NSSecureCoding>
{
@protected
	MADDatabaseType _databaseType;
	BOOL _requiresCredentials;
	NSString *_connectionString;
	NSString *_identifier;
}

@end

#endif
