//
//  ACAccountStore+Social.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/24/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "ACAccountStore+Social.h"
#import "NSError+Constructors.h"

@implementation ACAccountStore (Social)

+ (void)twitterFollow:(NSString *)screenName completion:(void (^)(BOOL success, NSError *error))completion {
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error) {
        if(granted) {
            // Get the list of Twitter accounts.
            NSArray *accountsArray = [accountStore accountsWithAccountType:accountType];
            
            // For the sake of brevity, we'll assume there is only one Twitter account present.
            // You would ideally ask the user which account they want to tweet from, if there is more than one Twitter account present.
            if (accountsArray.count > 0) {
                // Grab the initial Twitter account to tweet from.
                __block NSError *errorResponse = nil;
                __block BOOL success = NO;
                for (ACAccount *twitterAccount in accountsArray) {
                    NSMutableDictionary *tempDict = [[NSMutableDictionary alloc] init];
                    [tempDict setValue: screenName
                                forKey: @"screen_name"];
                    [tempDict setValue: @"true"
                                forKey: @"follow"];
                    NSLog(@"*******tempDict %@*******",tempDict);
                    
                    NSURL *twitterFriendships = [NSURL URLWithString:@"https://api.twitter.com/1.1/friendships/create.json"];
                    SLRequest *postRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:twitterFriendships parameters:tempDict];
                    [postRequest setAccount:twitterAccount];
                    [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                        if (!(success = urlResponse.statusCode == 200)) {
                            errorResponse = error;
                        }
                        #if DEBUG
                            NSString *output = [NSString stringWithFormat:@"HTTP response status: %li Error %ld", (long)[urlResponse statusCode],(long)error.code];
                            NSLog(@"%@error %@", output,error.description);
                        #endif
                    }];
                }
                completion(success, errorResponse);
                
            } else {
                NSString *title = NSLocalizedString(@"No Accounts Found", @"No Accounts Found");
                NSString *message = NSLocalizedString(@"Please add a Twitter account to your device.", @"Please add a Twitter account to your device.");
                NSError *noTwitterFound = [NSError errorWithDomain: @"MADSocial"
                                                              code: 3782
                                                             title: title
                                                        andMessage: message];
                completion(NO, noTwitterFound);
            }
            
        } else {
            NSString *title = NSLocalizedString(@"Access Denied", @"Access Denied");
            NSString *message = NSLocalizedString(@"The software doesn't have access to your Twitter accounts.  Please check the permission in the Settings app.",
                                                  @"The software doesn't have access to your Twitter accounts.  Please check the permission in the Settings app.");
            NSError *noTwitterFound = [NSError errorWithDomain: @"MADSocial"
                                                          code: 3782
                                                         title: title
                                                    andMessage: message];
            completion(NO, noTwitterFound);
        }
    }];
}

@end
