//
//  MADDatabaseProtocol.h
//  MAD
//
//  Created by Michael Thomason on 5/23/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADDatabaseProtocol_h
#define MADDatabaseProtocol_h

#import <Foundation/NSObject.h>

@class MADDatabaseTable, MADDatabaseField, MADDataTable, MADDatabaseConnection, MADCredential, MADQuery;

@protocol MADDatabaseDataSource <NSObject>
@required

- (void)getTables:(void (^)(BOOL success, NSError *error, NSArray <MADDatabaseTable *> *tables))completion;

- (NSArray <MADDatabaseTable *> *)getTablesFromConnection:(id)dbconn error:(NSError * __autoreleasing *)error;
- (NSArray <MADDatabaseField *> *)fieldsForTable: (NSString *)tableName connection: (id)dbconn error: (NSError * __autoreleasing *)error;

- (id)connectWithConnection:(MADDatabaseConnection *)connection credentals:(MADCredential *)credentals
			connectionError:(NSError * __autoreleasing *)error;

// These stay typed MADDataTable rather than the narrower <MADDataTableWriting>.
// MADDatabaseSQLServer and MADDatabaseSqlite3 only ever write, so their own
// implementations do narrow to the write port, but MADDatabaseMySQL's fetch reads
// column metadata back out of the table and corrects a column's type mid-row
// (MysqlFetch+DataTable.m), so the protocol cannot promise less than the full
// class until that path is redesigned.  See MADDataTable_Architecture_Report.md.
- (BOOL)executeSQL:(NSString *)sql fieldKeys:(NSArray *)fieldKeys onConnection:(id)dbconn
   intoResultTable:(MADDataTable *)dataTable withError:(NSError * __autoreleasing *)error;

- (BOOL)executeQuery:(MADQuery *)query withError:(NSError * __autoreleasing *)error;
- (BOOL)executeQuery:(MADQuery *)query withDataTable:(MADDataTable *)dataTable andError:(NSError * __autoreleasing *)error;

@optional
- (void)closeConnection:(id)process;
@end

#endif /* MADDatabaseProtocol_h */
