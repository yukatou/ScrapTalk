//
//  SCTViewController.m
//  ScrapTalk
//
//  Created by yukatou on 2014/02/15.
//  Copyright (c) 2014年 yukatou. All rights reserved.
//

#import "SCTViewController.h"

@interface SCTViewController ()

@end

@implementation SCTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    UILabel *roomLabel = (UILabel *)[cell viewWithTag:1];
    UIImageView *newImageView = (UIImageView *)[cell viewWithTag:3];
    
    switch (indexPath.row) {
        case 0:
            roomLabel.text = @"しょーごの部屋";
            break;
        case 1:
            roomLabel.text = @"ほげほげ";
            newImageView.hidden = YES;
            break;
        case 2:
            roomLabel.text = @"スペイン旅行中";
            break;
        default:
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
