//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADDatabaseDriverRegistry.h
//  MADAPI
//
//  The seam that turns "add a database driver" from editing the constructor into
//  linking another framework (ROADMAP.md §5.1).  A driver's MADDatabaseConnection
//  subclass conforms to MADDatabaseDriver and registers itself in +load; the
//  constructor categories in MAD look a driver up by MADDatabaseType instead of
//  importing MySQL and TDS, which is the MAD <-> drivers cycle.
//
//  Registration is per-process and by link: a process that does not link a driver
//  cannot build its databases, and the constructor's NSAssert says so rather than
//  failing later with a nil.  On Apple a linked framework's +load runs by itself;
//  a static link only pulls what something references, so a static host states its
//  drivers by referring to their classes (the Linux build does that in
//  Linux/Compat/MADDriverLinkage.m, and nothing in the frameworks does).
//

#ifndef MADAPI_MADDatabaseDriverRegistry_h
#define MADAPI_MADDatabaseDriverRegistry_h

#import <Foundation/Foundation.h>

#import <MADAPI/MADDatabaseType.h>

@class MADDatabaseConnection;

@protocol MADConnectionsPropertiesProtocol;

/// Spoken by a driver's connection class: everything the constructor needs to
/// build a connection, and the database class the connection executes against.
@protocol MADDatabaseDriver <NSObject>
@required

/// The type the driver answers to.
+ (MADDatabaseType)databaseType;

/// The driver's stored identifier -- "MySQL", "TDS", "Sqlite 3".  This is what
/// RptqDatabaseCredentals.driverID holds, so it is a document-format constant.
+ (NSString *)Identifier;

/// A connection carrying the given credentials.
+ (instancetype)newDatabaseConnection:(NSObject <MADConnectionsPropertiesProtocol> *)credentials;

/// The MADDatabase subclass a connection of this driver executes against.
+ (Class)databaseClass;

/// A connection to a host and database, for the type-based constructor.  A
/// file-backed driver has no host to dial and answers an empty connection.
+ (instancetype)newDatabaseConnectionWithHost:(NSString *)host
									 database:(NSString *)database
										 port:(NSInteger)port;

@optional

/// A connection to a file; only a file-backed driver answers.
+ (instancetype)newDatabaseConnectionWithURL:(NSURL *)url;

@end

@interface MADDatabaseDriverRegistry : NSObject

/// Registers a driver for its own -databaseType.  Called from each driver's +load;
/// a second class claiming a type already taken is a programming error.
+ (void)registerDriverClass:(Class <MADDatabaseDriver>)driverClass;

/// The driver registered for a type, or Nil when nothing in this process is.
+ (Class <MADDatabaseDriver>)driverClassForType:(MADDatabaseType)databaseType;

/// Every registered driver, in no particular order.
+ (NSArray <Class <MADDatabaseDriver>> *)registeredDriverClasses;

@end

#endif
