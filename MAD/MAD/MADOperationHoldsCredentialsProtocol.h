//
//  MADOperationHoldsCredentialsProtocol.h
//  MAD
//
//  Created by Michael on 2/16/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADOperationHoldsCredentialsProtocol_h
#define MADOperationHoldsCredentialsProtocol_h

@protocol MADOperationHoldsCredentialsProtocol <NSObject>

    - (MADCredential *)credentials;
    - (BOOL)gotCredentials;

@end

#endif /* MADOperationHoldsCredentialsProtocol_h */
