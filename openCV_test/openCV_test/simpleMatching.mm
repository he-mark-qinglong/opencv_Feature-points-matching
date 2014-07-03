//
//  simpleMatching.cpp
//  openCV_test
//
//  Created by mark on 14-6-3.
//  Copyright (c) 2014年 mark. All rights reserved.
//

#include "simpleMatching.h"

//#define DRAW_RICH_KEYPOINTS_MODE 1  //mark definition
//#define DRAW_OUTLIERS_MODE 1  //mark definition

const string winName = "correspondences";

enum { NONE_FILTER = 0, CROSS_CHECK_FILTER = 1 };

int getMatcherFilterType( const string& str )
{
    if( str == "NoneFilter" )
        return NONE_FILTER;
    if( str == "CrossCheckFilter" )
        return CROSS_CHECK_FILTER;
    CV_Error(CV_StsBadArg, "Invalid filter name");
    return -1;
}

static void simpleMatching( Ptr<DescriptorMatcher>& descriptorMatcher,
                           const Mat& descriptors1, const Mat& descriptors2,
                           vector<DMatch>& matches12 )
{
    descriptorMatcher->match( descriptors1, descriptors2, matches12 );
}

static void crossCheckMatching( Ptr<DescriptorMatcher>& descriptorMatcher,
                               const Mat& descriptors1, const Mat& descriptors2,
                               vector<DMatch>& filteredMatches12, int knn=1 )
{
    filteredMatches12.clear();
    vector<vector<DMatch> > matches12, matches21;
    descriptorMatcher->knnMatch( descriptors1, descriptors2, matches12, knn );
    descriptorMatcher->knnMatch( descriptors2, descriptors1, matches21, knn );
    for( size_t m = 0; m < matches12.size(); m++ ){
        bool findCrossCheck = false;
        for( size_t fk = 0; fk < matches12[m].size(); fk++ ){
            DMatch forward = matches12[m][fk];
            
            for( size_t bk = 0; bk < matches21[forward.trainIdx].size(); bk++ ){
                DMatch backward = matches21[forward.trainIdx][bk];
                if( backward.trainIdx == forward.queryIdx ){
                    filteredMatches12.push_back(forward);
                    findCrossCheck = true;
                    break;
                }
            }
            if( findCrossCheck ) break;
        }
    }
}

static void warpPerspectiveRand( const Mat& src, Mat& dst, Mat& H, RNG& rng )
{
    H.create(3, 3, CV_32FC1);
    H.at<float>(0,0) = rng.uniform( 0.8f, 1.2f);
    H.at<float>(0,1) = rng.uniform(-0.1f, 0.1f);
    H.at<float>(0,2) = rng.uniform(-0.1f, 0.1f) * src.cols;
    H.at<float>(1,0) = rng.uniform(-0.1f, 0.1f);
    H.at<float>(1,1) = rng.uniform( 0.8f, 1.2f);
    H.at<float>(1,2) = rng.uniform(-0.1f, 0.1f) * src.rows;
    H.at<float>(2,0) = rng.uniform(-1e-4f, 1e-4f);
    H.at<float>(2,1) = rng.uniform(-1e-4f, 1e-4f);
    H.at<float>(2,2) = rng.uniform( 0.8f, 1.2f);
    
    warpPerspective( src, dst, H, src.size() );
}

Mat doIteration( const Mat& img1, Mat& img2, bool isWarpPerspective,
                vector<KeyPoint>& keypoints1, const Mat& descriptors1,
                Ptr<FeatureDetector>& detector, Ptr<DescriptorExtractor>& descriptorExtractor,
                Ptr<DescriptorMatcher>& descriptorMatcher, int matcherFilter, bool eval,
                double ransacReprojThreshold, RNG& rng )
{
    Mat H1to2;
    if( isWarpPerspective )
        warpPerspectiveRand(img1, img2, H1to2, rng );
    
    cout << endl << "< Extracted keypoints from second image...";
    vector<KeyPoint> keypoints2;
    detector->detect( img2, keypoints2 );
    cout << keypoints2.size() << " points" << ">" << endl;
    
    if( !H1to2.empty() && eval ){
        cout << "< Evaluate feature detector..." << endl;
        float repeatability;
        int correspCount;
        evaluateFeatureDetector( img1, img2, H1to2, &keypoints1, &keypoints2,
                                repeatability, correspCount );
        cout << "repeatability = " << repeatability << endl;
        cout << "correspCount = " << correspCount << endl << ">" << endl;
    }
    
    cout << "< Computing descriptors for keypoints from second image...";
    Mat descriptors2;
    descriptorExtractor->compute( img2, keypoints2, descriptors2 );
    cout << ">" << endl;
    
    cout << "< Matching descriptors...";
    vector<DMatch> filteredMatches;
    switch( matcherFilter ){
        case CROSS_CHECK_FILTER :
            crossCheckMatching( descriptorMatcher, descriptors1, descriptors2, filteredMatches, 1 );
            break;
        default :
            simpleMatching( descriptorMatcher, descriptors1, descriptors2, filteredMatches );
    }
    cout << ">" << endl;
    descriptors2.release();
    
    if( !H1to2.empty() && eval ){
        cout << "< Evaluate descriptor matcher..." << endl;
        vector<Point2f> curve;
        Ptr<GenericDescriptorMatcher> gdm =
        new VectorDescriptorMatcher( descriptorExtractor, descriptorMatcher );
        evaluateGenericDescriptorMatcher( img1, img2, H1to2,
                                         keypoints1, keypoints2, 0, 0, curve, gdm );
        
        Point2f firstPoint = *curve.begin();
        Point2f lastPoint = *curve.rbegin();
        int prevPointIndex = -1;
        cout << "1-precision = " << firstPoint.x << "; recall = " << firstPoint.y << endl;
        for( float l_p = 0; l_p <= 1 + FLT_EPSILON; l_p+=0.05f ){
            int nearest = getNearestPoint( curve, l_p );
            if( nearest >= 0 ){
                Point2f curPoint = curve[nearest];
                if( curPoint.x > firstPoint.x && curPoint.x < lastPoint.x &&
                   nearest != prevPointIndex ){
                    cout << "1-precision = " << curPoint.x << "; recall = " << curPoint.y << endl;
                    prevPointIndex = nearest;
                }
            }
        }
        cout <<"1-precision = " << lastPoint.x << "; recall = " << lastPoint.y << ">" << endl;
    }
    
    vector<int> queryIdxs( filteredMatches.size() ), trainIdxs( filteredMatches.size() );
    for( size_t i = 0; i < filteredMatches.size(); i++ ){
        queryIdxs[i] = filteredMatches[i].queryIdx;
        trainIdxs[i] = filteredMatches[i].trainIdx;
    }
    
    if( !isWarpPerspective && ransacReprojThreshold >= 0 ){
        cout << "< Computing homography (RANSAC)...";
        vector<Point2f> points1, points2;
        KeyPoint::convert(keypoints1, points1, queryIdxs);
        KeyPoint::convert(keypoints2, points2, trainIdxs);
        H1to2 = findHomography( Mat(points1), Mat(points2), CV_RANSAC, ransacReprojThreshold );
        cout << ">" << endl;
    }
    
    Mat drawImg;
    if( !H1to2.empty() ){   // filter outliers
        vector<char> matchesMask( filteredMatches.size(), 0 );
        vector<Point2f> points1, points2;
        KeyPoint::convert(keypoints1, points1, queryIdxs);
        KeyPoint::convert(keypoints2, points2, trainIdxs);
        Mat points1t;
        perspectiveTransform(Mat(points1), points1t, H1to2);
        
        double maxInlierDist = ransacReprojThreshold < 0 ? 3 : ransacReprojThreshold;
        for( size_t i1 = 0; i1 < points1.size(); i1++ ){
            if( norm(points2[i1] - points1t.at<Point2f>((int)i1,0)) <= maxInlierDist ) // inlier
                matchesMask[i1] = 1;
        }
        // draw inliers
        drawMatches( img1, keypoints1, img2, keypoints2,
                    filteredMatches, drawImg, CV_RGB(0, 255, 0), CV_RGB(0, 0, 255), matchesMask
#if DRAW_RICH_KEYPOINTS_MODE
                    , DrawMatchesFlags::DRAW_RICH_KEYPOINTS
#endif
                    );
        
#if DRAW_OUTLIERS_MODE     // draw outliers
        for( size_t i1 = 0; i1 < matchesMask.size(); i1++ )
            matchesMask[i1] = !matchesMask[i1];
        drawMatches( img1, keypoints1, img2, keypoints2, filteredMatches,  drawImg,
                    CV_RGB(0, 0, 255), CV_RGB(255, 0, 0), matchesMask,
                    DrawMatchesFlags::DRAW_OVER_OUTIMG | DrawMatchesFlags::NOT_DRAW_SINGLE_POINTS );
#endif
        
        cout << "Number of inliers: " << countNonZero(matchesMask) << endl;
    }else
        drawMatches( img1, keypoints1, img2, keypoints2, filteredMatches, drawImg );
    
    return  drawImg;
}

UIImage * getMatch( Mat & img1, Mat & img2)
{
    if( img1.empty() ||  img2.empty() ){
        cout << "Can not read images" << endl;
        exit(-1);
    }
    cv::initModule_nonfree();  ////if use SIFT or SURF
    
    bool isWarpPerspective                       = 0;
    double ransacReprojThreshold                 = 3;
    Ptr<FeatureDetector> detector                = FeatureDetector::create( "SURF" );
    Ptr<DescriptorExtractor> descriptorExtractor = DescriptorExtractor::create( "SURF");
    Ptr<DescriptorMatcher> descriptorMatcher     = DescriptorMatcher::create( "BruteForce");
    if( detector.empty() || descriptorExtractor.empty() || descriptorMatcher.empty()){
        cout<< "detector:" << detector.empty()
        << "descriptor exstractor:" << descriptorExtractor.empty()
        << "descriptor:"<<descriptorMatcher.empty()
        <<endl;
        exit(-1);
    }
    
    vector<KeyPoint> keypoints1;
    detector->detect( img1, keypoints1 );
    cout << "Extracted keypoints from first image: " << keypoints1.size() << " points"<< endl;
    
    Mat descriptors1;
    descriptorExtractor->compute( img1, keypoints1, descriptors1 );
    cout << "Computed descriptors for keypoints from first image..." << endl;
    
    RNG rng               = theRNG();
    int mactherFilterType = getMatcherFilterType( "CrossCheckFilter");
    bool eval             = false;
    
    Mat retImg = doIteration( img1, img2, isWarpPerspective, keypoints1, descriptors1,
                             detector, descriptorExtractor, descriptorMatcher, mactherFilterType,
                             eval, ransacReprojThreshold, rng);
    UIImage *image = [UIImage UIImageFromCVMat: retImg];
    
    retImg.release();
    detector.release();
    descriptorExtractor.release();
    descriptorMatcher.release();
    descriptors1.release();
    img1.release();
    img2.release();
    
    return image;
}