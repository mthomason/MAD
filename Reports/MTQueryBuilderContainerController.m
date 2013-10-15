//
//  ViewController.m
//  MTSplitViewController
//
//  Created by Michael Thomason on 2/13/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryBuilderContainerController.h"
#import "Constants.h"

@interface MTQueryBuilderContainerController ()

@property (nonatomic, retain) IBOutlet UIView *leftView;
@property (nonatomic, retain) IBOutlet UIView *rightView;
@property (nonatomic, retain) IBOutletCollection(NSLayoutConstraint) NSArray *bogusConstraints;
@property (nonatomic, retain) IBOutlet UIToolbar *toolbarTop;
@property (nonatomic, retain) IBOutlet MTTitleView *titleView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemEdit;

@property (nonatomic, assign) BOOL isEditing;

- (MTQueryBuilderViewController *)queryBuilderController;
- (MTQueryBuilderAdvancedSchemaViewController *)queryBuilderControllerAdvanced;

@end

@implementation MTQueryBuilderContainerController

- (void)dealloc {
    [_leftView release];
    [_rightView release];
    [_bogusConstraints release];
    [_toolbarTop release];
    [_titleView release];
    [_barButtonItemEdit release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setIsEditing:NO];

    [[self delegateContentController] displayContentController: [[self childViewControllers] objectAtIndex:0]];
    [[self delegateContentController] displayContentController: [[self childViewControllers] objectAtIndex:1]];
    
    
    [[[self titleView] label] setText:NSLocalizedString(@"Query", @"Query")];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    //[super prepareForSegue:segue sender:sender];
    if ([[segue identifier] isEqualToString:@"MTSegueIdentifierShowReportDesigerFromSplitView"]) {
        if ([[segue destinationViewController] isKindOfClass: [MTReportDesignerViewController class]]) {
            [[segue destinationViewController] setDelegate: self];
        } else if ([[segue destinationViewController] isKindOfClass:[UINavigationController class]]) {
            [(MTReportDesignerViewController *)[[segue destinationViewController] topViewController] setDelegate:self];
        }
    }    
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    BOOL leftIsGo = YES, rightIsGo = YES;
    if ([identifier isEqualToString:@"MTSegueCloseDesigner"]) {
        leftIsGo = [self leftViewController] == nil ? YES :
                        [[self leftViewController] shouldPerformSegueWithIdentifier:identifier sender:sender];
        rightIsGo = [self rightViewController] == nil ? YES :
                        [[self rightViewController] shouldPerformSegueWithIdentifier:identifier sender:sender];
    }
    return leftIsGo && rightIsGo;
}

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[self toolbarTop] setTintColor:[UIColor edaBlueDark]];

    UIView *leftView = [[self leftView] retain];
    UIView *rightView = [[self rightView] retain];

    [[self view] removeConstraints:[self bogusConstraints]];

    NSString *constraintAsciiArtHorizontal = @"H:|-(==0.0000)-[leftView(==320.0000)]-(==0.0000)-[rightView]-(==0.0000)-|";

    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(leftView, rightView);
    
    
    NSArray *constraintsHorizontal = [NSLayoutConstraint constraintsWithVisualFormat:constraintAsciiArtHorizontal
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:viewsDictionary];
    [[self view] addConstraints:constraintsHorizontal];
    
    [leftView release];
    [rightView release];

}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    if ([self leftView]) {
        NSMutableArray *subviews = [[NSMutableArray alloc] initWithArray:[[self leftView] subviews]];
        [subviews addObjectsFromArray:[[self rightView] subviews]];
        for (UIView *view in subviews) {
            if ([view isKindOfClass:[UIScrollView class]]) {
                CGFloat top = self.topLayoutGuide.length;
                CGFloat bot = self.bottomLayoutGuide.length;
                [(UIScrollView *)view setContentInset: UIEdgeInsetsMake(top, 0, bot, 0)];
                [(UIScrollView *)view setScrollIndicatorInsets: [(UIScrollView *)view contentInset]];
            }
        }
        [subviews release];
    }
    /*
    if ([self rightView]) {
        CGFloat top = self.topLayoutGuide.length;
        CGFloat bot = self.bottomLayoutGuide.length;
        [(UITableView *)[self leftView] setContentInset: UIEdgeInsetsMake(top, 0, bot, 0)];
        [(UITableView *)[self leftView] setScrollIndicatorInsets: [(UITableView *)[self leftView] contentInset]];
    }
     */
}

- (id)leftViewController {
    return [[[[self childViewControllers] objectAtIndex:0] retain] autorelease];
}

- (id)rightViewController {
    return [[[[self childViewControllers] objectAtIndex:1] retain] autorelease];
}

- (IBAction)showReportDocumentList:(id)sender {
    [[self delegate] viewControllerDidFinish:self animated:YES];
}

- (IBAction)showReportDesigner:(id)sender {
//    MTQueryBuilderViewController *queryBuilderController = [[self queryBuilderController] retain];
//    [queryBuilderController show]
//    [queryBuilderController release];
}

- (IBAction)toggleEditModeQueryDesigner:(id)sender {
    
    [[self queryBuilderController] edit:sender];
    BOOL isEditing = [self isEditing];
    [self setIsEditing: !isEditing];
    NSArray *items = [[[self navigationController] toolbar] items];
    NSMutableArray *tbItems = [items mutableCopy];
    NSUInteger buttonIndex = [tbItems indexOfObject:[self barButtonItemEdit]];
    if (buttonIndex != NSNotFound) {
        UIBarButtonSystemItem buttonType = isEditing ? UIBarButtonSystemItemEdit : UIBarButtonSystemItemDone;
        SEL toggleEditModeQueryDesigner = @selector(toggleEditModeQueryDesigner:);
        UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: buttonType
                                                                                       target: self
                                                                                       action: toggleEditModeQueryDesigner];
        
        
        [tbItems replaceObjectAtIndex:buttonIndex withObject: barButtonItem];
        [[[self navigationController] toolbar] setItems: tbItems animated:YES];
        [self setBarButtonItemEdit:barButtonItem];
        [barButtonItem release];
    }
    [tbItems release];

}

- (MTQueryBuilderViewController *)queryBuilderController {
    return [[[self rightViewController] retain] autorelease];
}

- (MTQueryBuilderAdvancedSchemaViewController *)queryBuilderControllerAdvanced {
    return [[[self leftViewController] retain] autorelease];
}

- (void)viewControllerDidFinish:(id)controller {
    [self viewControllerDidFinish:controller animated:YES];
}

- (void)viewControllerDidFinish:(id)sender animated:(BOOL)animated {
    [self dismissViewControllerAnimated:animated completion:^{
        if ([sender isKindOfClass:[NSNumber class]]) {
            if ([sender boolValue]) {
                [[self delegate] viewControllerDidFinish:self animated:YES];
            }
        }
    }];

}

@end
