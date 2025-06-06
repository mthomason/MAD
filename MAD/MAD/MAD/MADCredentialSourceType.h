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

static inline NSString *NSStringFromMADCredentialSource(MADCredentialSource);
static inline NSString *NSStringFromMADCredentialSource(MADCredentialSource source) {
	switch (source) {
		case MADCredentialSourceNone: return @"MADCredentialSourceNone";
		case MADCredentialSourceKeychain: return @"MADCredentialSourceKeychain";
		case MADCredentialSourceCredentialPrompt: return @"MADCredentialSourceCredentialPrompt";
		case MADCredentialSourcePasswordPrompt: return @"MADCredentialSourcePasswordPrompt";
		case MADCredentialSourceUnknown: default: return @"MADCredentialSourceUnknown";
	}
}

#endif /* MADCredentialSourceType_h */
