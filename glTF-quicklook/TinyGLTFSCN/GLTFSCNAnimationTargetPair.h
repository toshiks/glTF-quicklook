//
//  GLTFSCNAnimationTargetPair.h
//  glTF-quicklook
//
//  Created by Klochkov Anton on 14/09/2019.
//  Copyright © 2019 Klochkov Anton. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface GLTFSCNAnimationTargetPair : NSObject
@property (nonatomic, strong) CAAnimation *animation;
@property (nonatomic, strong) SCNNode *target;
@end

NS_ASSUME_NONNULL_END
