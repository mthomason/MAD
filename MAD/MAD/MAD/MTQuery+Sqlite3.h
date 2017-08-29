//
//  MTQuery+Sqlite3.h
//  MAD
//
//  Created by Michael on 8/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQuery_Extras_h
#define Reports_MTQuery_Extras_h

#import <MAD/MTQuery.h>

@interface MTQuery (Sqlite3)

    - (NSString *)orderByClauseWithSortDescriptors:(NSArray *)sortDescriptors;

@end

#endif
