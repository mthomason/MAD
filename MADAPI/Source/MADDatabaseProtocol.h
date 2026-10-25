//
//  MADDatabaseProtocol.h
//  MAD
//
//  Created by Michael Thomason on 5/23/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADDatabaseProtocol_h
#define MADDatabaseProtocol_h

#import <Foundation/NSObject.h>
#import <MADFoundation/MADDataTable.h>

@class MADDatabaseTable, MADDatabaseField, MADDataTable, MADDatabaseConnection, MADCredential, MADQuery;

@protocol MADDatabaseDataSource <NSObject>
@required

- (void)getTables:(void (^)(BOOL success, NSError *error, NSArray <MADDatabaseTable *> *tables))completion;

- (NSArray <MADDatabaseTable *> *)getTablesFromConnection:(id)dbconn error:(NSError * __autoreleasing *)error;
- (NSArray <MADDatabaseField *> *)fieldsForTable: (NSString *)tableName connection: (id)dbconn error: (NSError * __autoreleasing *)error;

- (id)connectWithConnection:(MADDatabaseConnection *)connection credentals:(MADCredential *)credentals
			connectionError:(NSError * __autoreleasing *)error;

// Every driver only ever fills the table it is handed, so the promise is the write
// port, not the concrete class.  MySQL's fetch does read the table's column metadata
// back mid-row to correct a column's type, but that metadata is declared by
// <MADDataTableWriting> itself (MADDataTable.h), so this stays the narrowest type
// all three drivers can honour.  See docs/project/MADDataTable_Architecture_Report.md.
- (BOOL)executeSQL:(NSString *)sql fieldKeys:(NSArray *)fieldKeys onConnection:(id)dbconn
   intoResultTable:(id <MADDataTableWriting>)dataTable withError:(NSError * __autoreleasing *)error;

- (BOOL)executeQuery:(MADQuery *)query withError:(NSError * __autoreleasing *)error;
- (BOOL)executeQuery:(MADQuery *)query withDataTable:(id <MADDataTableWriting>)dataTable andError:(NSError * __autoreleasing *)error;

@optional
- (void)closeConnection:(id)process;
@end

#endif /* MADDatabaseProtocol_h */
