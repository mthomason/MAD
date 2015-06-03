//
//  MTTableViewControllerAbout.m
//  MAD
//
//  Created by Michael Thomason on 8/20/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADAboutTableViewController.h"
#import <MessageUI/MessageUI.h>
#import <CoreText/CoreText.h>
#import "MTApplicationInstance.h"
#import "UIApplication+Extras.h"
#import "MADOpenFileViewController.h"
#import "UIDevice+Hack.h"
#import "NSError+Constructors.h"
#import "UIColor+EverydayApps.h"
#import "MADVibrantTableViewCell.h"
#import "MADVibrantTableView.h"
#import "MADocument.h"
#import "MADConstants.h"

@interface MADAboutTableViewController ()
    <MFMailComposeViewControllerDelegate,
    UITableViewDelegate,
    UITableViewDataSource,
    MADVibrantTableViewCellDelegate>

@end

@implementation MADAboutTableViewController

#pragma mark - MADVibrantTableViewCellDelegate

- (UIBlurEffect *)blurEffectForCell:(UITableViewCell *)cell {
    return (UIBlurEffect *)((MADVibrantTableView *)self.tableView).visualEffectsView.effect;
}

#pragma mark - Exit

- (IBAction)unwindToAbout:(UIStoryboardSegue *)action { }

- (BOOL)canPerformUnwindSegueAction:(SEL)action
                 fromViewController:(UIViewController *)fromViewController
                         withSender:(id)sender {
    return action == @selector(unwindToAbout:);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        NSAssert([self.tableView isKindOfClass:[MADVibrantTableView class]], @"Expects %@ class at %s", NSStringFromClass([MADVibrantTableView class]), __PRETTY_FUNCTION__);
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.allowsSelection = NO;
    self.preferredContentSize = CGSizeMake(280, 200);
}

- (UIViewController *)viewControllerForUnwindSegueAction:(SEL)action
                                      fromViewController:(UIViewController *)fromViewController
                                              withSender:(id)sender {
    
    return action == @selector(unwindToAbout:) ?
            self :
            [super viewControllerForUnwindSegueAction: action
                                   fromViewController: fromViewController
                                           withSender: sender];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (NSString *)versionText {
    NSString *versionTextKey = NSLocalizedString(@"Verison %@", @"Verison %@");
    NSString *version = [UIApplication version];
    NSString *versionText = [NSString stringWithFormat:versionTextKey, version];
    return versionText;
}

- (NSString *)buildText {
    NSString *buildTextKey = NSLocalizedString(@"Build %@", @"Build %@");
    NSString *buildText = [NSString stringWithFormat:buildTextKey, MTGlobalBundleRev];
    return buildText;
}

- (NSAttributedString *)trademarkStatement {
    NSNumber *superscript = @(1);
    UIFont *font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
    NSDictionary *attributes = @{(__bridge NSString *)kCTSuperscriptAttributeName : superscript,
                                 NSFontAttributeName : font};
    NSAttributedString *r = [[NSAttributedString alloc] initWithString: @"®"
                                                            attributes: attributes];
    NSAttributedString *mad = [[NSAttributedString alloc] initWithString: MADTrademark
                                                              attributes: nil];
    
    NSMutableAttributedString *tm = [[NSMutableAttributedString alloc] initWithAttributedString: mad];
    [tm appendAttributedString:r];
    
    NSAttributedString *statement = [[NSAttributedString alloc] initWithString: @" is a registered trademark of Everyday Apps LLC."
                                                                    attributes: nil];
    [tm appendAttributedString: statement];
    
    return tm;
}

- (IBAction)cancel:(id)sender {
    [self.delegate viewControllerDidCancel: self];
}

- (IBAction)done:(id)sender {
    [self.delegate viewControllerDidCancel: self];
}

- (IBAction)composeEmail:(id)sender {
    [self.delegate viewControllerDidRequestComposeEmail: self
                                               animated: YES];
}


- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error {

    __weak MADAboutTableViewController *weakself = self;
    [NSError presentError: error
         onViewController: self
               completion:^(BOOL success) {
        if (success) {
            [weakself dismissViewControllerAnimated:YES completion:nil];
        }
    }];

}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"MTSegueAboutGettingStarted"] ||
        [segue.identifier isEqualToString:@"MTSegueAboutSwipeNext"]) {
        ((MADAboutTableViewController *)segue.destinationViewController).delegate = self.delegate;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MADVibrantTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MADTableViewCellAbout"];
    cell.vibrantTableViewCellDelegate = self;
    cell.frame = CGRectMake(CGPointZero.x, CGPointZero.y, self.tableView.bounds.size.width, tableView.estimatedRowHeight);
    switch (indexPath.row) {

        case 0:
            cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
            cell.label.tintColor = [UIColor edaBlueDark];
            cell.label.text = @"MAD Designer";
            cell.marginStyle = MADTableViewCellMarginStyleTop;
            break;

        case 1:
            cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
            cell.label.text = [self versionText];
            cell.label.tintColor = [UIColor darkTextColor];
            cell.marginStyle = MADTableViewCellMarginStyleMiddle;
            break;
            
        case 2:
            cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
            cell.label.text = [self buildText];
            cell.label.tintColor = [UIColor darkTextColor];
            cell.marginStyle = MADTableViewCellMarginStyleMiddle;
            break;
            
        case 3:
            cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
            cell.label.attributedText = [self trademarkStatement];
            cell.label.tintColor = [UIColor darkTextColor];
            cell.marginStyle = MADTableViewCellMarginStyleMiddle;
            break;

        case 4:
            cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
            cell.label.text = @"Created by Michael Thomason for Everyday Apps.";
            cell.label.tintColor = [UIColor darkTextColor];
            cell.marginStyle = MADTableViewCellMarginStyleBottom;
            break;

        default:
            break;
    }
    [cell layoutIfNeeded];
    return cell;
}

@end
