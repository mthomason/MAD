//
//  MADDataTable+Constructor.h
//  MAD
//
//  Created by Michael on 8/28/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADDataTable_Constructor_h
#define MAD_MADDataTable_Constructor_h

#import <MADFoundation/MADDataTable.h>
#import <MADFoundation/MADDataTableType.h>

@interface MADDataTable (Constructor)

	+ (instancetype)newDataTableWithDefinition:(NSDictionary *)definition;
	+ (instancetype)newDataTableForIdentifier:(NSString *)identifier;
	+ (instancetype)newDataTableOfType:(MADDataTableType)type withObjectID:(NSUInteger)objectID;

@end

#endif
