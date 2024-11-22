//
//  NSString+RelativePath.m
//  MAD
//
//  Created by Michael Thomason on 5/21/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "NSString+RelativePath.h"
#import <Foundation/NSPathUtilities.h>

@implementation NSString (RelativePath)

+ (instancetype)newStringWithPath:(NSString *)basePath relativeTo:(NSString *)anchorPath {
	
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

- (NSString *)stringWithPathRelativeTo:(NSString *)anchorPath {

	NSArray <NSString *> *pathComponents = self.pathComponents;
	NSArray <NSString *> *anchorComponents = anchorPath.pathComponents;
	
	NSUInteger componentsInCommon = MIN(pathComponents.count, anchorComponents.count);
	NSString *pathComponent, *anchorComponent;
	
	for (NSUInteger i = 0, n = componentsInCommon; i < n; i++) {
		pathComponent = pathComponents[i];
		anchorComponent = anchorComponents[i];
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
