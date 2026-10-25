//
//  MADApplicationProtocol.h
//  MAD Designer
//
//  Created by Michael Thomason on 9/22/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADApplicationProtocol_h
#define MADApplicationProtocol_h

#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>

@protocol MADApplicationProtocol <NSObject>

	+ (NSString *)ubiquityIdentifier;
	+ (NSString *)groupIdentifier;
	+ (NSString *)humanReadableCopyright;
	+ (NSString *)bundleDisplayName;
	+ (NSString *)bundleVersion;
	+ (NSString *)bundleVersionShortString;
	+ (NSString *)bundleGitCommitCount;
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
