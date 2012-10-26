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
#import "RptqTable.h"

@class NSDatabaseSalesForce;

typedef void (^rsltBlk_tblNames)(NSDatabaseSalesForce *database, NSArray *tables);

@protocol NSDatabaseSalesForceDelegate
- (void)showWebView:(UIWebView *)view;
@end

@interface NSDatabaseSalesForce : NSDatabase
    <SFOAuthCoordinatorDelegate,
        SFRestDelegate>

@property (assign) IBOutlet id <NSDatabaseSalesForceDelegate> delegate;

- (id)initNewFileWithName: (NSString *)name
               completion: (void (^)(BOOL success))completion;

- (id)initExistingFileWithUrl: (NSURL *)url;

- (void)tablesInDataseAsyc: (NSString *)database
                completion: (void (^)(NSDatabaseSalesForce *database, NSArray *tables))completion;

- (void)runQuery: (NSString *)query
      completion: (void (^)(NSDatabaseSalesForce *database, NSArray *results))completion;

- (void)queryDatabaseForManagedObjectContext: (NSManagedObjectContext *)moc
                       withCompletionHandler: (void (^)(NSArray *results, BOOL success))completion;

- (void)logout;

@end