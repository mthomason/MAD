//
//  NSData+AES256.h
//  Reports
//
//  Created by Michael Thomason on 5/31/13.
//  Copyright (c) 2016 Everyday Apps LLC. All rights reserved.
//
//  Found at http://pastie.org/426530#44
//

//  Base64 functions from the following...
//
//  NSData+Base64.h
//  base64
//
//  Created by Matt Gallagher on 2009/06/03.
//  Copyright 2009 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#ifndef Reports_MADData_h
#define Reports_MADData_h

#import <Foundation/NSData.h>
#import <CommonCrypto/CommonCryptor.h>
#import <Foundation/NSObjCRuntime.h>

void *NewBase64Decode(
                      const char *inputBuffer,
                      size_t length,
                      size_t *outputLength);

char *NewBase64Encode(
                      const void *inputBuffer,
                      size_t length,
                      bool separateLines,
                      size_t *outputLength);

@interface MADData : NSData

- (NSData *)AES256EncryptWithKey:(NSString *)key;
- (NSData *)AES256DecryptWithKey:(NSString *)key;

+ (NSData *)dataFromBase64String:(NSString *)aString;
- (NSString *)base64EncodedString;

@end

#endif
