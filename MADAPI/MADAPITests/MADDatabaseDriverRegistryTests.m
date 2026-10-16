//
//  MADDatabaseDriverRegistryTests.m
//  MADAPITests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for MADDatabaseDriverRegistry -- the seam that lets a driver register
//  itself instead of being imported by the constructor (ROADMAP.md §5.1).  This
//  bundle links no driver framework, so it is also the "a process that links no
//  driver has none" check; the drivers' own registration is pinned by the MAD
//  suite, which links them.
//

#import <XCTest/XCTest.h>

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

@interface MADDatabaseDriverRegistryTests : XCTestCase
@end

@implementation MADDatabaseDriverRegistryTests

- (void)testAProcessWithNoDriverLinkedHasNone {
	// This bundle links MADAPI and MADFoundation, no driver framework at all, and
	// that is what the constructor sees: nothing to build a MySQL database with.
	XCTAssertNil([MADDatabaseDriverRegistry driverClassForType: MADDatabaseTypeMySQL]);
	XCTAssertNil([MADDatabaseDriverRegistry driverClassForType: MADDatabaseTypeTDS]);
}

- (void)testRegistrationIsVisibleThroughTheLookup {
	[MADDatabaseDriverRegistry registerDriverClass: [MADTestDatabaseDriver class]];
	XCTAssertEqual([MADDatabaseDriverRegistry driverClassForType: (MADDatabaseType)101], [MADTestDatabaseDriver class]);
	XCTAssertTrue([[MADDatabaseDriverRegistry registeredDriverClasses] containsObject: [MADTestDatabaseDriver class]]);
}

- (void)testRegisteringTheSameClassTwiceIsAccepted {
	[MADDatabaseDriverRegistry registerDriverClass: [MADTestDatabaseDriver class]];
	XCTAssertNoThrow([MADDatabaseDriverRegistry registerDriverClass: [MADTestDatabaseDriver class]]);
}

- (void)testASecondDriverForOneTypeRaises {
	[MADDatabaseDriverRegistry registerDriverClass: [MADTestDatabaseDriver class]];
	// The claim has to fail loudly: keeping one of two drivers silently would make
	// which one runs depend on +load order.
	XCTAssertThrows([MADDatabaseDriverRegistry registerDriverClass: [MADTestUsurperDatabaseDriver class]]);
}

@end
