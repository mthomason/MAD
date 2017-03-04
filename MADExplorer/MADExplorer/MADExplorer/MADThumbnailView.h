//
//  MADThumbnailView.h
//  MADExplorer
//
//  Created by Michael Thomason on 6/23/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADThumbnailView_h
#define Reports_MADThumbnailView_h

#import <UIKit/UIImageView.h>

@interface MADThumbnailView : UIImageView

    @property (nonatomic, copy) NSURL *thumbnailURL;

    - (void)prepareForReuse;

@end

#endif
