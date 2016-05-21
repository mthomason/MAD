//
//  NSString+RelativePath.m
//  MAD
//
//  Created by Michael Thomason on 5/21/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "NSString+RelativePath.h"
#import <Foundation/NSPathUtilities.h>

@implementation NSString (RelativePath)

- (NSString *)stringWithPathRelativeTo:(NSString *)anchorPath {

    NSArray <NSString *> *pathComponents = self.pathComponents;
    NSArray <NSString *> *anchorComponents = anchorPath.pathComponents;
    
    NSUInteger componentsInCommon = MIN(pathComponents.count, anchorComponents.count);
    NSString *pathComponent, *anchorComponent;
    
    for (NSUInteger i = 0, n = componentsInCommon; i < n; i++) {
        pathComponent = [pathComponents objectAtIndex:i];
        anchorComponent = [anchorComponents objectAtIndex:i];
        if (![pathComponent isEqualToString:anchorComponent]) {
            componentsInCommon = i;
            break;
        }
    }
    
    const NSUInteger numberOfParentComponents = anchorComponents.count - componentsInCommon;
    const NSUInteger numberOfPathComponents = pathComponents.count - componentsInCommon;
    
    NSMutableArray *relativeComponents;
    relativeComponents = [[NSMutableArray alloc] initWithCapacity:
                                          numberOfParentComponents + numberOfPathComponents];
    for (NSUInteger i = 0; i < numberOfParentComponents; i++) {
        [relativeComponents addObject:@".."];
    }
    NSArray <NSString *> *subarrayWithRange;
    subarrayWithRange = [pathComponents subarrayWithRange:
                            NSMakeRange(componentsInCommon, numberOfPathComponents)];
    [relativeComponents addObjectsFromArray: subarrayWithRange];
    return [NSString pathWithComponents:relativeComponents];
}

@end
