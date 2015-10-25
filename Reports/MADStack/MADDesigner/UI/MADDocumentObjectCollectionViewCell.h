//
//  MADDocumentObjectCollectionViewCell.h
//  MAD Designer
//
//  Created by Michael Thomason on 10/24/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MAD/MADDocumentObjectType.h>

@interface MADDocumentObjectCollectionViewCell : UICollectionViewCell

@property (nonatomic, assign) MTDocumentObjectType type;
@property (nonatomic, weak) IBOutlet UILabel *title;
@property (nonatomic, weak) IBOutlet UILabel *detail;

@end
