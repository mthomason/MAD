//
//  MADElementDropPointMigrationPolicy.m
//  MAD Designer
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADElementDropPointMigrationPolicy.h"
#import <UIKit/UIGeometry.h>

@implementation MADElementDropPointMigrationPolicy

- (NSValue *)migrateValueFromDropPointX:(NSNumber *)dropPointX dropPointY:(NSNumber *)dropPointY {
    CGPoint origin = CGPointMake(dropPointX.floatValue, dropPointY.floatValue);
    return [NSValue valueWithCGPoint:origin];
}

@end
