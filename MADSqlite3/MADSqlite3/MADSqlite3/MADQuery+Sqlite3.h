//
//  MADQuery+Sqlite3.h
//  MAD
//
//  Created by Michael on 8/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQuery_Extras_h
#define Reports_MTQuery_Extras_h

#import <MADAPI/MADQuery.h>

@interface MADQuery (Sqlite3)

    - (NSString *)orderByClauseWithSortDescriptors:(NSArray *)sortDescriptors;
    - (NSString *)whereClauseWithRowIds:(NSArray *)rowids;
    - (NSString *)whereClauseWithParameters:(NSArray *)whereClause;             //For "cache" sqltie3

@end

#endif
