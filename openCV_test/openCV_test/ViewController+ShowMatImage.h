//
//  ViewController+ShowMatImage.h
//  openCV_test
//
//  Created by mark on 14-6-17.
//  Copyright (c) 2014年 mark. All rights reserved.
//

#import "ViewController.h"

#import <opencv2/highgui/cap_ios.h>

#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/nonfree/features2d.hpp>
#include <opencv2/legacy/legacy.hpp>
#include <opencv2/nonfree/nonfree.hpp>


@interface ViewController (ShowMatImage)
- (void) showImage:(cv::Mat)image;
- (void) showImage:(cv::Mat)image image2:(cv::Mat)image2;
@end
