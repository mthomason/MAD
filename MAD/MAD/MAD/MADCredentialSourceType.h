//
//  MADCredentialSourceType.h
//  MAD
//
//  Created by Michael on 2/16/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADCredentialSourceType_h
#define MAD_MADCredentialSourceType_h

typedef NS_ENUM(short, MADCredentialSource) {
	MADCredentialSourceUnknown = 0,
	MADCredentialSourceNone,
	MADCredentialSourceKeychain,
	MADCredentialSourceCredentialPrompt,
	MADCredentialSourcePasswordPrompt,
};

#endif /* MADCredentialSourceType_h */
