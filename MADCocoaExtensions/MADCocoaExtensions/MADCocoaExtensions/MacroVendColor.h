//
//  vendColor.h
//  CocoaExtensions
//
//  Created by Michael Thomason on 6/23/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef CocoaExtensions_vendColor_h
#define CocoaExtensions_vendColor_h

#define vendColor(r, g, b) return [UIColor colorWithRed:(CGFloat)r/255.0000f green:(CGFloat)g/255.0000f blue:(CGFloat)b/255.0000f alpha:1.0000f]
#define vendColorWithAlpha(r, g, b, a) return [UIColor colorWithRed:(CGFloat)r/255.0000f green:(CGFloat)g/255.0000f blue:(CGFloat)b/255.0000f alpha:a]

#endif
