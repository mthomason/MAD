//
//  MADDriverLinkage.m
//  Linux
//
//  Which database drivers the Linux build links.  A driver registers itself from
//  +load and the constructor looks it up (MADDatabaseDriverRegistry.h,
//  ROADMAP.md §5.1), so nothing in the framework sources names a driver class any
//  more -- and a static archive is *searched*, not loaded: without a reference the
//  linker drops the driver's object file and its +load never runs.  This class is
//  that reference on Linux, and it is compiled into libmad.a (Linux/CMakeLists.txt
//  target_sources) so every executable that --whole-archives the library gets the
//  drivers.  On Apple the host links the driver frameworks instead, which the
//  dynamic loader turns into the same +load.
//
//  Adding a driver to the product means a link entry in Linux/CMakeLists.txt and a
//  line here; nothing in MAD changes.
//

#import <Foundation/NSObject.h>

#import <MADSqlite3/MADDatabaseConnectionSqlite3.h>
#import <MADMySQL/MADDatabaseConnectionMySql.h>
#import <MADTdsClient/MADDatabaseConnectionSQLServer.h>

@interface MADLinuxDatabaseDriverLinkage : NSObject
@end

@implementation MADLinuxDatabaseDriverLinkage

+ (void)load {
	// Naming the classes is the point: each is a symbol the linker has to resolve,
	// which pulls the driver's object file in, whose own +load registers it.
	(void)[MADDatabaseConnectionSqlite3 class];
	(void)[MADDatabaseConnectionMySql class];
	(void)[MADDatabaseConnectionSQLServer class];
}

@end
