//
//  NSFileManager+Ubiquity.h
//  Linux/Compat
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Apple's NSFileManager answers iCloud's ubiquity questions -- the container
//  URL, the identity token, whether an item is ubiquitous -- and GNUstep's
//  has none of them.  Off Apple there is no ubiquitous storage at all, so
//  each call answers the value that means "no iCloud": nil, NO, or a no-op.
//  The file manager's cloud paths then take their local branches, which is
//  what the headless engine wants (the iCloud machinery dies with the store
//  migration's Phase D).  Non-Apple only; nothing on Apple sees it.
//

#ifndef MADCompat_NSFileManager_Ubiquity_h
#define MADCompat_NSFileManager_Ubiquity_h

#if !__APPLE__
#import <Foundation/NSFileManager.h>
#import <Foundation/NSURL.h>

@interface NSFileManager (MADCompatUbiquity)

- (NSURL *)URLForUbiquityContainerIdentifier:(NSString *)containerIdentifier;
- (id)ubiquityIdentityToken;
- (BOOL)isUbiquitousItemAtURL:(NSURL *)url;
- (BOOL)setUbiquitous:(BOOL)flag itemAtURL:(NSURL *)sourceURL
	  destinationURL:(NSURL *)destinationURL error:(NSError **)error;

@end

#endif /* !__APPLE__ */

#endif /* MADCompat_NSFileManager_Ubiquity_h */
