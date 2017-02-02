//
//  MADStyle.h
//  MADCocoaExtensions
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADTextStyle_h
#define MAD_MADTextStyle_h

#import <Foundation/NSObject.h>

@interface MADTextStyle : NSObject
    <NSCoding>

    - (instancetype)initWithBold:(BOOL)bold italic:(BOOL)italic
                       underline:(BOOL)underline strikethrough:(BOOL)strikethrough;

    @property (nonatomic, assign, readwrite) BOOL bold;
    @property (nonatomic, assign, readwrite) BOOL italic;
    @property (nonatomic, assign, readwrite) BOOL underline;
    @property (nonatomic, assign, readwrite) BOOL strikethrough;

@end

#endif /* MADStyle_h */
