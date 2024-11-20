//
//  NSData+Comparson.h
//  MAD
//
//  Created by Michael Thomason on 6/12/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_NSData_Compression_h
#define Reports_NSData_Compression_h

#import <Foundation/NSData.h>

@interface NSData (Comparson)

    - (NSComparisonResult)compareData:(NSData *)data;

@end

#endif
