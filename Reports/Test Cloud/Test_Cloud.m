//
//  Test_Cloud.m
//  Test Cloud
//
//  Created by Michael Thomason on 9/26/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "MACloudManager.h"

@interface Test_Cloud : XCTestCase

@end

@implementation Test_Cloud

- (void)setUp {
    [super setUp];

//    [[MACloudManager sharedManager]
    [[MACloudManager sharedManager] activate];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:MADPreferencesCloudDesired];
    [MACloudManager checkUserICloudPreferenceAndSetupIfNecessary];
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    NSLog(@"%@", [MACloudManager sharedManager].documentsDirectoryURL);
    NSLog(@"%@", [MACloudManager sharedManager].isCloudEnabled ? @"YES" : @"NO");
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
