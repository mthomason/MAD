//
//  NSDatabaseSalesForce.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "NSDatabase.h"

#import "UIManagedDocumentQuery.h"

#import "SFOAuthCoordinator.h"
#import "SFRestAPI.h"

@class NSDatabaseSalesForce;

typedef void (^rsltBlk_tblNames)(NSDatabaseSalesForce *database, NSArray *tables);
typedef void (^rsltBlk_fldNames)(NSDatabaseSalesForce *database, NSArray *fields);
typedef void (^rsltBlk_loginComplete)(NSDatabaseSalesForce *database, BOOL complete);

@protocol NSDatabaseSalesForceDelegate
- (void)showWebView:(UIWebView *)view;
@end

@interface NSDatabaseSalesForce : NSDatabase
    <SFOAuthCoordinatorDelegate, SFRestDelegate> {    
@public
    NSArray *_tables;
    NSArray *_fields;
@private
    SFOAuthCoordinator *_coordinator;
    
    NSString *_loginDomain;
    NSString *_loginIdentifier;
    NSString *_loginKey;
    NSString *_loginRedirectUri;
    
    rsltBlk_tblNames resultBlockTableNames;
    rsltBlk_fldNames resultBlockFieldNames;
    rsltBlk_loginComplete resultBlockLoginComplete;
        
    NSDatabaseQueryType currentQueryType;
}

@property (assign, nonatomic) IBOutlet id <NSDatabaseSalesForceDelegate> delegate;

@property (retain, nonatomic) SFOAuthCoordinator *coordinator;

@property (retain) NSString *loginDomain;
@property (retain) NSString *loginIdentifier;
@property (retain) NSString *loginKey;
@property (retain) NSString *loginRedirectUri;

/*
@property (retain) rsltBlk_tblNames resultBlockTableNames;
@property (retain) rsltBlk_fldNames resultBlockFieldNames;
@property (retain) rsltBlk_loginComplete resultBlockLoginComplete;
*/

@property (assign) NSDatabaseQueryType currentQueryType;

- (void)login:(void (^)(NSDatabaseSalesForce *database, BOOL complete))completion;

- (void)logout;

- (void)tablesInDataseAsyc:(NSString *)database completion:(void (^)(NSDatabaseSalesForce *database, NSArray *tables))completion;
- (void)fieldsInDatabase:(NSString *)database andTable:(NSString *)table
              completion:(void (^)(NSDatabaseSalesForce *database, NSArray *fields))completion;
- (BOOL)testConnection;

@end