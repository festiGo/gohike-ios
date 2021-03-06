//
//  NavigationStatusView.h
//  ScavengerApp
//
//  Created by Taco van Dijk on 5/28/13.
//  Copyright (c) 2013 Code for Europe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "NSLayoutConstraint+EvenDistribution.h"

@interface NavigationStatusView : UIView

@property (nonatomic, weak) IBOutlet UIView * checkinsView;//just a container view

-(void)setCheckinsCompleteWithArray:(NSArray*)array nextLocationId:(int)location_id;

@end
