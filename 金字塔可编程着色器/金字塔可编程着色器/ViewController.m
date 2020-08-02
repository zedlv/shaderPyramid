//
//  ViewController.m
//  金字塔可编程着色器
//
//  Created by lvAsia on 2020/8/1.
//  Copyright © 2020 yazhou lv. All rights reserved.
//

#import "ViewController.h"
#import "MyView.h"
@interface ViewController ()
@property(nonatomic, strong) MyView *myview;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.myview = (MyView *)self.view;
}


@end
