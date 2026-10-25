//
//  NSData+AES256.m
//  Reports
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "NSData+AES256.h"
#import <stdlib.h>
#import <string.h>
#import <strings.h>
#import <Foundation/NSString.h>

@implementation NSData (AES256)

#pragma mark - Public

// A fresh random IV per message, stored in the first block of the result, so the
// same plaintext under the same key never produces the same ciphertext.
- (NSData *)AES256EncryptWithKey:(NSString *)key {
	uint8_t iv[kCCBlockSizeAES128];
	arc4random_buf(iv, sizeof(iv));

	NSData *ciphertext = [self AES256EncryptWithKey:key iv:[NSData dataWithBytes:iv length:sizeof(iv)]];
	if (!ciphertext) {
		return nil;
	}

	NSMutableData *result = [NSMutableData dataWithCapacity:sizeof(iv) + ciphertext.length];
	[result appendBytes:iv length:sizeof(iv)];
	[result appendData:ciphertext];
	return result;
}

// The stored value is the IV followed by the ciphertext, so the first block is
// the IV the encryptor chose for this message.
- (NSData *)AES256DecryptWithKey:(NSString *)key {
	if (self.length < kCCBlockSizeAES128) {
		return nil;
	}
	const uint8_t *bytes = self.bytes;

	NSData *iv = [[NSData alloc] initWithBytesNoCopy:(void *)bytes length:kCCBlockSizeAES128 freeWhenDone:NO];
	NSData *ciphertext = [[NSData alloc] initWithBytesNoCopy:(void *)(bytes + kCCBlockSizeAES128)
													  length:self.length - kCCBlockSizeAES128
												freeWhenDone:NO];

	return [ciphertext AES256DecryptWithKey:key iv:iv];
}

#pragma mark - Core (fixed IV)

// The AES-256 key is the UTF-8 bytes of key, zero-padded to 32 bytes when
// shorter. A key that does not fit 32 bytes is refused: silently truncating --
// or worse, falling back to an all-zero key -- would let two different keys
// produce the same ciphertext.
static BOOL MADCopyAESKey(NSString *key, char keyBuffer[kCCKeySizeAES256]) {
	char buffer[kCCKeySizeAES256 + 1]; // room for the terminator, which is not part of the key
	bzero(buffer, sizeof(buffer)); // fill with zeroes (for padding)
	if (![key getCString:buffer maxLength:sizeof(buffer) encoding:NSUTF8StringEncoding]) {
		return NO;
	}
	memcpy(keyBuffer, buffer, kCCKeySizeAES256);
	return YES;
}

// Encrypts self with AES-256-CBC and PKCS#7 padding under the given 16-byte IV,
// returning the ciphertext alone. The public encryptor draws a random IV and
// prepends it; this form exists so the tests can pin the ciphertext against
// known vectors.
- (NSData *)AES256EncryptWithKey:(NSString *)key iv:(NSData *)iv {
	if (iv.length != kCCBlockSizeAES128) {
		return nil;
	}
	char keyBuffer[kCCKeySizeAES256];
	if (!MADCopyAESKey(key, keyBuffer)) {
		return nil;
	}

	// For a block cipher, the output is at most the input plus one block.
	size_t bufferSize = self.length + kCCBlockSizeAES128;
	void *buffer = malloc(bufferSize);

	size_t numBytesEncrypted = 0;
	CCCryptorStatus status = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
									 keyBuffer, kCCKeySizeAES256,
									 iv.bytes,
									 self.bytes, self.length,
									 buffer, bufferSize,
									 &numBytesEncrypted);
	if (status != kCCSuccess) {
		free(buffer);
		return nil;
	}

	// The returned data takes ownership of the buffer and frees it on deallocation.
	return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted freeWhenDone:YES];
}

// Decrypts self (the ciphertext, without the IV prefix) with AES-256-CBC under
// the given 16-byte IV; see the encryptor above.
- (NSData *)AES256DecryptWithKey:(NSString *)key iv:(NSData *)iv {
	if (iv.length != kCCBlockSizeAES128) {
		return nil;
	}
	char keyBuffer[kCCKeySizeAES256];
	if (!MADCopyAESKey(key, keyBuffer)) {
		return nil;
	}

	size_t bufferSize = self.length + kCCBlockSizeAES128;
	void *buffer = malloc(bufferSize);

	size_t numBytesDecrypted = 0;
	CCCryptorStatus status = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
									 keyBuffer, kCCKeySizeAES256,
									 iv.bytes,
									 self.bytes, self.length,
									 buffer, bufferSize,
									 &numBytesDecrypted);
	if (status != kCCSuccess) {
		free(buffer);
		return nil;
	}

	return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted freeWhenDone:YES];
}

@end
