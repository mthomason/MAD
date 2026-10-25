//
//  MADAlignment.h
//  MAD
//
//  Created by Michael Thomason on 9/28/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MTAlignment_h
#define MAD_MTAlignment_h

#import <Foundation/NSObject.h>

typedef enum MADHorizontalAlignment : int16_t {
	MADHorizontalAlignmentUnknown = -1,
	MADHorizontalAlignmentLeft = 0,
	MADHorizontalAlignmentCenter = 1,
	MADHorizontalAlignmentRight = 2,
	MADHorizontalAlignmentJustified = 3,
	MADHorizontalAlignmentNatrual = 4,
	
} MADHorizontalAlignment;

typedef enum MADVerticalAlignment : int16_t {
	MADVerticalAlignmentUnknown = -1,
	MADVerticalAlignmentTop = 0,
	MADVerticalAlignmentCenter = 1,
	MADVerticalAlignmentBottom = 2
} MADVerticalAlignment;

struct MADAlignment_t {
	MADHorizontalAlignment horizontal;
	MADVerticalAlignment vertical;
};
typedef struct MADAlignment_t MADAlignment_t;

@interface MADAlignment : NSObject <NSCoding>

@property (nonatomic, assign, readwrite) MADHorizontalAlignment horizontal;
@property (nonatomic, assign, readwrite) MADVerticalAlignment vertical;

- (instancetype)initWithHorizontal:(MADHorizontalAlignment)horizontal
						  vertical:(MADVerticalAlignment)vertical;

@end

static inline MADAlignment_t MADAlignmentMake(MADHorizontalAlignment, MADVerticalAlignment);
static inline MADAlignment_t MADAlignmentMake64(int64_t, int64_t);

static inline MADAlignment_t MADAlignmentMake(MADHorizontalAlignment h, MADVerticalAlignment v) {
	MADAlignment_t a; a.horizontal = h; a.vertical = v; return a;
}
static inline MADAlignment_t MADAlignmentMake64(int64_t h, int64_t v) {
	MADAlignment_t a;
	switch (v) {
		case MADVerticalAlignmentTop:
			a.vertical = MADVerticalAlignmentTop;
			break;
		case MADVerticalAlignmentCenter:
			a.vertical = MADVerticalAlignmentCenter;
			break;
		case MADVerticalAlignmentBottom:
			a.vertical = MADVerticalAlignmentBottom;
			break;
		default:
			a.vertical = MADVerticalAlignmentTop;
			break;
	}
	switch (h) {
		case MADHorizontalAlignmentLeft:
			a.horizontal = MADHorizontalAlignmentLeft;
			break;
		case MADHorizontalAlignmentCenter:
			a.horizontal = MADHorizontalAlignmentCenter;
			break;
		case MADHorizontalAlignmentRight:
			a.horizontal = MADHorizontalAlignmentRight;
			break;
		case MADHorizontalAlignmentJustified:
			a.horizontal = MADHorizontalAlignmentJustified;
			break;
		case MADHorizontalAlignmentNatrual:
			a.horizontal = MADHorizontalAlignmentNatrual;
			break;
		default:
			a.horizontal = MADHorizontalAlignmentLeft;
			break;
	}
	return a;
}

#endif
