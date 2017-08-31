//
//  MADTests.m
//  MADTests
//
//  Created by Michael Thomason on 9/19/15.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <MADSqlite3/MTDatabaseSqlite3.h>
#import "MADocument.h"
#import <objc/runtime.h>
#import <malloc/malloc.h>
#import "MADSectionRepresentation.h"

@interface MADTests : XCTestCase

@end

@implementation MADTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInstanceSize {
    NSLog(@"size of %@: %zd", NSStringFromClass([MADSectionRepresentation class]), class_getInstanceSize([MADSectionRepresentation class]));
    id sr = [[MADSectionRepresentation alloc] init];
    NSLog(@"size of %@: %zd", NSStringFromClass([MADSectionRepresentation class]), malloc_size((__bridge const void *)sr));
}

- (void)testDocument {
    
    for (NSBundle *bundle in [NSBundle allBundles]) {
        NSLog(@"%@", bundle);
    }
    NSURL *resourceURL = [[NSBundle bundleForClass:[self class]] resourceURL];
   NSURL *url = [resourceURL URLByAppendingPathComponent:@"Music.mad"].filePathURL; // URL to file
    MADocument *document = [[MADocument alloc] initWithFileURL:url];
 
    NSLog(@"Document: %@", document);
    // Call the asynchronous method with completion block
    [document saveToURL:document.fileURL
        forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            XCTAssert(success, @"Should have been success!");
        }];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

/*- (void)testSqlite3ErrorMessage {
    const char *errorName = NULL, *errorMessage = NULL;
    mad_sqlite3Err(SQLITE_OK, &errorName, &errorMessage);
    NSString *fullMessage = [[NSString alloc] initWithFormat:@"%s: %s", errorName, errorMessage];
    NSLog(@"%@", fullMessage);
}*/

- (NSUInteger)math1:(NSUInteger)i offset:(NSUInteger)offset multiplier:(NSUInteger)multiplier {
    return i * multiplier + offset;
}

NSUInteger math2(NSUInteger i, NSUInteger offset, NSUInteger multiplier) {
    return i * multiplier + offset;
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        for (NSUInteger i = 0; i < 100000000; i++) {
            [self math1:i offset:i^2 multiplier:i*2];
        }
    }];
     
}
- (void)testPerformanceExample2 {
    
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        for (NSUInteger i = 0; i < 100000000; i++) {
            math2(i, i^2, i*2);
        }
        
        
    }];
    
}



@end
