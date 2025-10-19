//
//  MysqlFetch+DataTable.h
//  MAD
//
//  Created by Michael on 1/4/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MysqlFetch_DataTable_h
#define Reports_MysqlFetch_DataTable_h

#import "MysqlFetch.h"

@interface MysqlFetch (DataTable)

	- (MADDataTable *)fetchWithCommand: (NSString *)s
							 dataTable: (MADDataTable * __autoreleasing *)dataTable
						  onConnection: (MysqlConnection *)connection
								 error: (NSError * __autoreleasing *)error;

	- (MADDataTable *)fetchWithCommand: (NSString *)command
							 dataTable: (MADDataTable **)dataTable
						  onConnection: (MysqlConnection *)connection
						 extendedNames: (BOOL)useExtendedNames
								 error: (NSError * __autoreleasing *)error;

@end

#endif
