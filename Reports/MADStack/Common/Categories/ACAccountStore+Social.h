//
//  ACAccountStore+Social.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/24/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_ACAccountStore_Social_h
#define MAD_Designer_ACAccountStore_Social_h

#import <Accounts/Accounts.h>
#import <Social/Social.h>
//#import <MADCocoaExtensions/MADCocoaExtensions.h>

@interface ACAccountStore (Social)

    + (void)twitterFollow:(NSString *)screenName completion:(void (^)(BOOL success, NSError *error))completion;

@end

#endif
