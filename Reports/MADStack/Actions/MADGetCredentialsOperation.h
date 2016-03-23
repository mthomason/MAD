//
//  MADGetCredentialsOperation.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADGetCredentialsOperation_h
#define MAD_Designer_MADGetCredentialsOperation_h

#import "MADGroupOperation.h"

@class UIViewController, MADCredential;

@interface MADGetCredentialsOperation : MADGroupOperation

    - (instancetype)initWithKey:(NSString *)key viewController:(UIViewController *)viewController;

    @property (readonly) MADCredential *credentials;

@end

#endif
