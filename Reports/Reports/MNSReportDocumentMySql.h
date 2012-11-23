//
//  NSDatabaseMySql.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MNSReportDocument.h"
#import <MySqlClientObjectiveC/MysqlConnection.h>
#import <MySqlClientObjectiveC/MysqlServer.h>
#import <MySqlClientObjectiveC/MysqlFetch.h>
#import <MySqlClientObjectiveC/MysqlFetchField.h>


@interface MNSReportDocumentMySql : MNSReportDocument

//@property (copy) NSString *username;
//@property (copy) NSString *password;
//@property (copy) NSString *host;
//@property (assign) NSInteger port;

/*
- (id)initWithHost:(NSString *)host port:(NSInteger)port username:(NSString *)username andPassword:(NSString *)password;
- (id)initWithOptions:(NSDictionary *)optons;

- (NSArray *)tablesFor:(NSString *)database;
- (NSSet *)fieldsFor:(NSString *)database andTable:(NSString *)table;
- (BOOL)testConnection;
*/
- (id)initNewFileWithName: (NSString *)name
               completion: (void (^)(BOOL success))completion;

- (void)tablesInDataseAsyc: (NSString *)database
                completion: (void (^)(MNSReportDocumentMySql *database, NSArray *tables))completion;

- (void)runQuery: (NSString *)query
      completion: (void (^)(MNSReportDocumentMySql *database, NSArray *results))completion;

- (void)queryDatabaseForManagedObjectContext: (NSManagedObjectContext *)moc
                       withCompletionHandler: (void (^)(NSArray *results, BOOL success))completion;

- (void)logout;


@end