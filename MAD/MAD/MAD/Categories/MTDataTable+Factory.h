//
//  MTDataTable+Factory.h
//  MAD
//
//  Created by Michael Thomason on 9/18/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MTDataTable_Factory_h
#define MAD_MTDataTable_Factory_h

#import <MADFoundation/MTDataTable.h>

@interface MTDataTable (Factory)

    + (instancetype)newDataTableWithDefinition:(NSDictionary *)definition;
    + (instancetype)newDataTableForIdentifier:(NSString *)identifier;
    + (instancetype)newDataTableOfType:(MTDataTableType)type withObjectID:(NSUInteger)objectID;

@end

#endif
