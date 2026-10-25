//
//  MADOperationHoldsPasswordProtocol.h
//  MAD
//
//  Created by Michael on 2/16/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADOperationHoldsPasswordProtocol_h
#define MADOperationHoldsPasswordProtocol_h

@protocol MADOperationHoldsPasswordProtocol <NSObject>

	@property (nonatomic, readonly, copy) NSString *password;
	@property (nonatomic, readonly, assign) BOOL gotPassword;

@end

#endif /* MADOperationHoldsPasswordProtocol_h */
