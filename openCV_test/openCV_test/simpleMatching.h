//
//  simpleMatching.h
//  openCV_test
//
//  Created by mark on 14-6-3.
//  Copyright (c) 2014年 mark. All rights reserved.
//

#ifndef __openCV_test__simpleMatching__
#define __openCV_test__simpleMatching__

#include <iostream>
#import <opencv2/highgui/cap_ios.h>

#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/nonfree/features2d.hpp>
#include <opencv2/legacy/legacy.hpp>
#include <opencv2/nonfree/nonfree.hpp>

#import "UIImage+OpenCV.h"

using namespace cv;
using namespace std;
/*
UIImage* doIteration( const Mat& img1, Mat& img2, bool isWarpPerspective,
                            vector<KeyPoint>& keypoints1, const Mat& descriptors1,
                            Ptr<FeatureDetector>& detector, Ptr<DescriptorExtractor>& descriptorExtractor,
                            Ptr<DescriptorMatcher>& descriptorMatcher, int matcherFilter, bool eval,
                            double ransacReprojThreshold, RNG& rng );
int getMatcherFilterType( const string& str );
*/
UIImage * getMatch( Mat &image1, Mat &image2);
#endif /* defined(__openCV_test__simpleMatching__) */
