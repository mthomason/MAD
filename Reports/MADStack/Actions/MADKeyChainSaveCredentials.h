//
//  MADKeyChainSaveCredentials.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/11/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADKeyChainSaveCredentials_h
#define MAD_Designer_MADKeyChainSaveCredentials_h

#import "MADOperation.h"

@class MADCredential, UIViewController;

@interface MADKeyChainSaveCredentials : MADOperation

- (instancetype)initWithKey:(NSString *)key viewController:(UIViewController *)viewController;

@end

#endif
