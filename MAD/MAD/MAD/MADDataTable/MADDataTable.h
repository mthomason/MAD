//
//  MADDataTable.h
//  MAD
//
//  Created by Michael Thomason on 9/18/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADDataTable_Factory_h
#define MAD_MADDataTable_Factory_h

#import <MAD/MADDataTablePlist.h>
#import <MADFoundation/MADDataTableType.h>

@interface MADDataTable : MADDataTablePlist

    + (instancetype)newDataTableWithDefinition:(NSDictionary *)definition;
    + (instancetype)newDataTableForIdentifier:(NSString *)identifier;
    + (instancetype)newDataTableOfType:(MADDataTableType)type withObjectID:(NSUInteger)objectID;

@end

#endif
