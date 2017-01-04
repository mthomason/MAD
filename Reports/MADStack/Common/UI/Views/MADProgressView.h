//
//  MADProgressView.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/24/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADProgressView_h
#define Reports_MADProgressView_h

#import <UIKit/UIProgressView.h>

typedef NS_ENUM(short, MADProgressViewType) {
    MADProgressViewTypeDefault,
    MADProgressViewTypeFileExplorer,
    MADProgressViewTypeConnection,
};

@interface MADProgressView : UIProgressView

    + (instancetype)newProgressView:(MADProgressViewType)type;

@end

#endif
