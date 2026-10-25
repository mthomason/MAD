//
//  MADPathUtilities.m
//  MAD
//
//  Created by Michael Thomason on 5/21/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADPathUtilities.h"
#import <Foundation/NSPathUtilities.h>

@implementation MADPathUtilities

+ (NSString *)stringWithPath:(NSString *)basePath relativeTo:(NSString *)anchorPath {

	NSString *pathComponent, *anchorComponent;
	NSArray <NSString *> *pathComponents = basePath.pathComponents,
	*anchorComponents = anchorPath.pathComponents;

	NSUInteger componentsInCommon = MIN(pathComponents.count, anchorComponents.count);

	for (NSUInteger i = 0, n = componentsInCommon; i < n; i++) {
		pathComponent = pathComponents[i];
		anchorComponent = anchorComponents[i];
		if (![pathComponent isEqualToString:anchorComponent]) {
			componentsInCommon = i;
			break;
		}
	}

	NSUInteger numberOfParentComponents = anchorComponents.count - componentsInCommon;
	NSUInteger numberOfPathComponents = pathComponents.count - componentsInCommon;

	NSMutableArray *relativeComponents = [[NSMutableArray alloc] initWithCapacity: numberOfParentComponents + numberOfPathComponents];
	for (NSUInteger i = 0; i < numberOfParentComponents; i++) {
		[relativeComponents addObject:@".."];
	}
	NSArray <NSString *> *subarrayWithRange = [pathComponents subarrayWithRange: NSMakeRange(componentsInCommon, numberOfPathComponents)];
	[relativeComponents addObjectsFromArray: subarrayWithRange];
	return [NSString pathWithComponents:relativeComponents];
}

@end
