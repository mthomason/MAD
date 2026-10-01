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
#import <MADFoundation/MADDataTable.h>

@interface MysqlFetch (DataTable)

// The table comes in by value and goes back out unchanged: every write below goes
// through the table's own -removeAllObjects / -addColumn: / -addRowWithDataForFieldKeys:
// port, so there is nothing to return through an out-parameter.  Typed to the write
// port because that is all the fetch uses.
	- (MADDataTable *)fetchWithCommand: (NSString *)s
							 dataTable: (id <MADDataTableWriting>)dataTable
						  onConnection: (MysqlConnection *)connection
								 error: (NSError * __autoreleasing *)error;

	- (MADDataTable *)fetchWithCommand: (NSString *)command
							 dataTable: (id <MADDataTableWriting>)dataTable
						  onConnection: (MysqlConnection *)connection
						 extendedNames: (BOOL)useExtendedNames
								 error: (NSError * __autoreleasing *)error;

@end

#endif
