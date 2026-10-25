//
//  MADOperationHoldsCredentialsProtocol.h
//  MAD
//
//  Created by Michael on 2/16/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADOperationHoldsCredentialsProtocol_h
#define MADOperationHoldsCredentialsProtocol_h

@class MADCredential;

@protocol MADOperationHoldsCredentialsProtocol <NSObject>

	- (MADCredential *)credentials;
	- (BOOL)gotCredentials;
	- (BOOL)manuallyInputtedCredentials;

@end

#endif /* MADOperationHoldsCredentialsProtocol_h */
