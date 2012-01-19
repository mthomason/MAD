//
//  NSDatabaseMySql.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "NSDatabaseSalesForce.h"

#import "Constants.h"

#import "SFOAuthCredentials.h"
#import "SFRestAPI.h"

static NSString * const kSFMobileSDKVersion = @"1.0";

@interface NSDatabaseSalesForce (Private)

@end

@implementation NSDatabaseSalesForce

@synthesize delegate = _delegate;

@synthesize coordinator = _coordinator;

@synthesize username = _username, password = _password;
@synthesize loginDomain = _loginDomain, loginIdentifier = _loginIdentifier, loginKey = _loginKey, loginRedirectUri = _loginRedirectUri;
/*
@synthesize resultBlockTableNames;
@synthesize resultBlockFieldNames;
@synthesize resultBlockLoginComplete;
*/
@synthesize currentQueryType;

- (void)dealloc {
    
    [_coordinator setDelegate: nil];
    [_coordinator release];
    _coordinator = nil;
/*
    [resultBlockTableNames release];
    [resultBlockFieldNames release];
    [resultBlockLoginComplete release];
  */  
    [_username release];
    [_password release];
    [_loginDomain release];
    [_loginIdentifier release];
    [_loginKey release];
    [_loginRedirectUri release];

    [super dealloc];
}

- (id)init {
    self = [super init];
    if (self) {

    }
    return self;
}

- (id)initWithLoginDomain:(NSString *)domain accountIdentifier:(NSString *)identifier remoteAccessConsumerKey:(NSString *)key oauthRedirectUri:(NSString *)uri {
    self = [super init];
    if (self) {
        [self setLoginDomain: domain];
        [self setLoginIdentifier: identifier];
        [self setLoginKey: key];
        [self setLoginRedirectUri: uri];
        [self setCurrentQueryType: NSDatabaseQueryTypeNone];
    }
    return self;
}

- (id)initWithUsername:(NSString *)username andPassword:(NSString *)password {
    self = [super init];
    if (self) {
        [self setUsername: username];
        [self setPassword: password];
        [self setCurrentQueryType: NSDatabaseQueryTypeNone];
    }
    return self;
}

- (id)initWithOptions:(NSDictionary *)optons {
    self = [super init];
    if (self) {
        [self setUsername: [optons objectForKey:NSDATABASE_USERNAME]];
        [self setPassword: [optons objectForKey:NSDATABASE_PASSWORD]];
        [self setCurrentQueryType: NSDatabaseQueryTypeNone];
    }
    return self;
}

#pragma mark - SFRestAPIDelegate

- (void)request:(SFRestRequest *)request didLoadResponse:(id)jsonResponse {
    NSArray *records = [[jsonResponse objectForKey:@"records"] retain];
    NSLog(@"request:didLoadResponse: #records: %d", records.count);
    NSLog(@"request:didLoadResponse:  records: %@", records);

    switch ([self currentQueryType]) {
        case NSDatabaseQueryTypeGetTables: {
            rsltBlk_tblNames tableNamesResultBlock = resultBlockTableNames;
            tableNamesResultBlock(self, records);
            break;
        }
        case NSDatabaseQueryTypeGetFields:
            ;
            break;
        default:
            break;
    }
    [records release];
}


- (void)request:(SFRestRequest*)request didFailLoadWithError:(NSError*)error {
    NSLog(@"request:didFailLoadWithError: %@", error);
    //add your failed error handling here

    [self setCurrentQueryType:NSDatabaseQueryTypeNone];
}

- (void)requestDidCancelLoad:(SFRestRequest *)request {
    NSLog(@"requestDidCancelLoad: %@", request);
    //add your failed error handling here

    [self setCurrentQueryType:NSDatabaseQueryTypeNone];
}

- (void)requestDidTimeout:(SFRestRequest *)request {
    NSLog(@"requestDidTimeout: %@", request);
    //add your failed error handling here
    
    [self setCurrentQueryType:NSDatabaseQueryTypeNone];
}

#pragma mark - Public Actions

- (void)tablesInDataseAsyc:(NSString *)database completion:(void (^)(NSDatabaseSalesForce *database, NSArray *tables))completion {
    
    [self setCurrentQueryType: NSDatabaseQueryTypeGetTables];
    
    resultBlockTableNames = completion;
    
    SFRestRequest *request = [[SFRestAPI sharedInstance] requestForDescribeGlobal];    
    [[SFRestAPI sharedInstance] send:request delegate:self];
    
}

- (void)fieldsInDatabase:(NSString *)database andTable:(NSString *)table
              completion:(void (^)(NSDatabaseSalesForce *database, NSArray *fields))completion {
    [self setCurrentQueryType: NSDatabaseQueryTypeGetFields];

    SFRestRequest *request = [[SFRestAPI sharedInstance] requestForDescribeWithObjectType: table];    
    [[SFRestAPI sharedInstance] send:request delegate:self];
    
}

- (BOOL)testConnection {
    [self setCurrentQueryType: NSDatabaseQueryTypeVerify];
    
    __block BOOL result = NO;
        
    return result;
}

#pragma mark - Salesforce.com login helpers


- (SFOAuthCoordinator *)coordinator {
    //create a new coordinator if we don't already have one
    if (nil == _coordinator) {
        
        NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey];
        NSString *loginDomain = [self loginDomain];
        NSString *accountIdentifier = [self loginIdentifier];
        //here we use the login domain as part of the identifier
        //to distinguish between eg  sandbox and production credentials
        NSString *fullKeychainIdentifier = [NSString stringWithFormat:@"%@-%@-%@", appName, accountIdentifier, loginDomain];
        
        
        SFOAuthCredentials *creds = [[SFOAuthCredentials alloc] 
                                     initWithIdentifier: fullKeychainIdentifier  
                                     clientId: NSDATABASE_SF_OAUTH_KEY ];
                
        
        creds.domain = @"login.salesforce.com";
        creds.redirectUri = @"eda://reports.everydayapps.com/user/login";
        
        SFOAuthCoordinator *coord = [[SFOAuthCoordinator alloc] initWithCredentials:creds];
        coord.scopes = [NSSet setWithObjects:@"visualforce", @"api",nil]; 
        
        coord.delegate = self;
        [self setCoordinator: coord];
        [coord release];
        [creds release];
    } 
    
    return _coordinator;
}

- (void)login:(void (^)(NSDatabaseSalesForce *database, BOOL complete))completion {
    //kickoff authentication
    resultBlockLoginComplete = completion;
    resultBlockLoginComplete(self, NO);
    [[self coordinator] authenticate];
}


- (void)logout {
    [[self coordinator] revokeAuthentication];
    [[self coordinator] authenticate];
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

- (void)oauthCoordinator:(SFOAuthCoordinator *)coordinator willBeginAuthenticationWithView:(UIWebView *)view {
    NSLog(@"oauthCoordinator:willBeginAuthenticationWithView");
    [resultBlockLoginComplete release];
}


- (void)oauthCoordinator:(SFOAuthCoordinator *)coordinator didBeginAuthenticationWithView:(UIWebView *)view {
    NSLog(@"oauthCoordinator:didBeginAuthenticationWithView");
    [resultBlockLoginComplete release];
    [[self delegate] showWebView: view];

}

- (void)oauthCoordinatorDidAuthenticate:(SFOAuthCoordinator *)coordinator {
    NSLog(@"Logged in yo!");
    NSLog(@"oauthCoordinatorDidAuthenticate for userId: %@", coordinator.credentials.userId);
    [coordinator.view removeFromSuperview];
    [[SFRestAPI sharedInstance] setCoordinator:self.coordinator];
    
    switch ([self currentQueryType]) {
        case NSDatabaseQueryTypeGetTables:

            break;
        case NSDatabaseQueryTypeGetFields:
            break;
        default:
            break;
    }
    
    
    resultBlockLoginComplete(self, YES);
    /*
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            //rsltBlk_loginComplete loginBlock = 
            //loginBlock(YES);
        });
    });
    */
}

- (void)oauthCoordinator:(SFOAuthCoordinator *)coordinator didFailWithError:(NSError *)error {
    NSLog(@"oauthCoordinator:didFailWithError: %@", error);
    [coordinator.view removeFromSuperview];
    
    if (error.code == kSFOAuthErrorInvalidGrant) {  //invalid cached refresh token
        //restart the login process asynchronously
        NSLog(@"Logging out because oauth failed with error code: %d",error.code);
        [self performSelector:@selector(logout) withObject:nil afterDelay:0];
    }
    else {
        // show alert and retry
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Salesforce Error" 
                                                        message:[NSString stringWithFormat:@"Can't connect to salesforce: %@", error]
                                                       delegate:self
                                              cancelButtonTitle:@"Retry"
                                              otherButtonTitles: nil];
        [alert show];
        [alert release];
    }
    rsltBlk_loginComplete loginBlock = resultBlockLoginComplete;
    loginBlock(self, NO);
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self.coordinator authenticate];    
}

@end