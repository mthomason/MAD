//
//  UIDocument+thumbnailURL.h
//  CocoaExtensions
//
//  Created by Michael Thomason on 9/14/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_CocoaExtensions_MADFilename_h
#define MAD_CocoaExtensions_MADFilename_h

#import <Foundation/NSObject.h>

@interface MADFilename : NSObject

    + (NSString *)newFilenameId:(NSUInteger)tag;

@end

#endif
