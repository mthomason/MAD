//
//  MADOperationTestResults.h
//  MAD
//
//  Created by Michael on 8/17/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/NSObject.h>

#ifndef MADOperationTestResults_h
#define MADOperationTestResults_h

@protocol MADOperationTestResults <NSObject>

    @property (nonatomic, readonly, strong) NSError *error;
    @property (nonatomic, readonly, assign, getter=isSuccess) BOOL success;

@end

#endif /* MADOperationTestResults_h */
