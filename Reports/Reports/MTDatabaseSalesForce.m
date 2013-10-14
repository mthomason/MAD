//
//  MNSDatabaseSalesForce.m
//  Reports
//
//  Created by Michael Thomason on 11/10/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTDatabaseSalesForce.h"

typedef void (^rsltBlk_tblNames)(MTDatabaseSalesForce *database, NSArray *tables);
typedef void (^rsltBlkGetTables)(BOOL success, NSError *error, NSArray *tables);
typedef void (^rsltBlkGetFields)(BOOL success, NSError *error, NSArray *fields);
typedef void (^rsltBlk_fldNames)(MTDatabaseSalesForce *database, RptqDatabaseSchemaTable *originTable, NSArray *fields);
typedef void (^rsltBlk_results)(MTDatabaseSalesForce *database, RptqQueryCache *results);
typedef void (^rsltBlk_complete)(MTDatabaseSalesForce *database, BOOL complete);

@interface MTDatabaseSalesForce ()

@property (nonatomic, retain) SFOAuthCoordinator *coordinator;

@property (copy) NSString *loginDomain;
@property (copy) NSString *loginIdentifier;
@property (copy) NSString *loginKey;
@property (copy) NSString *loginRedirectUri;
@property (copy) rsltBlk_complete resultBlockComplete;
@property (copy) rsltBlk_tblNames resultBlockTableNames;
@property (copy) rsltBlk_results resultBlockResults;
@property (copy) rsltBlk_fldNames resultBlockFieldNames;
@property (copy) rsltBlkGetTables resultBlockGetTables;
@property (copy) rsltBlkGetFields resultBlockGetFields;
@property (assign) MTDatabaseQueryType currentQueryType;

@end

@implementation MTDatabaseSalesForce

#pragma mark - Public Actions

- (NSString *)getSqlForQuery:(RptqQuery *)query {
#warning Not implemented.
    return @"";
}

- (void)sampleDataForSchemaField:(RptqDatabaseSchemaField *)schemaField
                      completion: (void (^)(BOOL success, NSError *error, NSArray *resultStrings))completion {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

- (void)getTables: (void (^)(BOOL success, NSError *error, NSArray *tables))completion {
    [self setCurrentQueryType: MTDatabaseQueryTypeGetTables];
    
    [self setResultBlockGetTables: completion];
    
    SFRestRequest *request = [[SFRestAPI sharedInstance] requestForDescribeGlobal];
    [[SFRestAPI sharedInstance] send:request delegate:self];
}

- (void)getFieldsForTableSchema: (RptqDatabaseSchemaTable *)table
               completion: (void (^)(BOOL success, NSError *error, NSArray *fields))completion {

    [self setCurrentQueryType: MTDatabaseQueryTypeGetFields];
    
    [self setResultBlockGetFields: completion];
    
    SFRestRequest *request = [[SFRestAPI sharedInstance] requestForDescribeWithObjectType: [table name]];
    [[SFRestAPI sharedInstance] send:request delegate:self];

}

- (void)cacheReportQueryForDocument:(RptqDocument *)document
      completion: (void (^)(MTDatabase *database, RptqQueryCache *cache))completion {
    
    [self setCurrentQueryType: MTDatabaseQueryTypeGetResults];
    
    self.resultBlockResults = completion;
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *rquery = [[database hasQueries] anyObject];

    SFRestRequest *request = [[SFRestAPI sharedInstance] requestForQuery: rquery];
    [[SFRestAPI sharedInstance] send:request delegate:self];
    
    
}

#pragma mark - Private Methods

- (void)login:(void (^)(MTDatabaseSalesForce *database, BOOL complete))completion {
    //kickoff authentication
    self.resultBlockComplete = completion;
    //NSLog(@"self->resultBlockLoginComplete: %@", resultBlockLoginComplete);
    [[self coordinator] authenticate];
}


- (void)logout {
    [[self coordinator] revokeAuthentication];
}

- (BOOL)testConnection {
    [self setCurrentQueryType: MTDatabaseQueryTypeVerify];
    
    __block BOOL result = NO;
    
    return result;
}

#pragma mark - SFRestAPIDelegate

- (void)request:(SFRestRequest *)request didLoadResponse:(id)jsonResponse {
    switch ([self currentQueryType]) {
        case MTDatabaseQueryTypeGetTables: {
            NSDictionary *response = [jsonResponse retain];
            [response enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                if ([key isEqualToString:@"sobjects"]) {
                    NSArray *sfTables = obj;
                    NSMutableArray *resultTables = [[NSMutableArray alloc] initWithCapacity:[sfTables count]];
                    for (id object in sfTables) {
                        MTDatabaseTable *databaseTable = [[MTDatabaseTable alloc] init];
                        [databaseTable setLabel:        [object objectForKey: @"label"]];
                        [databaseTable setLabelPlural:  [object objectForKey: @"labelPlural"]];
                        [databaseTable setName:         [object objectForKey: @"name"]];
                        [databaseTable setQueryable:    [[object objectForKey: @"queryable"] boolValue]];
                        [resultTables addObject:databaseTable];
                        [databaseTable release];
                    }
                    self.resultBlockGetTables(YES, nil, resultTables);
                    [resultTables release];
                }
                
            }];
            [response release];
            
            break;
        }
        case MTDatabaseQueryTypeGetResults: {
            NSDictionary *response = [jsonResponse retain];
            [response enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                //NSLog(@"Keys '%@' and fields '%@.'", key, obj);
#warning FIXME: Not yet implemented
            }];
            break;
        }
        case MTDatabaseQueryTypeGetFields: {
            [jsonResponse enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                if ([key isEqualToString:@"fields"]) {
                    NSArray *sfFields = obj;
                    NSMutableArray *resultFields = [[NSMutableArray alloc] initWithCapacity:[sfFields count]];
                    for (id object in sfFields) {
                        MTDatabaseField *databaseField = [[MTDatabaseField alloc] init];
                        [databaseField setName:     [object objectForKey:@"name"]];
                        [databaseField setLabel:    [object objectForKey:@"label"]];
                        //[databaseField setDatatype: [object objectForKey:@"type"]];
                        [resultFields addObject:databaseField];
                        [databaseField release];
                    }
                    self.resultBlockGetFields(YES, nil, resultFields);
                    [resultFields release];
                }
            }];
            break;
        }
        default:
            break;
    }
}


- (void)request:(SFRestRequest*)request didFailLoadWithError:(NSError*)error {
    //NSLog(@"request:didFailLoadWithError: %@", error);
#warning Show alert
    //add your failed error handling here
    
    [self setCurrentQueryType:MTDatabaseQueryTypeNone];
}

- (void)requestDidCancelLoad:(SFRestRequest *)request {
    //NSLog(@"requestDidCancelLoad: %@", request);
#warning Show alert
    //add your failed error handling here
    
    [self setCurrentQueryType:MTDatabaseQueryTypeNone];
}

- (void)requestDidTimeout:(SFRestRequest *)request {
    //NSLog(@"requestDidTimeout: %@", request);
#warning Show alert
    //add your failed error handling here
    
    [self setCurrentQueryType:MTDatabaseQueryTypeNone];
}

#pragma mark - Salesforce.com login helpers


- (SFOAuthCoordinator *)coordinator {
    //create a new coordinator if we don't already have one
    if (nil == _coordinator) {
        
        NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey];
        NSString *loginDomain = @"login.salesforce.com";
        NSString *accountIdentifier = @"Default";
        //here we use the login domain as part of the identifier
        //to distinguish between eg  sandbox and production credentials
        NSString *fullKeychainIdentifier = [NSString stringWithFormat:@"%@-%@-%@", appName, accountIdentifier, loginDomain];
        
        
        SFOAuthCredentials *creds = [[SFOAuthCredentials alloc] initWithIdentifier: fullKeychainIdentifier
                                                                          clientId: NSDATABASE_SF_OAUTH_KEY
                                                                         encrypted: YES];
        
        
        creds.domain = @"login.salesforce.com";
        creds.redirectUri = @"eda://reports.everydayapps.com/user/login";
        
        SFOAuthCoordinator *coord = [[SFOAuthCoordinator alloc] initWithCredentials:creds];
        coord.scopes = [NSSet setWithObjects: @"api",nil];
        
        coord.delegate = self;
        [self setCoordinator: coord];
        [coord release];
        [creds release];
    }
    
    return _coordinator;
}

- (void)reAuthenticate {
    [[self coordinator] revokeAuthentication];
    [self login:^(MTDatabaseSalesForce *database, BOOL complete) {
        
    }];
}

- (NSString *)getUserAgentString {
    //set a user agent string based on the mobile sdk version
    //We are building a user agent of the form:
    //SalesforceMobileSDK/1.0 iPhone OS/3.2.0 (iPad)
    
    UIDevice *curDevice = [UIDevice currentDevice];
    NSString *myUserAgent = [NSString stringWithFormat:
                             @"SalesforceMobileSDK/%@ %@/%@ (%@)",
                             kSFMobileSDKVersion,
                             [curDevice systemName],
                             [curDevice systemVersion],
                             [curDevice model]
                             ];
    
    
    return myUserAgent;
}

#pragma mark - SFOAuthCoordinatorDelegate

- (void)oauthCoordinator:(SFOAuthCoordinator *)coordinator willBeginAuthenticationWithView:(UIWebView *)view { }


- (void)oauthCoordinator:(SFOAuthCoordinator *)coordinator didBeginAuthenticationWithView:(UIWebView *)view {
    //nil[[self delegate] showWebView: view];
}

- (void)oauthCoordinatorDidAuthenticate:(SFOAuthCoordinator *)coordinator {
    [coordinator.view removeFromSuperview];
    [[SFRestAPI sharedInstance] setCoordinator:self.coordinator];
    self.resultBlockComplete(self, YES);
}

- (void)oauthCoordinator:(SFOAuthCoordinator *)coordinator didFailWithError:(NSError *)error {
    //NSLog(@"oauthCoordinator:didFailWithError: %@", error);
    [coordinator.view removeFromSuperview];
    
    if (error.code == kSFOAuthErrorInvalidGrant) {  //invalid cached refresh token
        //restart the login process asynchronously
        //NSLog(@"Logging out because oauth failed with error code: %d",error.code);
        [self performSelector:@selector(logout) withObject:nil afterDelay:0];
    }
    else {
        // show alert and retry
        
        MTAlertView *alertView = [[MTAlertView alloc] initWithTitle: NSLocalizedString(@"Salesforce Error", @"Salesforce Error")
                                                            message: [NSString stringWithFormat:@"Can't connect to salesforce: %@", error]
                                                  cancelButtonTitle: NSLocalizedString(@"Retry", @"Retry")
                                                   otherButtonTitle: nil onDismiss:^(NSInteger buttonIndex) {
                                                       
                                                   } onCancel:^{
                                                       [self login:^(MTDatabaseSalesForce *database, BOOL complete) {
                                                           
                                                       }];
                                                   }];
        [alertView show];
        [alertView autorelease];
        
/*
        
        [UIAlertView showAlertViewWithTitle:@"Salesforce Error" message:[NSString stringWithFormat:@"Can't connect to salesforce: %@", error] cancelButtonTitle:@"Retry" otherButtonTitle:nil onDismiss:^(int buttonIndex) {
            
        } onCancel:^{
            [self login:^(MTDatabaseSalesForce *database, BOOL complete) {
                
            }];
        }];
 */
    }
    self.resultBlockComplete(self, NO);
    
}

- (NSString *)identifier {
    return [MTDatabaseSalesForce identifier];
}

+ (NSString *)identifier {
    return @"Salesforce.com";
}

- (id)connectionSettings {
    return nil;
}

@end
