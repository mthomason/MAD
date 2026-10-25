//
//  NSData+AES256.m
//  Reports
//
//  Created by Michael Thomason on 5/31/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "NSData+AES256.h"
#import <stdlib.h>
#import <strings.h>
#import <Foundation/NSString.h>

@implementation NSData (AES256)

- (NSData *)AES256EncryptWithKey:(NSString *)key {
	// A fresh random IV per message, stored in the first block of the result. A NULL IV
	// made every encryption under a given key deterministic, so the same plaintext
	// always produced the same ciphertext and callers could tell two values apart.
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

- (NSData *)AES256DecryptWithKey:(NSString *)key {
	// The first block is the IV the encryptor chose for this message.
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

#pragma mark - Fixed-IV core (test seam)

/*
	The deterministic core behind the public encryptor: encrypt self under key with the
	given 16-byte IV, returning the ciphertext alone. Exposed so the golden tests can pin
	exact ciphertext bytes against externally computed vectors; the public method draws a
	random IV and prepends it.
 */
- (NSData *)AES256EncryptWithKey:(NSString *)key iv:(NSData *)iv {
	if (iv.length != kCCBlockSizeAES128) {
		return nil;
	}

	// 'key' should be 32 bytes for AES256, will be null-padded otherwise
	char keyPtr[kCCKeySizeAES256+1]; // room for terminator (unused)
	bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)

	// fetch key data. The result was once discarded, so a key too long to fit left the
	// buffer as the 32 zero bytes it was just cleared to -- two different keys then
	// produced identical ciphertext. Refuse instead of silently using the zero key.
	if (![key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding]) {
		return nil;
	}

	NSUInteger dataLength = self.length;

	//See the doc: For block ciphers, the output size will always be less than or
	//equal to the input size plus the size of one block.
	//That's why we need to add the size of one block here
	size_t bufferSize = dataLength + kCCBlockSizeAES128;
	void *buffer = malloc(bufferSize);

	size_t numBytesEncrypted = 0;
	CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
										  keyPtr, kCCKeySizeAES256,
										  iv.bytes,
										  self.bytes, dataLength, /* input */
										  buffer, bufferSize, /* output */
										  &numBytesEncrypted);
	if (cryptStatus == kCCSuccess) {
		NSData *result = [NSData dataWithBytes:buffer length:numBytesEncrypted];
		free(buffer);
		return result;
	}

	free(buffer); //free the buffer;
	return nil;
}

/*
	The deterministic core behind the public decryptor: self is the ciphertext (without
	the IV prefix), iv the 16 bytes the encryptor used for this message.
 */
- (NSData *)AES256DecryptWithKey:(NSString *)key iv:(NSData *)iv {
	if (iv.length != kCCBlockSizeAES128) {
		return nil;
	}

	// 'key' should be 32 bytes for AES256, will be null-padded otherwise
	char keyPtr[kCCKeySizeAES256+1]; // room for terminator (unused)
	bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)

	// fetch key data. As in the encrypt path, a key too long to fit is refused rather
	// than silently turning into the all-zero key.
	if (![key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding]) {
		return nil;
	}

	NSUInteger dataLength = self.length;

	//See the doc: For block ciphers, the output size will always be less than or
	//equal to the input size plus the size of one block.
	//That's why we need to add the size of one block here
	size_t bufferSize = dataLength + kCCBlockSizeAES128;
	void *buffer = malloc(bufferSize);

	size_t numBytesDecrypted = 0;
	CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
										  keyPtr, kCCKeySizeAES256,
										  iv.bytes,
										  self.bytes, dataLength, /* input */
										  buffer, bufferSize, /* output */
										  &numBytesDecrypted);

	if (cryptStatus == kCCSuccess) {
		//the returned NSData takes ownership of the buffer and will free it on deallocation
		return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
	}

	free(buffer); //free the buffer;
	return nil;
}

@end
