//
//  MysqlFetch+DataTable.h
//  MAD
//
//  Created by Michael on 1/4/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import <MADMySQL/MysqlFetch.h>
#import "MTDataTable.h"

@interface MysqlFetch (DataTable)

- (MTDataTable *)fetchWithCommand: (NSString *)s
                        dataTable: (MTDataTable * __autoreleasing *)dataTable
                     onConnection: (MysqlConnection *)connection
                            error: (NSError * __autoreleasing *)error;

- (MTDataTable *)fetchWithCommand: (NSString *)command
                        dataTable: (MTDataTable **)dataTable
                     onConnection: (MysqlConnection *)connection
                    extendedNames: (BOOL)useExtendedNames
                            error: (NSError * __autoreleasing *)error;

@end
