//
//  MTQuery+Extras.h
//  MAD
//
//  Created by Michael on 8/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQuery_Extras_h
#define Reports_MTQuery_Extras_h

#import <MAD/MTQuery.h>

@interface MTQuery (Extras)

    - (instancetype)initWithQueryType:(MADQueryType)type object:(id)object;
    + (NSDictionary *)newQueryDefinitionSelect:(NSArray *)columnKeys
                                     tableName:(NSString *)tableName
                               sortDescriptors:(NSArray *)sortDescriptors;
    + (NSDictionary *)newQueryDefinitionSelect:(NSDictionary *)queryDefinationSelect
                                     withLimit:(NSUInteger)limit
                                     andOffset:(NSUInteger)offset;

@end

#endif
