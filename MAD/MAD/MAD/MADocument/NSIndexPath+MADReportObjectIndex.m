//
//  NSIndexPath+MADReportObjectIndex.m
//  MAD
//
//  Created by Michael Thomason on 7/2/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "NSIndexPath+MADReportObjectIndex.h"

@implementation NSIndexPath (MADReportObjectIndex)

+ (instancetype)newIndexPathWithSection:(NSUInteger)section
                                    row:(NSUInteger)row
                                andItem:(NSUInteger)item {
    
    const NSUInteger numberOfIndexes = 3;
    NSUInteger indexes[] = {section, row, item};
    id result = [[NSIndexPath alloc] initWithIndexes: indexes
                                              length: numberOfIndexes];
    return result;

}

@end
