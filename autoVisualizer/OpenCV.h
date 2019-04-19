//
//  OpenCV.h
//  autoVisualizer
//
//  Created by kehwaweng on 2019/4/2.
//  Copyright © 2019 kehwaweng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenCV : NSObject

+ (NSMutableDictionary *)cvGetFeature:(nonnull NSImage *)image;
+ (bool)cvCheckGrayscale:(nonnull NSImage *)image;
@end

NS_ASSUME_NONNULL_END
