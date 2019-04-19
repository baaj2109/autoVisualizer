//
//  OpenCV.m
//  autoVisualizer
//
//  Created by kehwaweng on 2019/4/2.
//  Copyright © 2019 kehwaweng. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import <opencv2/imgproc.hpp>
#import <opencv2/highgui.hpp>
#import <opencv2/features2d.hpp>
#import <opencv2/core.hpp>
#import <Cocoa/Cocoa.h>
#import "OpenCV.h"

static void NSImageToMat(NSImage *image, cv::Mat &mat) {
    
    // Create a pixel buffer.
    NSBitmapImageRep *bitmapImageRep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];
    NSInteger width                  = [bitmapImageRep pixelsWide];
    NSInteger height                 = [bitmapImageRep pixelsHigh];
    CGImageRef imageRef              = [bitmapImageRep CGImage];
    cv::Mat mat8uc4                  = cv::Mat((int)height, (int)width, CV_8UC4);
    CGColorSpaceRef colorSpace       = CGColorSpaceCreateDeviceRGB();
    CGContextRef contextRef          = CGBitmapContextCreate(mat8uc4.data, mat8uc4.cols, mat8uc4.rows, 8, mat8uc4.step, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault);
    CGContextDrawImage(contextRef, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    
    // Draw all pixels to the buffer.
    cv::Mat mat8uc3 = cv::Mat((int)width, (int)height, CV_8UC3);
    cv::cvtColor(mat8uc4, mat8uc3, CV_RGBA2BGR);
    
    mat = mat8uc3;
}



static double getEntropy (cv::Mat image){
    std::vector<cv::Mat> channels;
    cv::split( image, channels );
    
    int histSize = 256;
    float range[] = { 0, 256 } ;
    const float* histRange = { range };
    bool uniform = true;
    bool accumulate = false;
    cv::Mat hist0, hist1, hist2;
    
    cv::calcHist( &channels[0], 1, 0, cv::Mat(), hist0, 1, &histSize, &histRange, uniform, accumulate );
    cv::calcHist( &channels[1], 1, 0, cv::Mat(), hist1, 1, &histSize, &histRange, uniform, accumulate );
    cv::calcHist( &channels[2], 1, 0, cv::Mat(), hist2, 1, &histSize, &histRange, uniform, accumulate );
    //frequency
    float count = 0;
    for (int i=0;i<histSize;i++){
        count += hist0.at<float>(i) + hist1.at<float>(i) + hist2.at<float>(i);
    }
    //entropy
    cv::Scalar e;
    e.val[0]=0;
    float p;
    
    for (int i=0;i<histSize;i++){
        p = (abs(hist0.at<float>(i)) + abs(hist1.at<float>(i)) + abs(hist2.at<float>(i))) / count;
        if(p != 0){
            e.val[0] += -p*log2(p);
        }
    }
    return e.val[0];
}


static double getBrightness(cv::Mat image){
    
//    double brightness = 0;
    int histSize = 256;
    float range[] = { 0, 256 } ;
    const float* histRange = { range };
    bool uniform = true;
    bool accumulate = false;
    cv::Mat hist;
    int channels[] = {0};
    cv::calcHist( &image, 1, channels, cv::Mat(), hist, 1, &histSize, &histRange, uniform, accumulate );
    int pixelCount =0;
    for(int i = 0; i < histSize; i++){
//        std::cout<<"index: "<<i<<" value: "<<hist.at<float>(i)<<std::endl;
        pixelCount += hist.at<float>(i);
    }
    double brightness = 256;
    int scale = 256;
    for(int i=0; i<scale; i++){
        double ratio = hist.at<float>(i) / pixelCount;
        brightness += ratio * (-scale + i);
    }
    
    return brightness;
}

static bool checkGrayscale(cv::Mat rgbMat){
    for(int i = 0 ; i < rgbMat.rows ; i++){
        cv::Vec3b* ptr = rgbMat.ptr<cv::Vec3b>(i);
        for(int j = 0 ; j < rgbMat.cols ; j++){
            if(!(ptr[j][0] == ptr[j][1] && ptr[j][0] == ptr[j][2])) {
                return false;
            }
        }
    }
    return true;
}

@implementation OpenCV


+ (bool)cvCheckGrayscale:(NSImage *)image{
    cv::Mat rgbMat;
    NSImageToMat(image, rgbMat);
    bool flag = checkGrayscale(rgbMat);
    return flag;
}

+ (NSMutableDictionary *)cvGetFeature:(NSImage *)image{
    NSMutableDictionary *mutableDict = [[NSMutableDictionary alloc] init];
    cv::Mat rgbMat, grayMat;
    NSImageToMat(image, rgbMat);
    cv::cvtColor(rgbMat, grayMat, CV_BGR2GRAY);
    /*
        contrast , feature:index contrast:0
     */
    double min, max, contrast;
    cv::minMaxLoc(grayMat, &min, &max);
    //std::cout<<"max: "<<max<<" min: "<<min<<std::endl;
    contrast = (max - min)/(max + min);
//    std::cout<<"contrast: "<<contrast<<std::endl;
    
    NSString *str = [NSString stringWithFormat:@"%d", 0];
    NSNumber *num = [NSNumber numberWithDouble:contrast];
    [mutableDict setValue: num forKey:str];
    
    /*
        mean and std , feature:index bmean:1 , bstd:2 , gmean:3 , gstd:4 , rmean:5 , rstd:6 ,
     */
    std::vector<double> rgbMean,rgbStd;
    cv::meanStdDev(rgbMat, rgbMean, rgbStd);
    std::vector<int> meanIndex = {1,3,5};
    std::vector<int> stdIndex  = {2,4,6};
    for(int i = 0 ; i< rgbMean.size() ; i++ ){
//        std::cout<<"mean: "<<rgbMean[i]<<" stddev: "<<rgbStd[i]<<std::endl;
        NSString *sMean = [NSString stringWithFormat:@"%d", meanIndex[i]];
        NSNumber *nMean = [NSNumber numberWithDouble:rgbMean[i]];
        [mutableDict setValue: nMean forKey:sMean];
        NSString *sStd = [NSString stringWithFormat:@"%d", stdIndex[i]];
        NSNumber *nStd = [NSNumber numberWithDouble:rgbStd[i]];
        [mutableDict setValue: nStd forKey:sStd];
    }
    
    /*
        moments , feature:index hmean:7 , hstd:8 , smean:9 , sstd:10 , vmean:11 , vstd:12 ,
                               hmoment:13 , smoment:14 , vmoment:15
     */
    cv::Mat hsv,h,s,v;
    std::vector<cv::Mat> matOneChan(3);
    cv::cvtColor(rgbMat, hsv, CV_BGR2HSV);
    cv::split(hsv, matOneChan);
    std::vector<double> hsvMean, hsvStd;
    cv::meanStdDev(hsv, hsvMean, hsvStd);
    cv::Scalar h_skewness, s_skewness, v_skewness;
    meanIndex = {7,9,11};
    stdIndex  = {8,10,12};
    for(int i = 0 ; i <hsvMean.size();i++){
//        std::cout<<"hsvMean: "<<hsvMean[i]<<" hsvstd: "<<hsvStd[i]<<std::endl;
        
        NSString *sMean = [NSString stringWithFormat:@"%d", meanIndex[i]];
        NSNumber *nMean = [NSNumber numberWithDouble:hsvMean[i]];
        [mutableDict setValue: nMean forKey:sMean];
        NSString *sStd = [NSString stringWithFormat:@"%d", stdIndex[i]];
        NSNumber *nStd = [NSNumber numberWithDouble:hsvStd[i]];
        [mutableDict setValue: nStd forKey:sStd];
        
    }
    matOneChan[0].convertTo(h, CV_16S);
    h = cv::abs(h - hsvMean[0]);
    cv::pow(h, 3, h);
    cv::Scalar mean = cv::mean(h);
    double h_moment = std::pow(mean.val[0], 1.0/3);
//    std::cout<<"h moment: "<<h_moment<<std::endl;
    NSString *strh = [NSString stringWithFormat:@"%d", 13];
    NSNumber *numh = [NSNumber numberWithDouble:h_moment];
    [mutableDict setValue: numh forKey:strh];
    
    matOneChan[1].convertTo(s, CV_16S);
    s = cv::abs(s - hsvMean[1]);
    cv::pow(s, 3, s);
    mean = cv::mean(s);
    double s_moment = std::pow(mean.val[0], 1.0/3);
//    std::cout<<"s moment: "<<s_moment<<std::endl;
    NSString *strs = [NSString stringWithFormat:@"%d", 14];
    NSNumber *nums = [NSNumber numberWithDouble:s_moment];
    [mutableDict setValue: nums forKey:strs];
    
    
    matOneChan[2].convertTo(v, CV_16S);
    v = cv::abs(v - hsvMean[2]);
    cv::pow(v, 3, v);
    mean = cv::mean(v);
    double v_moment = std::pow(mean.val[0], 1.0/3);
//    std::cout<<"v moment: "<<v_moment<<std::endl;
    NSString *strv = [NSString stringWithFormat:@"%d", 15];
    NSNumber *numv = [NSNumber numberWithDouble:v_moment];
    [mutableDict setValue: numv forKey:strv];
    
    /*
        entropy , feature:index entropy:16
     */
    double entropy = getEntropy(rgbMat);
//    std::cout<<"entropy: "<<entropy<<std::endl;
    NSString *strEntropy = [NSString stringWithFormat:@"%d", 16];
    NSNumber *numEntropy = [NSNumber numberWithDouble:entropy];
    [mutableDict setValue: numEntropy forKey:strEntropy];
    
    /*
        brightness , feature:index brightness:17
     */
    double brightness = getBrightness(rgbMat);
//    std::cout<<"brightness: "<<brightness<<std::endl;
    NSString *strBrightness = [NSString stringWithFormat:@"%d", 17];
    NSNumber *numBrightness = [NSNumber numberWithDouble:brightness];
    [mutableDict setValue: numBrightness forKey:strBrightness];
    
    
    return mutableDict;
};


@end
