//
//  Gradients.m
//  Reports
//
//  Created by Michael Thomason on 1/3/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "UIColor+Gradients.h"

@implementation UIColor (Gradients)

+ (CGGradientRef)backgroundGradientWhiteToBlack {
    static CGGradientRef _backgroundGradientTileBlack = NULL;
    if (NULL == _backgroundGradientTileBlack) {
        CGFloat colors[8] = {
            10.0000f / 255.0000f, 8.0000f / 255.0000f, 9.0000f / 255.0000f, 1.0000f,
            10.0000f / 255.0000f, 15.0000f / 255.0000f, 11.0000f / 255.0000f, 1.0000f
        };
        CGFloat colorStops[4] = {0.0000f, 1.0000f};
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        _backgroundGradientTileBlack = CGGradientCreateWithColorComponents(colorSpace, colors, colorStops, 2);
        CGColorSpaceRelease(colorSpace);
    }
    return _backgroundGradientTileBlack;
}

+ (CGGradientRef)backgroundGradientBlack {
    static CGGradientRef _backgroundGradientTileBlack = NULL;
    if (NULL == _backgroundGradientTileBlack) {
        CGFloat colors[16] = {
            10.0000f / 255.0000f, 8.0000f / 255.0000f, 9.0000f / 255.0000f, 1.0000f,
            10.0000f / 255.0000f, 15.0000f / 255.0000f, 11.0000f / 255.0000f, 1.0000f,
            109.0000f / 255.0000f, 118.0000f / 255.0000f, 115.0000f / 255.0000f, 1.0000f,
            175.0000f / 255.0000f, 189.0000f / 255.0000f, 192.0000f / 255.0000f, 1.0000f
        };
        CGFloat colorStops[4] = {0.0000f, 0.4200f, 0.4300f, 1.0000f};
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        _backgroundGradientTileBlack = CGGradientCreateWithColorComponents(colorSpace, colors, colorStops, 4);
        CGColorSpaceRelease(colorSpace);
    }
    return _backgroundGradientTileBlack;
}

+ (CGGradientRef)backgroundGradientWhite {
    static CGGradientRef _backgroundGradientTileWhite = NULL;
    if (NULL == _backgroundGradientTileWhite) {
        CGFloat colors[20] = {
            225.0000f / 255.0000f, 225.0000f / 255.0000f, 225.0000f / 255.0000f, 1.0000f,
            1.0000f, 1.0000f, 1.0000f, 1.0000f,
            253.0000f / 255.0000f, 253.0000f / 255.0000f, 253.0000f / 255.0000f, 1.0000f,
            237.0000f / 255.0000f, 237.0000f / 255.0000f, 237.0000f / 255.0000f, 1.0000f,
            222.0000f / 255.0000f, 222.0000f / 255.0000f, 222.0000f / 255.0000f, 1.0000f
        };
        CGFloat colorStops[5] = {0.0000f, 0.4000f, 0.6000f, 0.9800f, 1.0000f};
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        _backgroundGradientTileWhite = CGGradientCreateWithColorComponents(colorSpace, colors, colorStops, 5);
        CGColorSpaceRelease(colorSpace);
    }
    return _backgroundGradientTileWhite;
}

+ (CGGradientRef)backgroundGradientGray {
    static CGGradientRef _backgroundGradientTileGray = NULL;
    if (NULL == _backgroundGradientTileGray) {
        CGFloat colors[20] = {
            181.0000f / 255.0000f, 195.0000f / 255.0000f, 203.0000f / 255.0000f, 1.0000f,
            216.0000f / 255.0000f, 225.0000f / 255.0000f, 231.0000f / 255.0000f, 1.0000f,
            181.0000f / 255.0000f, 198.0000f / 255.0000f, 208.0000f / 255.0000f, 1.0000f,
            194.0000f / 255.0000f, 212.0000f / 255.0000f, 224.0000f / 255.0000f, 1.0000f,
            214.0000f / 255.0000f, 234.0000f / 255.0000f, 247.0000f / 255.0000f, 1.0000f
        };
        CGFloat colorStops[5] = {0.0000f, 0.5000f, 0.5000f, 0.7500f, 1.0000f};
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        _backgroundGradientTileGray = CGGradientCreateWithColorComponents(colorSpace, colors, colorStops, 5);
        CGColorSpaceRelease(colorSpace);
    }
    return _backgroundGradientTileGray;
}

+ (CGGradientRef)backgroundGradientGreen {
    static CGGradientRef _backgroundGradientTileGreen = NULL;
    if (NULL == _backgroundGradientTileGreen) {
        CGFloat colors[20] = {
            185.0000f / 255.0000f, 206.0000f / 255.0000f, 68.0000f / 255.0000f, 1.0000f,
            168.0000f / 255.0000f, 199.0000f / 255.0000f, 50.0000f / 255.0000f, 1.0000f,
            142.0000f / 255.0000f, 185.0000f / 255.0000f, 42.0000f / 255.0000f, 1.0000f,
            114.0000f / 255.0000f, 170.0000f / 255.0000f, 0.0000f, 1.0000f,
            148.0000f / 255.0000f, 197.0000f / 255.0000f, 22.0000f / 255.0000f, 1.0000f
        };
        CGFloat colorStops[5] = {0.0000f, 0.0800f, 0.5000f, 0.5000f, 0.9600f};
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        _backgroundGradientTileGreen = CGGradientCreateWithColorComponents(colorSpace, colors, colorStops, 5);
        CGColorSpaceRelease(colorSpace);
    }
    return _backgroundGradientTileGreen;
}

+ (CGGradientRef)backgroundGradientBlue {
    static CGGradientRef _backgroundGradientTileBlue = NULL;
    if (NULL == _backgroundGradientTileBlue) {
        CGFloat colors[16] = {
            112.0000f / 255.0000f, 182.0000f / 255.0000f, 242.0000f / 255.0000f, 1.0000f,
            84.0000f / 255.0000f, 163.0000f / 255.0000f, 238.0000f / 255.0000f, 1.0000f,
            54.0000f / 255.0000f, 112.0000f / 144.0000f, 240.0000f / 255.0000f, 1.0000f,
            26.0000f / 255.0000f, 98.0000f / 255.0000f, 219.0000f / 255.0000f, 1.0000f
        };
        CGFloat colorStops[4] = {0.0000f, 0.5000f, 0.5000f, 1.0000f};
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        _backgroundGradientTileBlue = CGGradientCreateWithColorComponents(colorSpace, colors, colorStops, 4);
        CGColorSpaceRelease(colorSpace);
    }
    return _backgroundGradientTileBlue;
}

+ (CGGradientRef)backgroundGradientPurple {
    static CGGradientRef _backgroundGradientTilePurple = NULL;
    if (NULL == _backgroundGradientTilePurple) {
        CGFloat colors[16] = {
            141.0000f / 255.0000f, 67.0000f / 255.0000f, 207.0000f / 255.0000f, 1.0000f,
            195.0000f / 255.0000f, 154.0000f / 255.0000f, 232.0000f / 255.0000f, 1.0000f,
            149.0000f / 255.0000f, 76.0000f / 255.0000f, 214.0000f / 255.0000f, 1.0000f,
            171.0000f / 255.0000f, 56.0000f / 255.0000f, 211.0000f / 255.0000f, 1.0000f
        };
        CGFloat colorStops[4] = {0.0000f, 0.5000f, 0.5000f, 1.0000f};
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        _backgroundGradientTilePurple = CGGradientCreateWithColorComponents(colorSpace, colors, colorStops, 4);
        CGColorSpaceRelease(colorSpace);
    }
    return _backgroundGradientTilePurple;
}

+ (CGGradientRef)backgroundGradientRed {
    static CGGradientRef _backgroundGradientTileRed = NULL;
    if (NULL == _backgroundGradientTileRed) {
        CGFloat colors[20] = {
            1.0000f, 88.0000f / 255.0000f, 55.0000f / 255.0000f, 1.0000f,
            247.0000f / 255.0000f, 42.0000f / 255.0000f, 12.0000f / 255.0000f, 1.0000f,
            241.0000f / 255.0000f, 111.0000f / 255.0000f, 92.0000f / 255.0000f, 1.0000f,
            215.0000f / 255.0000f, 41.0000f / 255.0000f, 23.0000f / 255.0000f, 1.0000f,
            236.0000f / 255.0000f, 60.0000f / 255.0000f, 44.0000f / 255.0000f, 1.0000f
        };
        CGFloat colorStops[5] = {0.0000f, 0.2600f, 0.5000f, 0.5000f, 1.0000f};
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        _backgroundGradientTileRed = CGGradientCreateWithColorComponents(colorSpace, colors, colorStops, 5);
        CGColorSpaceRelease(colorSpace);
    }
    return _backgroundGradientTileRed;
}

+ (CGGradientRef)backgroundGradientBlackShine {
    static CGGradientRef _backgroundGradientBlackShine = NULL;
    if (NULL == _backgroundGradientBlackShine) {
        CGFloat colors[16] = {
            175.0000f / 255.0000f, 189.0000f / 255.0000f, 192.0000f / 255.0000f, 0.5000f,
            109.0000f / 255.0000f, 118.0000f / 255.0000f, 115.0000f / 255.0000f, 0.5000f,
            10.0000f / 255.0000f, 15.0000f / 255.0000f, 11.0000f / 255.0000f, 0.5000f,
            10.0000f / 255.0000f, 8.0000f / 255.0000f, 9.0000f / 255.0000f, 0.5000f
        };
        CGFloat colorStops[4] = {0.0000f, 0.4900f, 0.5000f, 1.0000f};
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        _backgroundGradientBlackShine = CGGradientCreateWithColorComponents(colorSpace, colors, colorStops, 4);
        CGColorSpaceRelease(colorSpace);
    }
    return _backgroundGradientBlackShine;
}

+ (CGGradientRef)backgroundGradientFadeFromBlack {
    static CGGradientRef _backgroundGradientFadeFromBlack = NULL;
    if (NULL == _backgroundGradientFadeFromBlack) {
        CGFloat colors[12] = {
            0.0000f, 0.0000f, 0.0000f, 0.9000f,
            0.0000f, 0.0000f, 0.0000f, 0.3000f,
            0.0000f, 0.0000f, 0.0000f, 0.9000f
        };
        CGFloat colorStops[3] = {0.0000f, 0.5000f, 1.0000f};
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        _backgroundGradientFadeFromBlack = CGGradientCreateWithColorComponents(colorSpace, colors, colorStops, 3);
        CGColorSpaceRelease(colorSpace);
    }
    return _backgroundGradientFadeFromBlack;
}

+ (CGGradientRef)backgroundGradientFadeFromBlackRadial {
    static CGGradientRef _backgroundGradientFadeFromBlack = NULL;
    if (NULL == _backgroundGradientFadeFromBlack) {
        CGFloat colors[12] = {
            0.0000f, 0.0000f, 0.0000f, 0.3000f,
            0.0000f, 0.0000f, 0.0000f, 0.6000f,
            0.0000f, 0.0000f, 0.0000f, 0.9000f
        };
        CGFloat colorStops[3] = {0.0000f, 0.5000f, 1.0000f};
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        _backgroundGradientFadeFromBlack = CGGradientCreateWithColorComponents(colorSpace, colors, colorStops, 3);
        CGColorSpaceRelease(colorSpace);
    }
    return _backgroundGradientFadeFromBlack;
}

+ (CGGradientRef)backgroundGradientFadeToBlackRadial {
    static CGGradientRef _backgroundGradientFadeFromBlack = NULL;
    if (NULL == _backgroundGradientFadeFromBlack) {
        CGFloat colors[12] = {
            0.0000f, 0.0000f, 0.0000f, 0.9000f,
            0.0000f, 0.0000f, 0.0000f, 0.6000f,
            0.0000f, 0.0000f, 0.0000f, 0.3000f
        };
        CGFloat colorStops[3] = {0.0000f, 0.9000f, 1.0000f};
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        _backgroundGradientFadeFromBlack = CGGradientCreateWithColorComponents(colorSpace, colors, colorStops, 3);
        CGColorSpaceRelease(colorSpace);
    }
    return _backgroundGradientFadeFromBlack;
}

+ (CGGradientRef)backgroundGradientFadeToBlackRadialIcon {
    static CGGradientRef _backgroundGradientFadeFromBlack = NULL;
    if (NULL == _backgroundGradientFadeFromBlack) {
        CGFloat colors[12] = {
            0.0000f, 0.0000f, 0.0000f, 1.0000f,
            0.0000f, 0.0000f, 0.0000f, 0.0500f,
            0.0000f, 0.0000f, 0.0000f, 0.0000f
        };
        CGFloat colorStops[3] = {0.0000f, 2.0000f/3.0000f, 1.0000f};
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        _backgroundGradientFadeFromBlack = CGGradientCreateWithColorComponents(colorSpace, colors, colorStops, 3);
        CGColorSpaceRelease(colorSpace);
    }
    return _backgroundGradientFadeFromBlack;
}

+ (CGGradientRef)backgroundGradientGreenToRedIcon {
    static CGGradientRef _backgroundGradientFadeFromBlack = NULL;
    if (NULL == _backgroundGradientFadeFromBlack) {
        CGFloat colors[12] = {
            150.0000f  / 255.0000f, 255.0000f  / 255.0000f, 155.0000f / 255.0000f, 1.0000f,
            015.0000f  / 255.0000f, 185.0000f  / 255.0000f, 030.0000f / 255.0000f, 1.0000f,
            015.0000f  / 255.0000f, 185.0000f  / 255.0000f, 030.0000f / 255.0000f, 1.0000f,
        };
        CGFloat colorStops[3] = {0.0000f, 0.7500f, 1.0000f};
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        _backgroundGradientFadeFromBlack = CGGradientCreateWithColorComponents(colorSpace, colors, colorStops, 3);
        CGColorSpaceRelease(colorSpace);
    }
    return _backgroundGradientFadeFromBlack;
}

+ (CGGradientRef)backgroundGradientFadeFromRandom {
    CGFloat redLevel	= rand() / (float) RAND_MAX;
	CGFloat greenLevel	= rand() / (float) RAND_MAX;
	CGFloat blueLevel	= rand() / (float) RAND_MAX;
    CGFloat colors[12] = {
        redLevel, greenLevel, blueLevel, 0.9000f,
        redLevel, greenLevel, blueLevel, 0.5000f,
        redLevel, greenLevel, blueLevel, 0.9000f
    };
    CGFloat colorStops[3] = {0.0000f, 0.5000f, 1.0000f};
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    static CGGradientRef result = NULL;
    if (result == NULL) result = CGGradientCreateWithColorComponents(colorSpace, colors, colorStops, 3);
    CGColorSpaceRelease(colorSpace);
    return result;
}

@end
