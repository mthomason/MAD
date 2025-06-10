//
//  MADApplicationProtocol.h
//  MAD Designer
//
//  Created by Michael Thomason on 9/22/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADApplicationProtocol_h
#define MADApplicationProtocol_h

#include <objc/NSObject.h>

@protocol MADApplicationProtocol <NSObject>

	+ (NSString *)ubiquityIdentifier;
	+ (NSString *)groupIdentifier;
	+ (NSString *)humanReadableCopyright;
	+ (NSString *)bundleDisplayName;
	+ (NSString *)bundleVersion;
	- (NSString *)ubiquityIdentifier;
	- (NSString *)groupIdentifier;
	- (NSString *)applicationIdentifier;
	- (NSString *)applicationBundleIdentifier;
	- (NSString *)name;
	- (NSString *)trademark;
	- (NSString *)applicationNameSufixPart;
	- (NSString *)localizedApplicationNameSufixPart;
	- (NSString *)versionNumber;
	- (NSString *)revisionNumber;

@end

#endif /* MADApplicationProtocol_h */
