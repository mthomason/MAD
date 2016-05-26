//
//  MADApplicationProtocol.h
//  MAD Designer
//
//  Created by Michael Thomason on 9/22/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MADApplicationProtocol_h
#define MADApplicationProtocol_h

#include <objc/NSObject.h>

@class NSUserDefaults;

@protocol MADApplicationProtocol <NSObject>

    + (NSString *)ApplicationNameSufixPart;
    + (NSString *)Trademark;
    - (NSString *)applicationIdentifier;
    - (NSString *)applicationBundleIdentifier;
    - (NSString *)ubiquityIdentifier;
    - (NSString *)groupIdentifier;
    - (NSString *)name;
    - (NSString *)trademark;
    - (NSString *)applicationNameSufixPart;
    - (NSString *)localizedApplicationNameSufixPart;
    - (NSString *)versionNumber;
    - (NSString *)revisionNumber;

@end

#endif /* MADApplicationProtocol_h */
