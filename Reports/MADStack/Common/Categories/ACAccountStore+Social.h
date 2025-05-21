//
//  ACAccountStore+Social.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/24/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_Designer_ACAccountStore_Social_h
#define MAD_Designer_ACAccountStore_Social_h

#import <Accounts/Accounts.h>

@interface ACAccountStore (Social)

+ (void)twitterFollow:(NSString *)screenName completion:(void (^)(BOOL success, NSError *error))completion __deprecated;

@end

#endif
