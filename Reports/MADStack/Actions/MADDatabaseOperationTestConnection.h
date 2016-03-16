//
//  MADDatabaseOperationTest.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/16/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADOperation.h"

@interface MADDatabaseOperationTestConnection : MADOperation

@property (nonatomic, readonly, strong) NSError *error;
@property (nonatomic, readonly, assign) bool success;

@end
