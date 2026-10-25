//
//  MADOperationHoldsUsernameProtocol.h
//  MAD
//
//  Created by Michael on 2/16/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADOperationHoldsUsernameProtocol_h
#define MADOperationHoldsUsernameProtocol_h

@protocol MADOperationHoldsUsernameProtocol <NSObject>

	@property (nonatomic, readonly, copy) NSString *username;
	@property (nonatomic, readonly, assign) BOOL gotUsername;

@end

#endif /* MADOperationHoldsUsernameProtocol_h */
