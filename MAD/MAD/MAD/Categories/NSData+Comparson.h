//
//  NSData+Comparson.h
//  MAD
//
//  Created by Michael Thomason on 6/12/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_NSData_Compression_h
#define Reports_NSData_Compression_h

#import <Foundation/Foundation.h>

@interface NSData (Comparson)

- (NSComparisonResult)compareData:(NSData *)data;

@end

#endif
