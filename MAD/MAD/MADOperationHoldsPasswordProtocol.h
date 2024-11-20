//
//  MADOperationHoldsPasswordProtocol.h
//  MAD
//
//  Created by Michael on 2/16/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADOperationHoldsPasswordProtocol_h
#define MADOperationHoldsPasswordProtocol_h

@protocol MADOperationHoldsPasswordProtocol <NSObject>

    @property (nonatomic, readonly, copy) NSString *password;
    @property (nonatomic, readonly, assign) BOOL gotPassword;

@end

#endif /* MADOperationHoldsPasswordProtocol_h */
