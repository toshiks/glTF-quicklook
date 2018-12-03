//
//  SceneGenerator.h
//  glTF-qucklook
//
//  Created by Klochkov Anton on 03/12/2018.
//  Copyright © 2018 Klochkov Anton. All rights reserved.
//

#import <Foundation/Foundation.h>

@import SceneKit;

NS_ASSUME_NONNULL_BEGIN

@interface SceneGenerator : NSObject

+ (CFDataRef)sceneDataByURL:(CFURLRef)url;
+ (SCNScene *)sceneByURL:(CFURLRef)url;

@end

NS_ASSUME_NONNULL_END
