//
//  ThumbnailGenerator.m
//  glTF-qucklook
//
//  Created by Klochkov Anton on 03/12/2018.
//  Copyright © 2018 Klochkov Anton. All rights reserved.
//

#import "ThumbnailGenerator.h"
#import "SceneGenerator.h"
#import "SCNScene+BoundingBox.h"

#define MAX_SIZE 700

@implementation ThumbnailGenerator

+ (NSImage *) thumbnailImageByURL:(CFURLRef)url rect:(NSRect)rect {
    SCNScene *scene = [SceneGenerator sceneByURL:url];
    
    SCNVector3 sceneMin;
    SCNVector3 sceneMax;
    
    [scene getBoundingBoxOfAllSceneMin:&sceneMin max:&sceneMax];
    
    SCNNode *cameraNode = [SCNNode node];
    cameraNode.camera = [SCNCamera camera];
    
    cameraNode.camera.automaticallyAdjustsZRange = true;
    
    CGFloat dz = MIN(MAX(sceneMax.x - sceneMin.x, sceneMax.y - sceneMin.y), MAX_SIZE);
    if(cameraNode.camera.zNear > dz){
        cameraNode.camera.zNear = dz;
    }
    
    CGFloat wz = dz +sceneMax.z - sceneMin.z;
    if(cameraNode.camera.zFar < wz){
        cameraNode.camera.zFar = wz;
    }
    
    cameraNode.position = SCNVector3Make((sceneMax.x + sceneMin.x) * 0.5, (sceneMax.y + sceneMin.y) * 0.5, sceneMax.z + dz);
    [scene.rootNode addChildNode:cameraNode];
    
    SCNView *view = [[SCNView alloc] initWithFrame:rect options:nil];
    view.autoenablesDefaultLighting = true;
    view.scene = scene;
    view.pointOfView = cameraNode;
    
    return [view snapshot];
}

@end
