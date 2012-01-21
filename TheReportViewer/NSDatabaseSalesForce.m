//
//  NSDatabaseMySql.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "NSDatabaseSalesForce.h"

#import "Constants.h"

#import "UIManagedDocumentQuery.h"

#import "NSFileManager+Common.h"

#import "SFOAuthCredentials.h"
#import "SFRestAPI.h"

static NSString * const kSFMobileSDKVersion = @"1.0";

@interface NSDatabaseSalesForce (Private)

@end

@implementation NSDatabaseSalesForce

@synthesize delegate = _delegate;

@synthesize coordinator = _coordinator;

@synthesize loginDomain = _loginDomain, loginIdentifier = _loginIdentifier, loginKey = _loginKey, loginRedirectUri = _loginRedirectUri;

@synthesize currentQueryType;

- (void)dealloc {
        
    [_coordinator setDelegate: nil];
    [_coordinator release];
    _coordinator = nil;

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

//Init with url. Open the file at that url.
- (id)initWithUrl:(NSURL *)url {
    self = [super init];
    if (self) {

    }
    return self;
}

//Init with new file name. Create and open the file at that url.
- (id)initWithFileName:(NSString *)name {
    self = [super init];
    if (self) {
        
    }
    return self;
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
    
    resultBlockFieldNames = completion;
    
    SFRestRequest *request = [[SFRestAPI sharedInstance] requestForDescribeWithObjectType: table];    
    [[SFRestAPI sharedInstance] send:request delegate:self];
    
}

- (void)newQueryFile {
    
}

- (BOOL)testConnection {
    [self setCurrentQueryType: NSDatabaseQueryTypeVerify];
    
    __block BOOL result = NO;
    
    return result;
}

#pragma mark - SFRestAPIDelegate

- (void)request:(SFRestRequest *)request didLoadResponse:(id)jsonResponse {
    switch ([self currentQueryType]) {
        case NSDatabaseQueryTypeGetTables: {
            
            NSDictionary *response = [jsonResponse retain];
            [response enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                if ([key isEqualToString:@"sobjects"]) {
                    NSArray *tables = [obj retain];
                    NSMutableArray *records = [[NSMutableArray alloc] initWithCapacity: [tables count]];
                    [tables enumerateObjectsUsingBlock:^(id objt, NSUInteger idx, BOOL *stop) {
                        NSDictionary *table = [objt retain];
                        [records addObject:[NSString stringWithString: [table objectForKey:@"name"]]];
                        [table release];
                    }];
                    
                    rsltBlk_tblNames tableNamesResultBlock = resultBlockTableNames;
                    tableNamesResultBlock(self, records);                    
                    
                    [records release];
                    [tables release];
                }
                
            }];
            [response release];

            break;
        }
        case NSDatabaseQueryTypeGetFields: {
            NSDictionary *response = [jsonResponse retain];
            //NSLog(@"response: %@", response);
            [response enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                //NSLog(@"Field {%@, %@}", key, obj);
                if ([key isEqualToString:@"fields"]) {
                    NSArray *fields = [obj retain];
                    NSMutableArray *records = [[NSMutableArray alloc] initWithCapacity: [fields count]];
                    [fields enumerateObjectsUsingBlock:^(id objf, NSUInteger idx, BOOL *stop) {
                        NSDictionary *field = [objf retain];
                        //NSLog(@"%@", field);                        
                        //NSLog(@"%@", [field objectForKey:@"name"]);
                        [records addObject:[NSString stringWithString: [field objectForKey:@"name"]]];
                        [field release];
                    }];
                    
                    rsltBlk_tblNames fieldNamesResultBlock = resultBlockFieldNames;
                    fieldNamesResultBlock(self, records);                    
                    
                    [records release];
                    [fields release];
                }
            }];
            [response release];
            break;
        }
        default:
            break;
    }
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
    [[self coordinator] authenticate];
}


- (void)logout {
    [[self coordinator] revokeAuthentication];
}

- (void)reAuthenticate {
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

- (void)oauthCoordinator:(SFOAuthCoordinator *)coordinator willBeginAuthenticationWithView:(UIWebView *)view { }


- (void)oauthCoordinator:(SFOAuthCoordinator *)coordinator didBeginAuthenticationWithView:(UIWebView *)view {
    [[self delegate] showWebView: view];
}

- (void)oauthCoordinatorDidAuthenticate:(SFOAuthCoordinator *)coordinator {
    [coordinator.view removeFromSuperview];
    [[SFRestAPI sharedInstance] setCoordinator:self.coordinator];
    resultBlockLoginComplete(self, YES);
}

- (void)oauthCoordinator:(SFOAuthCoordinator *)coordinator didFailWithError:(NSError *)error {
    //NSLog(@"oauthCoordinator:didFailWithError: %@", error);
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