//
//  MTQuery+Extras.h
//  MAD
//
//  Created by Michael on 8/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQuery_Extras_h
#define Reports_MTQuery_Extras_h

#import <MADAPI/MTQuery.h>
#import "MADQueryType.h"

@interface MTQuery (Extras)

    @property (nonatomic, assign, readonly) MADQueryType type;

    - (instancetype)initWithQueryType:(MADQueryType)type object:(id)object;
    + (NSDictionary *)newQueryDefinitionSelect:(NSArray *)columnKeys
                                     tableName:(NSString *)tableName
                               sortDescriptors:(NSArray *)sortDescriptors;
    + (NSDictionary *)newQueryDefinitionSelect:(NSDictionary *)queryDefinationSelect
                                     withLimit:(NSUInteger)limit
                                     andOffset:(NSUInteger)offset;

@end

#endif
