//
//  MADReceiptTableViewCell.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/21/15.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADTableViewCellReceiptInAppPurchase_h
#define MAD_Designer_MADTableViewCellReceiptInAppPurchase_h

#import <UIKit/UITableViewCell.h>

@interface MADTableViewCellReceiptInAppPurchase : UITableViewCell

    @property (weak, nonatomic) IBOutlet UILabel *labelID;
    @property (weak, nonatomic) IBOutlet UILabel *labelOriginalPurchaseDate;
    @property (weak, nonatomic) IBOutlet UILabel *labelCancellationDate;
    @property (weak, nonatomic) IBOutlet UILabel *labelCancellationLabel;

@end

#endif
