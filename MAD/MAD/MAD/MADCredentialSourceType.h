//
//  MADCredentialSourceType.h
//  MAD
//
//  Created by Michael on 2/16/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADCredentialSourceType_h
#define MAD_MADCredentialSourceType_h

typedef NS_ENUM(short, MADCredentialSource) {
    MADCredentialSourceUnknown,
    MADCredentialSourceNone,
    MADCredentialSourceKeychain,
    MADCredentialSourceCredentialPrompt,
    MADCredentialSourcePasswordPrompt,
};

#endif /* MADCredentialSourceType_h */
