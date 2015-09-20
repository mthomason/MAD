//
//  MADReceiptTableViewCell.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/21/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MADTableViewCellReceiptInAppPurchase : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *labelID;
@property (weak, nonatomic) IBOutlet UILabel *labelOriginalPurchaseDate;
@property (weak, nonatomic) IBOutlet UILabel *labelCancellationDate;
@property (weak, nonatomic) IBOutlet UILabel *labelCancellationLabel;


@end
