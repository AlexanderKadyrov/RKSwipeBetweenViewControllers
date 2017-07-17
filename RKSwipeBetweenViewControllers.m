//
//  RKSwipeBetweenViewControllers.m
//  RKSwipeBetweenViewControllers
//
//  Created by Richard Kim on 7/24/14.
//  Copyright (c) 2014 Richard Kim. All rights reserved.
//
//  @cwRichardKim for regular updates

#import "RKSwipeBetweenViewControllers.h"

CGFloat X_BUFFER = 0.0;
CGFloat Y_BUFFER = 0;
CGFloat HEIGHT = 44.0;

CGFloat BOUNCE_BUFFER = 10.0;
CGFloat ANIMATION_SPEED = 0.2;
CGFloat SELECTOR_Y_BUFFER = 41.0;
CGFloat SELECTOR_HEIGHT = 3.0;

CGFloat X_OFFSET = 8.0;

@interface RKSwipeBetweenViewControllers () <UIPageViewControllerDelegate,UIPageViewControllerDataSource,UIScrollViewDelegate>
@property (nonatomic, strong) NSArray <UIColor *>*selectionColors;
@property (nonatomic, strong) NSArray <UIViewController *>*views;
@property (nonatomic, strong) UIPageViewController *pageViewController;
@property (nonatomic) UIScrollView *pageScrollView;
@property (nonatomic, strong) UIView *navigationView;
@property (nonatomic, strong) UIView *selectionBar;
@property (nonatomic) NSInteger currentPageIndex;
@property (nonatomic) BOOL isPageScrollingFlag;
@property (nonatomic) BOOL hasAppearedFlag;
@end

@implementation RKSwipeBetweenViewControllers

#pragma mark - Initialization

+ (instancetype)withViews:(NSArray <UIViewController *>*)views selectionColors:(NSArray <UIColor *>*)selectionColors {
    return [[self alloc] initWithViews:views selectionColors:selectionColors];
}

- (instancetype)initWithViews:(NSArray <UIViewController *>*)views selectionColors:(NSArray <UIColor *>*)selectionColors {
    
    UIPageViewController *controller = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                                       navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                                     options:nil];
    controller.view.backgroundColor = [UIColor whiteColor];
    
    self = [super initWithRootViewController:controller];
    
    if (self) {
        [self setNavigationBarDefaultColor];
        self.selectionColors = [selectionColors copy];
        self.views = [views copy];
        self.currentPageIndex = 0;
        self.isPageScrollingFlag = NO;
    }
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setNavigationBarDefaultColor];
    if ( ! self.hasAppearedFlag) {
        [self setupPageViewController];
        [self setupSegmentButtons];
        self.hasAppearedFlag = YES;
    }
}

#pragma mark - Setup

- (void)setupPageViewController {
    self.pageViewController = (UIPageViewController*)self.topViewController;
    self.pageViewController.delegate = self;
    self.pageViewController.dataSource = self;
    [self.pageViewController setViewControllers:@[[self.views objectAtIndex:0]] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
    [self syncScrollView];
}

- (void)setupSegmentButtons {
    
    self.navigationView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.navigationBar.frame.size.height)];
    
    NSInteger numControllers = self.views.count;
    
    [self.views enumerateObjectsUsingBlock:^(UIViewController *object, NSUInteger i, BOOL *stop) {
        UIButton *button = [[UIButton alloc]initWithFrame:CGRectMake(X_BUFFER+i*(self.view.frame.size.width-2*X_BUFFER)/numControllers-X_OFFSET, Y_BUFFER, (self.view.frame.size.width-2*X_BUFFER)/numControllers, HEIGHT)];
        [button setTag:i];
        [button.titleLabel setFont:[UIFont systemFontOfSize:14 weight:UIFontWeightRegular]];
        [button setTitleColor:(self.buttonColor ? self.buttonColor : [UIColor blackColor]) forState:UIControlStateNormal];
        [button addTarget:self action:@selector(tapSegmentButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [button setTitle:(object.title.length ? object.title : [NSString stringWithFormat:@"View - %lu", (unsigned long)index]) forState:UIControlStateNormal];
        [self.navigationView addSubview:button];
    }];
    
    self.pageViewController.navigationController.navigationBar.topItem.titleView = self.navigationView;
    
    self.selectionBar = [[UIView alloc] initWithFrame:CGRectMake(X_BUFFER-X_OFFSET, SELECTOR_Y_BUFFER, (self.view.frame.size.width-2*X_BUFFER)/self.views.count, SELECTOR_HEIGHT)];
    self.selectionBar.backgroundColor = [self selectionColorWithIndex:0];
    [self.navigationView addSubview:self.selectionBar];
}

#pragma mark - Set

- (void)setPageViewControllerColor:(UIColor *)pageViewControllerColor {
    _pageViewControllerColor = pageViewControllerColor;
    self.topViewController.view.backgroundColor = pageViewControllerColor;
}

- (void)setNavigationBarDefaultColor {
    [self.navigationBar setBackgroundImage:[self imageWithColor:[UIColor whiteColor]] forBarMetrics:UIBarMetricsDefault];
    self.navigationBar.translucent = NO;
}

- (void)setViewControllerIndex:(NSUInteger)index direction:(UIPageViewControllerNavigationDirection)direction animated:(BOOL)animated {
    if (index > self.views.count-1) {
        return;
    }
    [self.pageViewController setViewControllers:@[[self.views objectAtIndex:index]] direction:direction animated:animated completion:nil];
}

#pragma mark - Sync

- (void)syncScrollView {
    for (UIView* view in self.pageViewController.view.subviews){
        if([view isKindOfClass:[UIScrollView class]]) {
            self.pageScrollView = (UIScrollView *)view;
            self.pageScrollView.delegate = self;
        }
    }
}

#pragma mark - Movement

- (void)tapSegmentButtonAction:(UIButton *)button {
    if ( ! self.isPageScrollingFlag) {
        NSInteger tempIndex = self.currentPageIndex;
        __weak typeof(self) weakSelf = self;
        if (button.tag > tempIndex) {
            for (int i = (int)tempIndex+1; i<=button.tag; i++) {
                [self.pageViewController setViewControllers:@[[self.views objectAtIndex:i]] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:^(BOOL complete) {
                    if (complete) {
                        [weakSelf updateCurrentPageIndex:i];
                        [weakSelf.selectionBar setBackgroundColor:[weakSelf selectionColorWithIndex:i]];
                        if (weakSelf.blockTransitionCompletion) {
                            weakSelf.blockTransitionCompletion(i);
                        }
                    }
                }];
            }
        }
        else if (button.tag < tempIndex) {
            for (int i = (int)tempIndex-1; i >= button.tag; i--) {
                [self.pageViewController setViewControllers:@[[self.views objectAtIndex:i]] direction:UIPageViewControllerNavigationDirectionReverse animated:YES completion:^(BOOL complete){
                    if (complete) {
                        [weakSelf updateCurrentPageIndex:i];
                        [weakSelf.selectionBar setBackgroundColor:[weakSelf selectionColorWithIndex:i]];
                        if (weakSelf.blockTransitionCompletion) {
                            weakSelf.blockTransitionCompletion(i);
                        }
                    }
                }];
            }
        }
    }
}

- (void)updateCurrentPageIndex:(int)newIndex {
    self.currentPageIndex = newIndex;
}

#pragma mark - UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat xFromCenter = self.view.frame.size.width-scrollView.contentOffset.x;
    NSInteger xCoor = X_BUFFER+self.selectionBar.frame.size.width*self.currentPageIndex-X_OFFSET;
    self.selectionBar.frame = CGRectMake(xCoor-xFromCenter/self.views.count, self.selectionBar.frame.origin.y, self.selectionBar.frame.size.width, self.selectionBar.frame.size.height);
}

#pragma mark - Page View Controller Data Source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    NSInteger index = [self.views indexOfObject:viewController];
    if ((index == NSNotFound) || (index == 0)) {
        return nil;
    }
    index--;
    return [self.views objectAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    NSInteger index = [self.views indexOfObject:viewController];
    if (index == NSNotFound) {
        return nil;
    }
    index++;
    if (index == self.views.count) {
        return nil;
    }
    return [self.views objectAtIndex:index];
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed {
    if (completed) {
        self.currentPageIndex = [self.views indexOfObject:[pageViewController.viewControllers lastObject]];
        self.selectionBar.backgroundColor = [self selectionColorWithIndex:self.currentPageIndex];
        if (self.blockTransitionCompletion) {
            self.blockTransitionCompletion(self.currentPageIndex);
        }
    }
}

#pragma mark - Scroll View Delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.isPageScrollingFlag = YES;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.isPageScrollingFlag = NO;
}

#pragma mark - Other

- (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

- (UIColor *)selectionColorWithIndex:(NSInteger)index {
    if ( ! self.selectionColors.count) {
        return [UIColor colorWithWhite:40.0f / 255.0f alpha:1.0f];
    }
    else if (index > self.selectionColors.count-1) {
        return self.selectionColors.firstObject;
    }
    return self.selectionColors[index];
}

@end
