//
//  MADDatabaseProtocol.h
//  MAD
//
//  Created by Michael Thomason on 5/23/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADDatabaseProtocol_h
#define MADDatabaseProtocol_h

#import <Foundation/NSObject.h>

@class MADDatabaseTable, MADDatabaseField, MADDataTable, MADDatabaseConnection, MADCredential, MADQuery;

@protocol MADDatabaseDataSource <NSObject>
  @required

    - (void)getTables:(void (^)(BOOL success, NSError *error, NSArray <MADDatabaseTable *> *tables))completion;

    - (NSArray <MADDatabaseTable *> *)getTablesFromConnection:(id)dbconn
                                                        error:(NSError * __autoreleasing *)error;
    - (NSArray <MADDatabaseField *> *)fieldsForTable: (NSString *)tableName
                                          connection: (id)dbconn
                                               error: (NSError * __autoreleasing *)error;

    - (id)connectWithConnection:(MADDatabaseConnection *)connection
                     credentals:(MADCredential *)credentals
                connectionError:(NSError * __autoreleasing *)error;

    - (BOOL)executeSQL:(NSString *)sql
             fieldKeys:(NSArray *)fieldKeys
          onConnection:(id)dbconn
       intoResultTable:(MADDataTable *)dataTable
             withError:(NSError * __autoreleasing *)error;

    - (BOOL)executeQuery:(MADQuery *)query
               withError:(NSError * __autoreleasing *)error;
    - (BOOL)executeQuery:(MADQuery *)query
           withDataTable:(MADDataTable *)dataTable
                andError:(NSError * __autoreleasing *)error;

    - (NSString *)sqlSampleDataForField:(NSString *)fieldName
                               andTable:(NSString *)tableName;

  @optional
    - (void)closeConnection:(id)process;
@end


@protocol MADDatabaseDelegate <NSObject>
  @required
  @optional
@end

@protocol MADDatabaseDBProtocol <NSObject>
  @required
  @optional
@end

#endif /* MADDatabaseProtocol_h */
