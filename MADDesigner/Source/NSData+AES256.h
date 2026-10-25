//
//  NSData+AES256.h
//  Reports
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_NSData_AES256_h
#define Reports_NSData_AES256_h

#import <Foundation/NSData.h>
#import <CommonCrypto/CommonCryptor.h>

@interface NSData (AES256)

	- (NSData *)AES256EncryptWithKey:(NSString *)key;
	- (NSData *)AES256DecryptWithKey:(NSString *)key;

@end

#endif
