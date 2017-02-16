//
//  MADMySQLFetchProtocol.h
//  MADMySQL
//
//  Created by Michael on 2/16/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADMySQLFetchProtocol_h
#define MADMySQLFetchProtocol_h

@class MADDataTable, MTQuery;

@protocol MADMySQLFetchProtocol
@optional
    - (MADDataTable *)dataTableForQuery:(MTQuery *)query;
    - (void)didFetchRow:(NSUInteger)row;
@end

#endif /* MADMySQLFetchProtocol_h */
