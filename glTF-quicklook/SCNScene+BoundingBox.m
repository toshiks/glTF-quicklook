//
//  SCNScene+BoundingBox.m
//  glTF-qucklook
//
//  Created by Klochkov Anton on 03/12/2018.
//  Copyright © 2018 Klochkov Anton. All rights reserved.
//

#import "SCNScene+BoundingBox.h"

@implementation SCNScene (BoundingBox)

- (void) getBoundingBoxOfAllSceneMin:(nullable SCNVector3 *)min max:(nullable SCNVector3 *)max {
    *min = SCNVector3Make(CGFLOAT_MAX, CGFLOAT_MAX, CGFLOAT_MAX);
    *max = SCNVector3Make(CGFLOAT_MIN, CGFLOAT_MIN, CGFLOAT_MIN);
    
    [self.rootNode enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
        if(child.geometry != nil){
            SCNVector3 childMin;
            SCNVector3 childMax;
            [child.geometry getBoundingBoxMin:&childMin max:&childMax];
            
            min->x = MIN(min->x, childMin.x + child.worldPosition.x);
            min->y = MIN(min->y, childMin.y + child.worldPosition.y);
            min->z = MIN(min->z, childMin.z + child.worldPosition.z);
            
            max->x = MAX(max->x, childMax.x + child.worldPosition.x);
            max->y = MAX(max->y, childMax.y + child.worldPosition.y);
            max->z = MAX(max->z, childMax.z + child.worldPosition.z);
        }
    }];
}

@end
