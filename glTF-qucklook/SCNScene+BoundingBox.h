//
//  SCNScene+BoundingBox.h
//  glTF-qucklook
//
//  Created by Klochkov Anton on 03/12/2018.
//  Copyright © 2018 Klochkov Anton. All rights reserved.
//

@import SceneKit;

NS_ASSUME_NONNULL_BEGIN

@interface SCNScene (BoundingBox)

- (void) getBoundingBoxOfAllSceneMin:(nullable SCNVector3 *)min max:(nullable SCNVector3 *)max;

@end

NS_ASSUME_NONNULL_END
