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

    [[MACloudManager sharedManager] activate];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:MADPreferencesCloudDesired];
    [MACloudManager checkUserICloudPreferenceAndSetupIfNecessary:^{

        [super setUp];
        
    }];
    
}

- (void)tearDown {
    [super tearDown];
}

- (void)testExample {
    NSLog(@"%@", [MACloudManager sharedManager].documentsDirectoryURL);
    NSLog(@"%@", [MACloudManager sharedManager].isCloudEnabled ? @"YES" : @"NO");
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

@end
