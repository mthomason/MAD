//
//  MADOperationCondition.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/16/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADOperationCondition_h
#define MAD_Designer_MADOperationCondition_h

#import <Foundation/NSOperation.h>

@class MADOperation, MADOperationConditionResult;

/**
 A protocol for defining conditions that must be satisfied in order for an
 operation to begin execution.
 */
@protocol MADOperationCondition <NSObject>

    /**
     The name of the condition. This is used in userInfo dictionaries of `.ConditionFailed`
        errors as the value of the `OperationConditionKey` key.
    */
    - (NSString *)name;

    /**
     Specifies whether multiple instances of the conditionalized operation may
        be executing simultaneously.
    */
    - (BOOL)isMutuallyExclusive;

    /**
     Some conditions may have the ability to satisfy the condition if another
        operation is executed first. Use this method to return an operation that
        (for example) asks for permission to perform the operation
 
     - parameter operation: The `Operation` to which the Condition has been added.
     - returns: An `NSOperation`, if a dependency should be automatically added. Otherwise, `nil`.
     - note: Only a single operation may be returned as a dependency. If you
            find that you need to return multiple operations, then you should be
            expressing that as multiple conditions. Alternatively, you could return
            a single `GroupOperation` that executes multiple operations internally.
    */
    - (NSOperation *)dependencyForOperation:(MADOperation *)operation;

    // Evaluate the condition, to see if it has been satisfied or not.
    - (MADOperationConditionResult *)evaluateForOperation:(MADOperation *)operation;

    -(void)evaluateForOperation:(MADOperation *)operation completion:(void(^)(MADOperationConditionResult *))completion;

@end

#endif /* MADOperationCondition_h */
