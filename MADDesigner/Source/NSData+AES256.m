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

	// A fresh random IV per message, stored in the first block of the result. A NULL IV
	// made every encryption under a given key deterministic, so the same plaintext
	// always produced the same ciphertext and callers could tell two values apart.
	uint8_t iv[kCCBlockSizeAES128];
	arc4random_buf(iv, sizeof(iv));

	//See the doc: For block ciphers, the output size will always be less than or
	//equal to the input size plus the size of one block.
	//That's why we need to add the size of one block here
	size_t bufferSize = dataLength + kCCBlockSizeAES128;
	void *buffer = malloc(bufferSize);

	size_t numBytesEncrypted = 0;
	CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
										  keyPtr, kCCKeySizeAES256,
										  iv,
										  self.bytes, dataLength, /* input */
										  buffer, bufferSize, /* output */
										  &numBytesEncrypted);
	if (cryptStatus == kCCSuccess) {
		NSMutableData *result = [NSMutableData dataWithCapacity:sizeof(iv) + numBytesEncrypted];
		[result appendBytes:iv length:sizeof(iv)];
		[result appendBytes:buffer length:numBytesEncrypted];
		free(buffer);
		return result;
	}

	free(buffer); //free the buffer;
	return nil;
}

- (NSData *)AES256DecryptWithKey:(NSString *)key {
	// 'key' should be 32 bytes for AES256, will be null-padded otherwise
	char keyPtr[kCCKeySizeAES256+1]; // room for terminator (unused)
	bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)

	// fetch key data. As in the encrypt path, a key too long to fit is refused rather
	// than silently turning into the all-zero key.
	if (![key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding]) {
		return nil;
	}

	// The first block is the IV the encryptor chose for this message.
	if (self.length < kCCBlockSizeAES128) {
		return nil;
	}
	const void *iv = self.bytes;
	const void *ciphertext = (const uint8_t *)self.bytes + kCCBlockSizeAES128;
	NSUInteger dataLength = self.length - kCCBlockSizeAES128;

	//See the doc: For block ciphers, the output size will always be less than or
	//equal to the input size plus the size of one block.
	//That's why we need to add the size of one block here
	size_t bufferSize = dataLength + kCCBlockSizeAES128;
	void *buffer = malloc(bufferSize);

	size_t numBytesDecrypted = 0;
	CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
										  keyPtr, kCCKeySizeAES256,
										  iv,
										  ciphertext, dataLength, /* input */
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
