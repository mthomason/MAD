//
//  MADQuery+Sqlite3.h
//  MAD
//
//  Created by Michael on 8/29/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MTQuery_Extras_h
#define Reports_MTQuery_Extras_h

#import <MADAPI/MADQuery.h>

#import <Foundation/NSSortDescriptor.h>

@interface MADQuery (Sqlite3)

- (NSString *)orderByClauseWithSortDescriptors:(NSArray <NSSortDescriptor *> *)sortDescriptors;
- (NSString *)whereClauseWithRowIds:(NSArray <NSNumber *> *)rowids;
- (NSString *)whereClauseWithParameters:(NSArray <NSDictionary *> *)whereClause;

@end

#endif
