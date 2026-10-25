//
//  MADDataTable+Constructor.h
//  MAD
//
//  Created by Michael on 8/28/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADDataTable_Constructor_h
#define MAD_MADDataTable_Constructor_h

#import <MADFoundation/MADDataTable.h>
#import <MADFoundation/MADDataTableType.h>

@interface MADDataTable (Constructor)

	+ (instancetype)newDataTableWithDefinition:(NSDictionary *)definition;
	+ (instancetype)newDataTableForIdentifier:(NSString *)identifier;
	+ (instancetype)newDataTableOfType:(MADDataTableType)type withObjectID:(NSUInteger)objectID;

/// Same, but with the directory the table may cache into.  Pass `nil` to fall back to
/// the application's own cache directory; pass one when there is no application around
/// to ask -- a unit test, say -- so a physical table can be built without one.
	+ (instancetype)newDataTableOfType:(MADDataTableType)type
						  withObjectID:(NSUInteger)objectID
						cacheDirectory:(NSURL *)cacheDirectory;

@end

#endif
