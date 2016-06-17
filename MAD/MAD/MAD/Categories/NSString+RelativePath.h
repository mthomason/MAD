//
//  NSString+RelativePath.h
//  MAD
//
//  Created by Michael Thomason on 5/21/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Reports_NSString_RelativePath_h
#define MAD_Reports_NSString_RelativePath_h

#import <Foundation/NSString.h>

@interface NSString (RelativePath)

- (NSString *)stringWithPathRelativeTo:(NSString *)anchorPath;

@end

#endif
