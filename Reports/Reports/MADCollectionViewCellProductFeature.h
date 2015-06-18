//
//  MADCollectionViewCellProductFeature.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/18/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MADCollectionViewCellProductFeature : UICollectionViewCell

@property (nonatomic, weak) IBOutlet UIImageView *image;
@property (nonatomic, weak) IBOutlet UILabel *labelTitle;
@property (nonatomic, weak) IBOutlet UITextView *labelDescription;

@end
