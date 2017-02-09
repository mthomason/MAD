//
//  MTDataTable.h
//  MAD
//
//  Created by Michael Thomason on 9/18/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MTDataTable_Factory_h
#define MAD_MTDataTable_Factory_h

#import <MAD/MADDataTablePlist.h>

typedef NS_ENUM(short, MADDataTableType) {
    MADDataTableTypeVirtual,
    MADDataTableTypePhysical,
};

@interface MTDataTable : MADDataTablePlist

    + (instancetype)newDataTableWithDefinition:(NSDictionary *)definition;
    + (instancetype)newDataTableForIdentifier:(NSString *)identifier;
    + (instancetype)newDataTableOfType:(MADDataTableType)type withObjectID:(NSUInteger)objectID;

@end

#endif
