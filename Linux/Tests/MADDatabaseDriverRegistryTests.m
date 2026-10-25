//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADDatabaseDriverRegistryTests.m
//  Linux/Tests
//
//  Ported from MADAPITests/MADDatabaseDriverRegistryTests.m: the registry that
//  lets a driver register itself instead of being imported by the constructor
//  (ROADMAP.md §5.1).  This executable links libmadapi and no driver archive, so
//  it is also the "a process that links no driver has none" check; the drivers'
//  own registration is pinned by MADDatabaseDriverDispatchTests, which links
//  libmad and through it the drivers.
//

#import "MADTestSupport.h"

#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADDatabaseDriverRegistry.h>
#import <MADAPI/MADDatabaseType.h>

// Driver stubs: the protocol's four required methods and nothing else.  Their type
// is one no real driver claims, so registering one cannot disturb another test.
@interface MADTestDatabaseDriver : MADDatabaseConnection <MADDatabaseDriver>
@end

@implementation MADTestDatabaseDriver

+ (MADDatabaseType)databaseType { return (MADDatabaseType)101; }
+ (NSString *)Identifier { return @"Test"; }
+ (Class)databaseClass { return [MADDatabase class]; }
+ (instancetype)newDatabaseConnection:(NSObject <MADConnectionsPropertiesProtocol> *)credentials { return [[self alloc] init]; }
+ (instancetype)newDatabaseConnectionWithHost:(NSString *)host database:(NSString *)database port:(NSInteger)port { return [[self alloc] init]; }

@end

// A second class claiming the same type, to make the duplicate claim raise.
@interface MADTestUsurperDatabaseDriver : MADDatabaseConnection <MADDatabaseDriver>
@end

@implementation MADTestUsurperDatabaseDriver

+ (MADDatabaseType)databaseType { return (MADDatabaseType)101; }
+ (NSString *)Identifier { return @"Usurper"; }
+ (Class)databaseClass { return [MADDatabase class]; }
+ (instancetype)newDatabaseConnection:(NSObject <MADConnectionsPropertiesProtocol> *)credentials { return [[self alloc] init]; }
+ (instancetype)newDatabaseConnectionWithHost:(NSString *)host database:(NSString *)database port:(NSInteger)port { return [[self alloc] init]; }

@end

static void testAProcessWithNoDriverLinkedHasNone(void) {
	MAD_PASS([MADDatabaseDriverRegistry driverClassForType: MADDatabaseTypeMySQL] == Nil, "a process with no driver has no MySQL");
	MAD_PASS([MADDatabaseDriverRegistry driverClassForType: MADDatabaseTypeTDS] == Nil, "a process with no driver has no TDS");
}

static void testRegistrationIsVisibleThroughTheLookup(void) {
	[MADDatabaseDriverRegistry registerDriverClass: [MADTestDatabaseDriver class]];
	MAD_PASS([MADDatabaseDriverRegistry driverClassForType: (MADDatabaseType)101] == [MADTestDatabaseDriver class], "the registered class is the one looked up");
	MAD_PASS([[MADDatabaseDriverRegistry registeredDriverClasses] containsObject: [MADTestDatabaseDriver class]], "the class is in the registered list");
}

static void testRegisteringTheSameClassTwiceIsAccepted(void) {
	[MADDatabaseDriverRegistry registerDriverClass: [MADTestDatabaseDriver class]];
	MAD_NO_THROW([MADDatabaseDriverRegistry registerDriverClass: [MADTestDatabaseDriver class]], "registering one class twice is accepted");
}

static void testASecondDriverForOneTypeRaises(void) {
	[MADDatabaseDriverRegistry registerDriverClass: [MADTestDatabaseDriver class]];
	// The claim has to fail loudly: keeping one of two drivers silently would make
	// which one runs depend on +load order.
	MAD_THROWS_NAMED([MADDatabaseDriverRegistry registerDriverClass: [MADTestUsurperDatabaseDriver class]],
					 NSInternalInconsistencyException, "two drivers for one type raise");
}

MAD_TEST_MAIN("MADDatabaseDriverRegistryTests",
	MAD_TEST(testAProcessWithNoDriverLinkedHasNone),
	MAD_TEST(testRegistrationIsVisibleThroughTheLookup),
	MAD_TEST(testRegisteringTheSameClassTwiceIsAccepted),
	MAD_TEST(testASecondDriverForOneTypeRaises));
