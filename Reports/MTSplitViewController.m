//
//  ViewController.m
//  MTSplitViewController
//
//  Created by Michael Thomason on 2/13/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTSplitViewController.h"

@interface MTSplitViewController ()

@property (retain, nonatomic) IBOutlet UIView *leftView;
@property (retain, nonatomic) IBOutlet UIView *rightView;
@property (retain, nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *bogusConstraints;

@end

@implementation MTSplitViewController

- (void)dealloc {
    [_leftView release];
    [_rightView release];
    [_bogusConstraints release];
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
    NSLog(@"%@ %@", [[self childViewControllers] objectAtIndex:0], [[self childViewControllers] objectAtIndex:1]);
	// Do any additional setup after loading the view, typically from a nib.
//    NSMutableArray *viewControllers = [[NSMutableArray alloc] initWithCapacity:2];
    
//    UIStoryboard *sb = [[UIStoryboard storyboardWithName:MTStoryboardSplitViewController bundle:nil] retain];
    
//    UIViewController *childViewControllerLeft = [[sb instantiateViewControllerWithIdentifier:MTBlueViewControllerIdentifier] retain];
//    UIViewController *childViewControllerRight = [[sb instantiateViewControllerWithIdentifier:MTRedViewControllerIdentifier] retain];
    
//    [viewControllers addObject:childViewControllerLeft];
//    [viewControllers addObject:childViewControllerRight];
    
//    [self setViewControllers:viewControllers];
    
//    [sb release];
    
//    [viewControllers release];
    [[self delegate] displayContentController:
     [[[[self childViewControllers] objectAtIndex:0] retain] autorelease]];
    
    [[self delegate] displayContentController:
     [[[[self childViewControllers] objectAtIndex:1] retain] autorelease]];
    

    
}

- (id)leftViewController {
    return [[[[self childViewControllers] objectAtIndex:0] retain] autorelease];
}

- (id)rightViewController {
    return [[[[self childViewControllers] objectAtIndex:1] retain] autorelease];
}

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    UIView *leftView = [[self leftView] retain];
    UIView *rightView = [[self rightView] retain];

    //CGFloat leftViewWidth = 320.0000f;
    //CGRect leftFrame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, leftViewWidth, self.view.frame.size.height);
    //[leftView setFrame:leftFrame];
    
    //CGRect rightFrame = CGRectMake(self.view.frame.origin.x + leftViewWidth, self.view.frame.origin.y, self.view.frame.size.width -leftViewWidth, self.view.frame.size.height);
    //[rightView setFrame:rightFrame];

    
    
    //[leftView setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin];
    //[rightView setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin];

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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setBogusConstraints:nil];
    [super viewDidUnload];
}
@end
