//
//  MUIViewControllerMySqlTest.m
//  TheReportViewer
//
//  Created by Michael Thomason on 8/9/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MUIViewControllerMySqlTest.h"

#import "MysqlConnection.h"
#import "MysqlServer.h"
#import "MysqlFetch.h"
#import "MysqlFetchField.h"


/*
#include "my_global.h"
#include "my_sys.h"
#include "mysql.h"
*/
@interface MUIViewControllerMySqlTest ()

@end

@implementation MUIViewControllerMySqlTest

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    
            MYSQL *_connection = mysql_init(NULL);
            unsigned int timeout = 30;
            mysql_options(_connection, MYSQL_OPT_CONNECT_TIMEOUT, &timeout);
            
            //NSLog(@"Connecting to %@",server);
            
            if (!mysql_real_connect(_connection,
                                    "everydayapps.com",
                                    "edatest",
                                    "tEsT289ydjk",
                                    "quotationary",
                                    3306,  // default port
                                    NULL,  // default socket
                                    CLIENT_FOUND_ROWS)) {
                NSLog(@"Failed to connect: Error: %s\n", mysql_error(_connection));
            } else {
                NSLog(@"Connected to server");
            }
    
    mysql_close(_connection);
    
    MysqlServer *serv = [[MysqlServer alloc] init];

    MysqlConnection *conn = [MysqlConnection connectToServer: serv];
    
    NSMutableArray *results = nil;
    if (conn) {
        MysqlFetch *fetch = [MysqlFetch fetchWithCommand:@"SHOW TABLES;" onConnection:conn];
        if (fetch) {
            if ([[fetch fields] count] > 0) {
                MysqlFetchField *resultsTableName = [[fetch fields] objectAtIndex:0];
                results = [[NSMutableArray alloc] initWithCapacity:[[fetch results] count]];
                
                for (NSDictionary *tableName in [fetch results]) {
                    NSString *tn = [tableName objectForKey:[resultsTableName name]];
                    [results addObject: tn];
                    
                    
                    MysqlFetch *fetchCols = [MysqlFetch fetchWithCommand:[NSString stringWithFormat:@"SHOW COLUMNS IN %@;", [tableName objectForKey:[resultsTableName name]]] onConnection:conn];
                    if (fetchCols != nil) {
                        if ([[fetch fields] count] > 0) {
                            MysqlFetchField *resultsColumnName = [[[fetchCols fields] objectAtIndex:0] retain];
                            NSMutableArray *resultsBuddy = [[NSMutableArray alloc] initWithCapacity:[[fetchCols results] count]];
                            for (NSDictionary *columnName in [fetchCols results]) {
                                NSLog(@"%@", resultsColumnName);
                                NSLog(@"%@", columnName);
                                switch ([resultsColumnName fieldType]) {
                                    case MYSQL_TYPE_DECIMAL:
                                        break;
                                    case MYSQL_TYPE_SHORT:
                                        break;
                                    case MYSQL_TYPE_FLOAT:
                                        break;
                                    case MYSQL_TYPE_NULL:
                                        break;
                                    case MYSQL_TYPE_LONGLONG:
                                        break;
                                    case MYSQL_TYPE_DATE:
                                        break;
                                    case MYSQL_TYPE_DATETIME:
                                        break;
                                    case MYSQL_TYPE_NEWDATE:
                                        break;
                                    case MYSQL_TYPE_BIT:
                                        break;
                                    case MYSQL_TYPE_NEWDECIMAL:
                                        break;
                                    case MYSQL_TYPE_ENUM:
                                        break;
                                    case MYSQL_TYPE_SET:
                                        break;
                                    case MYSQL_TYPE_TINY_BLOB:
                                        break;
                                    case MYSQL_TYPE_MEDIUM_BLOB:
                                        break;
                                    case MYSQL_TYPE_LONG_BLOB:
                                        break;
                                    case MYSQL_TYPE_BLOB:
                                        break;
                                    case MYSQL_TYPE_VAR_STRING:
                                        break;
                                    case MYSQL_TYPE_STRING:
                                        break;
                                    case MYSQL_TYPE_GEOMETRY:
                                        break;
                                    case MAX_NO_FIELD_TYPES:
                                        break;
                                    case MYSQL_TYPE_TINY:
                                        break;
                                    case MYSQL_TYPE_LONG:
                                        break;
                                    case MYSQL_TYPE_TIMESTAMP:
                                        break;
                                    case MYSQL_TYPE_DOUBLE:
                                        break;
                                    case MYSQL_TYPE_INT24:
                                        break;
                                    case MYSQL_TYPE_TIME:
                                        break;
                                    case MYSQL_TYPE_YEAR:
                                        break;
                                    case MYSQL_TYPE_VARCHAR:
                                        break;
                                    default:
                                        break;
                                }
                                NSLog(@"Name:   %@", [columnName objectForKey:[resultsColumnName name]]);
                                NSLog(@"Width:  %d", [resultsColumnName width]);
                                NSLog(@"Type:   %d", [resultsColumnName fieldType]);
                            }
                            [resultsBuddy release];
                            [resultsColumnName release];
                        }
                    }
                }
                
                [results release];
            }
        }
    }
    
    [serv release];
    
    NSLog(@"Finished test.");
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
