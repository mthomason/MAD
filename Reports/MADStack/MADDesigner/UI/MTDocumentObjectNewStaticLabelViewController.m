//
//  MTDocumentObjectNewStaticLabelViewController.m
//  Reports
//
//  Created by Michael Thomason on 3/17/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTDocumentObjectNewStaticLabelViewController.h"

#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>

#import "MADNavigationBarTitleView.h"

NSString * const MTDocumentObjectNewStaticLabelViewControllerIdentifier = @"MTDocumentObjectNewStaticLabelViewControllerIdentifier";

@interface MTDocumentObjectNewStaticLabelViewController ()

@property (nonatomic, weak) IBOutlet UILabel *labelTextLabel;

@end

@implementation MTDocumentObjectNewStaticLabelViewController

@synthesize unwindViewController;

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.leftItemsSupplementBackButton = YES;
    self.navigationItem.hidesBackButton = NO;
    self.textField.delegate = self;
    [self.textField becomeFirstResponder];
    
    MADNavigationBarTitleView *titleView = [[MADNavigationBarTitleView alloc] initWithFrame:CGRectZero];
    titleView.text = NSLocalizedString(@"Static Label", @"Title of button to create a non-changing (static) text-label-document-object.");
    self.navigationItem.titleView = titleView;

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.preferredContentSize = CGSizeMake(320.0000f, 120.0000f);
    self.navigationController.preferredContentSize = CGSizeMake(320.0000f, 120.0000f);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (BOOL)canPerformUnwindSegueAction:(SEL)action
                 fromViewController:(UIViewController *)fromViewController
                         withSender:(id)sender {
    return NO;
}

- (UIViewController *)viewControllerForUnwindSegueAction:(SEL)action
                                      fromViewController:(UIViewController *)fromViewController
                                              withSender:(id)sender {
    
    return self.unwindViewController ?
            self.unwindViewController :
            [super viewControllerForUnwindSegueAction: action
                           fromViewController: fromViewController
                                   withSender: sender];
}

#pragma mark -
#pragma mark Text Field Delegate Protocol

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.text.length > 0) {
        [self performSegueWithIdentifier:@"MTSegueNewDocumentObjectStaticLabelSaveIdentifer" sender:self];
    } else {
        [self performSegueWithIdentifier:@"MTSegueNewDocumentObjectStaticLabelCancelIdentifer" sender:self];
    }
    return YES;
}

#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
