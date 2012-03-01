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
typedef void (^rsltBlk_fldNames)(NSDatabaseSalesForce *database, RptqTable *originTable, NSArray *fields);
typedef void (^rsltBlk_complete)(NSDatabaseSalesForce *database, BOOL complete);

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

//This is called internally.
- (void)logout;

@end