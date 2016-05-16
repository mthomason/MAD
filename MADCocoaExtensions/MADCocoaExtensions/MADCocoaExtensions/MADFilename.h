//
//  UIDocument+thumbnailURL.h
//  CocoaExtensions
//
//  Created by Michael Thomason on 9/14/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_CocoaExtensions_MADFilename_h
#define MAD_CocoaExtensions_MADFilename_h

#import <Foundation/NSObject.h>

@interface MADFilename : NSObject

    + (NSString *)newFilenameId:(NSUInteger)tag;
    + (NSString *)newFilenameForMadUrl:(NSURL *)madUrl;

@end

#endif
