//
//  TinyGLTFSCN.m
//  glTF-quicklook
//
//  Created by Klochkov Anton on 12/06/2019.
//  Copyright © 2019 Klochkov Anton. All rights reserved.
//

#define TINYGLTF_IMPLEMENTATION
#define STB_IMAGE_IMPLEMENTATION
#define TINYGLTF_NO_STB_IMAGE_WRITE
#define TINYGLTF_ENABLE_DRACO
#define TINYGLTF_USE_CPP14
#define TINYGLTF_NO_EXTERNAL_IMAGE

#import "TinyGLTFSCN.h"
#import "GLTFSCNAnimationTargetPair.h"
#include "tiny_gltf.h"

typedef struct __attribute__((packed)) {
    float x, y, z;
} GLTFVector3;

typedef struct __attribute__((packed)) {
    float x, y, z, w;
} GLTFVector4;

typedef struct __attribute__((packed)) {
    GLTFVector4 columns[4];
} GLTFMatrix4;

static SCNMatrix4 GLTFSCNMatrix4FromFloat4x4(GLTFMatrix4 m) {
    SCNMatrix4 mOut = (SCNMatrix4) {
        m.columns[0].x, m.columns[0].y, m.columns[0].z, m.columns[0].w,
        m.columns[1].x, m.columns[1].y, m.columns[1].z, m.columns[1].w,
        m.columns[2].x, m.columns[2].y, m.columns[2].z, m.columns[2].w,
        m.columns[3].x, m.columns[3].y, m.columns[3].z, m.columns[3].w
    };
    return mOut;
}

const std::string  GLTFAttributeSemanticPosition  = "POSITION";
const std::string  GLTFAttributeSemanticTangent   = "TANGENT";
const std::string  GLTFAttributeSemanticNormal    = "NORMAL";
const std::string  GLTFAttributeSemanticTexCoord0 = "TEXCOORD_0";
const std::string  GLTFAttributeSemanticTexCoord1 = "TEXCOORD_1";
const std::string  GLTFAttributeSemanticColor0    = "COLOR_0";
const std::string  GLTFAttributeSemanticJoints0   = "JOINTS_0";
const std::string  GLTFAttributeSemanticJoints1   = "JOINTS_1";
const std::string  GLTFAttributeSemanticWeights0  = "WEIGHTS_0";
const std::string  GLTFAttributeSemanticWeights1  = "WEIGHTS_1";
const std::string  GLTFAttributeSemanticRoughness = "ROUGHNESS";
const std::string  GLTFAttributeSemanticMetallic  = "METALLIC";

typedef NS_ENUM(NSInteger, TinyImageChannel) {
    TinyImageChannelRed,
    TinyImageChannelGreen,
    TinyImageChannelBlue,
    TinyImageChannelAlpha,
    TinyImageChannelAll = 255
};


typedef NS_ENUM(NSInteger, GLTF_TYPE) {
    GLTF_TYPE_GLTF,
    GLTF_TYPE_GLB
};


static SCNGeometryPrimitiveType TinyGLTFSCNGeometryPrimitiveTypeForPrimitiveType(NSInteger primitiveType) {
    switch (primitiveType) {
        case TINYGLTF_MODE_POINTS:
            return SCNGeometryPrimitiveTypePoint;
        case TINYGLTF_MODE_LINE:
            return SCNGeometryPrimitiveTypeLine;
        case TINYGLTF_MODE_TRIANGLES:
            return SCNGeometryPrimitiveTypeTriangles;
        case TINYGLTF_MODE_TRIANGLE_STRIP:
            return SCNGeometryPrimitiveTypeTriangleStrip;
        default:
            // Unsupported: line loop, line strip, triangle fan
            return SCNGeometryPrimitiveTypePolygon;
    }
}

static NSInteger TinyGLTFPrimitiveCountForIndexCount(NSInteger indexCount, SCNGeometryPrimitiveType primitiveType) {
    switch (primitiveType) {
        case SCNGeometryPrimitiveTypePoint:
            return indexCount;
        case SCNGeometryPrimitiveTypeLine:
            return indexCount / 2;
        case SCNGeometryPrimitiveTypeTriangles:
            return indexCount / 3;
        case SCNGeometryPrimitiveTypeTriangleStrip:
            return indexCount - 2;
        case SCNGeometryPrimitiveTypePolygon:
            return 1;
        default:
            return 0;
    }
}

static SCNWrapMode GLTFSCNWrapModeForAddressMode(int mode) {
    switch (mode) {
        case TINYGLTF_TEXTURE_WRAP_CLAMP_TO_EDGE:
            return SCNWrapModeClamp;
        case TINYGLTF_TEXTURE_WRAP_MIRRORED_REPEAT:
            return SCNWrapModeMirror;
        case TINYGLTF_TEXTURE_WRAP_REPEAT:
        default:
            return SCNWrapModeRepeat;
    }
}

size_t TinyGLTFSizeOfComponentTypeWithDimension(NSInteger baseType, NSInteger dimension)
{
    switch (baseType) {
        case TINYGLTF_COMPONENT_TYPE_BYTE:
        case TINYGLTF_COMPONENT_TYPE_UNSIGNED_BYTE:
            switch (dimension) {
                case TINYGLTF_TYPE_VEC2:
                    return 2;
                case TINYGLTF_TYPE_VEC3:
                    return 3;
                case TINYGLTF_TYPE_VEC4:
                    return 4;
                default:
                    break;
            }
        case TINYGLTF_COMPONENT_TYPE_SHORT:
        case TINYGLTF_COMPONENT_TYPE_UNSIGNED_SHORT:
            switch (dimension) {
                case TINYGLTF_TYPE_VEC2:
                    return 4;
                case TINYGLTF_TYPE_VEC3:
                    return 6;
                case TINYGLTF_TYPE_VEC4:
                    return 8;
                default:
                    break;
            }
        case TINYGLTF_COMPONENT_TYPE_INT:
        case TINYGLTF_COMPONENT_TYPE_UNSIGNED_INT:
        case TINYGLTF_COMPONENT_TYPE_FLOAT:
            switch (dimension) {
                case TINYGLTF_TYPE_SCALAR:
                    return 4;
                case TINYGLTF_TYPE_VEC2:
                    return 8;
                case TINYGLTF_TYPE_VEC3:
                    return 12;
                case TINYGLTF_TYPE_VEC4:
                case TINYGLTF_TYPE_MAT2:
                    return 16;
                case TINYGLTF_TYPE_MAT3:
                    return 36;
                case TINYGLTF_TYPE_MAT4:
                    return 64;
                default:
                    break;
            }
        default:
            break;
    }
    return 0;
}

NSInteger TinyGLTFComponentCountForDimension(NSInteger dimension) {
    switch (dimension) {
        case TINYGLTF_TYPE_SCALAR:
            return 1;
        case TINYGLTF_TYPE_VEC2:
            return 2;
        case TINYGLTF_TYPE_VEC3:
            return 3;
        case TINYGLTF_TYPE_VEC4:
            return 4;
        case TINYGLTF_TYPE_MAT2:
            return 4;
        case TINYGLTF_TYPE_MAT3:
            return 9;
        case TINYGLTF_TYPE_MAT4:
            return 16;
        default:
            return 0;
    }
}


@interface TinyGLTFSCN ()
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, SCNNode *> *scnNodesForTinyNodes;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSArray<NSValue *> *> *inverseBindMatricesForSkins;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *cgImagesForImagesAndChannels;
@property (nonatomic, assign) NSInteger namelessAnimationIndex;
@property (nonatomic, strong) NSURL *gltfPath;
@end


@implementation TinyGLTFSCN

- (GLTF_TYPE) typeOfFileByPath: (NSURL *) url {
    return [[url pathExtension].lowercaseString isEqualToString:@"glb"] ? GLTF_TYPE_GLB : GLTF_TYPE_GLTF;
}

- (BOOL) loadModel: (NSURL *) modelURL {
    self.scnNodesForTinyNodes = [NSMutableDictionary dictionary];
    self.inverseBindMatricesForSkins = [NSMutableDictionary dictionary];
    self.cgImagesForImagesAndChannels = [NSMutableDictionary dictionary];
    self.namelessAnimationIndex = 0;
    self.gltfPath = [modelURL URLByDeletingLastPathComponent];
    
    GLTF_TYPE typeOfFile = [self typeOfFileByPath:modelURL];
    
    tinygltf::Model model;
    tinygltf::TinyGLTF loader;
    std::string err;
    std::string warn;
    bool ret;
    
    if (typeOfFile == GLTF_TYPE_GLTF) {
        ret = loader.LoadASCIIFromFile(&model, &err, &warn, std::string(modelURL.path.UTF8String));
    } else {
        ret = loader.LoadBinaryFromFile(&model, &err, &warn, std::string(modelURL.path.UTF8String));
    }
    
    if (!warn.empty()) {
#if DEBUG
        NSLog(@"Warn: %s\n", warn.c_str());
#endif
    }
    
    if (!err.empty()) {
#if DEBUG
        NSLog(@"Err: %s\n", err.c_str());
#endif
        return NO;
    }
    
    if (!ret) {
#if DEBUG
        NSLog(@"Failed to parse glTF\n");
#endif
        return NO;
    }
    
    [self loadScenes:model];
    [self loadAnimations:model];
    
    return YES;
}

- (void) loadScenes:(const tinygltf::Model &)model {
    NSMutableArray *scenes = [NSMutableArray array];
    
    for (const auto& scene: model.scenes) {
        SCNScene *scnScene = [SCNScene scene];
        
        for (const auto& node: scene.nodes) {
            [self recursiveAddNodeWithId:node toSCNNode:scnScene.rootNode fromModel:model];
        }
        
        [scenes addObject:scnScene];
    }
    
    _scenes = scenes;
}

- (void) loadAnimations:(const tinygltf::Model &)model {
    NSMutableDictionary *animations = [NSMutableDictionary dictionary];
    for (const auto &animation: model.animations) {
        NSString *name = animation.name.size() != 0 ? [[NSString alloc] initWithFormat:@"%s", animation.name.c_str()]: [self _nextAnonymousAnimationName];
        NSMutableArray *pairs = [NSMutableArray array];
        for (size_t i = 0; i < animation.channels.size(); ++i) {
            const auto& channel = animation.channels[i];
            const auto& sampler = animation.samplers[channel.sampler];
            
            
            const auto& inputAccessor = model.accessors[sampler.input];
            const auto& outputAccessor = model.accessors[sampler.output];
            
            
            CAKeyframeAnimation *keyframeAnimation = nil;
            NSString *targetPath = [[NSString alloc] initWithFormat:@"%s", channel.target_path.c_str()];
            
            if ([targetPath isEqualToString:@"rotation"]) {
                keyframeAnimation = [CAKeyframeAnimation animationWithKeyPath:@"orientation"];
                keyframeAnimation.values = [self arrayFromQuaternionAccessor:outputAccessor fromModel:model];
            } else if ([targetPath isEqualToString:@"translation"]) {
                keyframeAnimation = [CAKeyframeAnimation animationWithKeyPath:@"translation"];
                keyframeAnimation.values = [self vectorArrayFromAccessor:outputAccessor fromModel:model];
            } else if ([targetPath isEqualToString:@"scale"]) {
                keyframeAnimation = [CAKeyframeAnimation animationWithKeyPath:@"scale"];
                keyframeAnimation.values = [self vectorArrayFromScalarAccessor:outputAccessor fromModel:model];
            } else {
                continue;
            }
            
            NSTimeInterval startTime = [self startTime:inputAccessor fromModel:model];
            NSTimeInterval endTime = [self endTime:inputAccessor fromModel:model keyFrameCount:(int)inputAccessor.count];
            
            
            keyframeAnimation.keyTimes = [self normalizedArrayFromFloatAccessor:inputAccessor fromModel:model minimumValue:startTime maximumValue:endTime];
            keyframeAnimation.beginTime = startTime;
            keyframeAnimation.duration = endTime - startTime;
            keyframeAnimation.repeatDuration = FLT_MAX;
            NSNumber *targetNodeID = [NSNumber numberWithInteger:channel.target_node];
            
            SCNNode *scnNode = self.scnNodesForTinyNodes[targetNodeID];
            if (scnNode != nil) {
                GLTFSCNAnimationTargetPair *pair = [GLTFSCNAnimationTargetPair new];
                pair.animation = keyframeAnimation;
                pair.target = scnNode;
                [pairs addObject:pair];
            } else {
#if DEBUG
                NSLog(@"WARNING: Could not find node for channel target node identifier %@", targetNodeID);
#endif
            }
        }
        
        animations[name] = [pairs copy];
    }
    
    _animations = animations;
    
}

- (simd_float4x4)computeTransformForTinyNode: (const tinygltf::Node &)node {
    simd_quatf _rotationQuaternion = simd_quaternion(0.f, 0.f, 0.f, 1.f);
    simd_float3 _scale = vector3(1.0f, 1.0f, 1.0f);
    simd_float3 _translation = vector3(0.0f, 0.0f, 0.0f);
    
    const auto& rotation = node.rotation;
    const auto& scale = node.scale;
    const auto& translation = node.translation;
    
    if (rotation.size() == 4) {
        _rotationQuaternion = simd_quaternion(float(rotation[0]), float(rotation[1]), float(rotation[2]), float(rotation[3]));
    }
    
    if (scale.size() == 3) {
        _scale = vector3(float(scale[0]), float(scale[1]), float(scale[2]));
    }
    
    if (translation.size() == 3) {
        _translation = vector3(float(translation[0]), float(translation[1]), float(translation[2]));
    }
    
    simd_float4x4 translationMatrix = matrix_identity_float4x4;
    translationMatrix.columns[3][0] = _translation[0];
    translationMatrix.columns[3][1] = _translation[1];
    translationMatrix.columns[3][2] = _translation[2];
    
    simd_float4x4 rotationMatrix = simd_matrix4x4(_rotationQuaternion);
    
    simd_float4x4 scaleMatrix = matrix_identity_float4x4;
    scaleMatrix.columns[0][0] = _scale[0];
    scaleMatrix.columns[1][1] = _scale[1];
    scaleMatrix.columns[2][2] = _scale[2];
    
    return matrix_multiply(matrix_multiply(translationMatrix, rotationMatrix), scaleMatrix);
}

- (void) recursiveAddNodeWithId: (NSInteger)nodeID toSCNNode:(SCNNode *)node fromModel: (const tinygltf::Model &)model {
    const auto &tinyNode = model.nodes[nodeID];
    SCNNode *scnNode = [self makeSCNNodeForTinyNodeByID:nodeID];
    
    if (@available(iOS 11.0, *)) {
        scnNode.simdTransform = [self computeTransformForTinyNode:tinyNode];
    } else {
        scnNode.transform = SCNMatrix4FromMat4([self computeTransformForTinyNode:tinyNode]);
    }
    scnNode.name = node.name;
    
    [node addChildNode:scnNode];
    
    NSArray<SCNNode *> *meshNodes = [self nodesForTinyMesh:tinyNode.mesh withSkin:tinyNode.skin fromModel:model];
    for (SCNNode *meshNode in meshNodes) {
        [scnNode addChildNode:meshNode];
    }
    
    for (const auto &child: tinyNode.children){
        [self recursiveAddNodeWithId:child toSCNNode:scnNode fromModel:model];
    }
}

- (NSArray<SCNNode *> *)nodesForTinyMesh: (NSInteger)meshID withSkin:(NSInteger)skinID fromModel:(const tinygltf::Model &)model {
    if (meshID == -1){
        return nil;
    }
    
    const auto& mesh = model.meshes[meshID];
    
    NSMutableArray *nodes = [NSMutableArray array];
    
    NSArray<SCNNode *> *bones = [self bonesForTinySkin:skinID fromModel:model];
    NSArray<NSValue *> *inverseBindMatrices =  [self inverseBindMatricesForTinySkin:skinID fromModel:model];
    
    for (size_t i = 0; i < mesh.primitives.size(); ++i) {
        const auto& submesh = mesh.primitives[i];
        
        NSMutableArray *sources = [NSMutableArray array];
        NSMutableArray *elements = [NSMutableArray array];
        
        auto addAttribute = [&](const std::string& attribute, SCNGeometrySourceSemantic semantic) {
            const auto &attributeIter = submesh.attributes.find(attribute);
            
            if (attributeIter == submesh.attributes.end()){
                return;
            }
            
            SCNGeometrySource *attributeSource = [self geometrySourceWithSemantic:semantic accessorID:attributeIter->second fromModel:model];
            if (attributeSource != nil) {
                [sources addObject:attributeSource];
            }
            
            return;
        };
        
        addAttribute(GLTFAttributeSemanticPosition, SCNGeometrySourceSemanticVertex);
        addAttribute(GLTFAttributeSemanticNormal, SCNGeometrySourceSemanticNormal);
        addAttribute(GLTFAttributeSemanticTangent, SCNGeometrySourceSemanticTangent);
        addAttribute(GLTFAttributeSemanticTexCoord0, SCNGeometrySourceSemanticTexcoord);
        addAttribute(GLTFAttributeSemanticColor0, SCNGeometrySourceSemanticColor);
        
        const auto& indexAccessor = model.accessors[submesh.indices];
        const auto& indexBufferView = model.bufferViews[indexAccessor.bufferView];
        const auto& indexBuffer = model.buffers[indexBufferView.buffer];
        
        SCNGeometryPrimitiveType primitiveType = TinyGLTFSCNGeometryPrimitiveTypeForPrimitiveType(submesh.mode);
        NSInteger bytesPerIndex = (indexAccessor.componentType == TINYGLTF_COMPONENT_TYPE_UNSIGNED_SHORT) ? sizeof(uint16_t) : sizeof(uint32_t);
        NSData *indexData = [NSData dataWithBytes:indexBuffer.data.data() + indexBufferView.byteOffset + indexAccessor.byteOffset length:indexAccessor.count * bytesPerIndex];
        NSInteger indexCount = indexAccessor.count;
        NSInteger primitiveCount = TinyGLTFPrimitiveCountForIndexCount(indexCount, primitiveType);
        SCNGeometryElement *geometryElement = [SCNGeometryElement geometryElementWithData:indexData
                                                                            primitiveType:primitiveType
                                                                           primitiveCount:primitiveCount
                                                                            bytesPerIndex:bytesPerIndex];
        [elements addObject:geometryElement];
        
        SCNGeometry *geometry = [SCNGeometry geometryWithSources:sources elements:elements];
        
        
        SCNMaterial *material = [self materialForTinyMaterial:submesh.material fromModel:model];
        if (material != nil) {
            geometry.materials = @[material];
        }
        
        SCNNode *node = [SCNNode node];
        node.geometry = geometry;
        
        const auto& boneWeightsIter = submesh.attributes.find(GLTFAttributeSemanticWeights0);
        const auto& boneIndicesIter = submesh.attributes.find(GLTFAttributeSemanticJoints0);
        
        if (boneIndicesIter != submesh.attributes.end() && boneWeightsIter != submesh.attributes.end()) {
            SCNGeometrySource *boneWeights = [self geometrySourceWithSemantic:SCNGeometrySourceSemanticVertex accessorID:boneWeightsIter->second fromModel:model];
            SCNGeometrySource *boneIndices = [self geometrySourceWithSemantic:SCNGeometrySourceSemanticVertex accessorID:boneIndicesIter->second fromModel:model];
            
            if (boneWeights != nil && boneIndices != nil) {
                SCNSkinner *skinner = [SCNSkinner skinnerWithBaseGeometry:geometry
                                                                    bones:bones
                                                boneInverseBindTransforms:inverseBindMatrices
                                                              boneWeights:boneWeights
                                                              boneIndices:boneIndices];
                node.skinner = skinner;
            }
        }
        
        [nodes addObject:node];
    }
    
    return nodes;
}

- (SCNMaterial *)materialForTinyMaterial:(NSInteger)materialID fromModel:(const tinygltf::Model &)model {
    if (materialID == -1) {
        return nil;
    }
    
    const auto& material = model.materials[materialID];
    
    SCNMaterial *scnMaterial = [SCNMaterial material];
    
    scnMaterial.name = [NSString stringWithUTF8String:material.name.c_str()];
    
    scnMaterial.lightingModelName = SCNLightingModelPhysicallyBased;
    scnMaterial.doubleSided = material.doubleSided;
    
    if (material.pbrMetallicRoughness.baseColorTexture.index != -1) {
        const auto& baseColorTexture = model.textures[material.pbrMetallicRoughness.baseColorTexture.index];
        
        if (baseColorTexture.source != -1) {
            scnMaterial.diffuse.contents = (__bridge id)[self cgImageForTinyImage:baseColorTexture.source channelMask:TinyImageChannel::TinyImageChannelAll fromModel:model];
        }
        
        if (baseColorTexture.sampler != -1) {
            const auto &baseColorTextureSampler = model.samplers[baseColorTexture.sampler];
            scnMaterial.diffuse.wrapS = GLTFSCNWrapModeForAddressMode(baseColorTextureSampler.wrapS);
            scnMaterial.diffuse.wrapT = GLTFSCNWrapModeForAddressMode(baseColorTextureSampler.wrapT);
        }
    }
    
    if (scnMaterial.diffuse.contents == nil || material.pbrMetallicRoughness.baseColorTexture.index == -1) {
        const auto& colorFactor = material.pbrMetallicRoughness.baseColorFactor;
        
        if (colorFactor.size() >= 4) {
            scnMaterial.diffuse.contents = (__bridge_transfer id)[self newCGColorForFloat4:simd_make_float4(colorFactor[0], colorFactor[1], colorFactor[2], colorFactor[3])];
        }
    }
    
    scnMaterial.diffuse.mappingChannel = material.pbrMetallicRoughness.baseColorTexture.texCoord;
    
    if (material.pbrMetallicRoughness.metallicRoughnessTexture.index != -1) {
        const auto& metallicRoughnessTexture = model.textures[material.pbrMetallicRoughness.metallicRoughnessTexture.index];
        
        if (metallicRoughnessTexture.source != -1) {
            scnMaterial.metalness.contents = (__bridge id)[self cgImageForTinyImage:metallicRoughnessTexture.source channelMask:TinyImageChannel::TinyImageChannelBlue fromModel:model];
            
            scnMaterial.roughness.contents = (__bridge id)[self cgImageForTinyImage:metallicRoughnessTexture.source channelMask:TinyImageChannel::TinyImageChannelGreen fromModel:model];
        }
        
        if (metallicRoughnessTexture.sampler != -1) {
            const auto &metallicRoughnessTextureSampler = model.samplers[metallicRoughnessTexture.sampler];
            scnMaterial.metalness.wrapS = GLTFSCNWrapModeForAddressMode(metallicRoughnessTextureSampler.wrapS);
            scnMaterial.metalness.wrapT = GLTFSCNWrapModeForAddressMode(metallicRoughnessTextureSampler.wrapT);
            scnMaterial.roughness.wrapS = GLTFSCNWrapModeForAddressMode(metallicRoughnessTextureSampler.wrapS);
            scnMaterial.roughness.wrapT = GLTFSCNWrapModeForAddressMode(metallicRoughnessTextureSampler.wrapT);
        }
    }
    
    if (scnMaterial.metalness.contents == nil || material.pbrMetallicRoughness.metallicRoughnessTexture.index == -1) {
        scnMaterial.metalness.contents = @(material.pbrMetallicRoughness.metallicFactor);
    }
    
    if (scnMaterial.roughness.contents == nil || material.pbrMetallicRoughness.metallicRoughnessTexture.index == -1) {
        scnMaterial.metalness.contents = @(material.pbrMetallicRoughness.roughnessFactor);
    }
    
    scnMaterial.metalness.mappingChannel = material.pbrMetallicRoughness.metallicRoughnessTexture.texCoord;
    scnMaterial.roughness.mappingChannel = material.pbrMetallicRoughness.metallicRoughnessTexture.texCoord;
    
    
    
    if (material.normalTexture.index != -1) {
        const auto& normalTexture = model.textures[material.normalTexture.index];
        
        if (normalTexture.source != -1) {
            scnMaterial.normal.contents = (__bridge id)[self cgImageForTinyImage:normalTexture.source channelMask:TinyImageChannel::TinyImageChannelAll fromModel:model];
        }
        
        if (normalTexture.sampler != -1) {
            const auto &normalTextureSampler = model.samplers[normalTexture.sampler];
            scnMaterial.normal.wrapS = GLTFSCNWrapModeForAddressMode(normalTextureSampler.wrapS);
            scnMaterial.normal.wrapT = GLTFSCNWrapModeForAddressMode(normalTextureSampler.wrapT);
        }
    }
    
    scnMaterial.normal.mappingChannel = material.normalTexture.texCoord;
    
    if (material.occlusionTexture.index != -1) {
        const auto& occlusionTexture = model.textures[material.occlusionTexture.index];
        
        if (occlusionTexture.source != -1) {
            scnMaterial.ambientOcclusion.contents = (__bridge id)[self cgImageForTinyImage:occlusionTexture.source channelMask:TinyImageChannel::TinyImageChannelRed fromModel:model];
        }
        
        if (occlusionTexture.sampler != -1) {
            const auto &occlusionTextureSampler = model.samplers[occlusionTexture.sampler];
            scnMaterial.ambientOcclusion.wrapS = GLTFSCNWrapModeForAddressMode(occlusionTextureSampler.wrapS);
            scnMaterial.ambientOcclusion.wrapT = GLTFSCNWrapModeForAddressMode(occlusionTextureSampler.wrapT);
        }
    }
    
    scnMaterial.ambientOcclusion.mappingChannel = material.occlusionTexture.texCoord;
    
    if (material.emissiveTexture.index != -1) {
        const auto& emissiveTexture = model.textures[material.emissiveTexture.index];
        
        if (emissiveTexture.source != -1) {
            scnMaterial.emission.contents = (__bridge id)[self cgImageForTinyImage:emissiveTexture.source channelMask:TinyImageChannel::TinyImageChannelAll fromModel:model];
        }
        
        if (emissiveTexture.sampler != -1) {
            const auto &emissiveTextureSampler = model.samplers[emissiveTexture.sampler];
            scnMaterial.emission.wrapS = GLTFSCNWrapModeForAddressMode(emissiveTextureSampler.wrapS);
            scnMaterial.emission.wrapT = GLTFSCNWrapModeForAddressMode(emissiveTextureSampler.wrapT);
        }
    }
    
    if (scnMaterial.emission.contents == nil || material.emissiveTexture.index == -1) {
        const auto& emissiveFactor = material.emissiveFactor;
        
        if (emissiveFactor.size() >= 3) {
            scnMaterial.emission.contents = (__bridge_transfer id)[self newCGColorForFloat3:simd_make_float3(emissiveFactor[0], emissiveFactor[1], emissiveFactor[2])];
        }
    }
    
    scnMaterial.emission.mappingChannel = material.emissiveTexture.texCoord;
    
    return scnMaterial;
}

- (CGImageRef)newCGImageByExtractingChannel:(NSInteger)channelIndex fromCGImage:(const tinygltf::Image *)sourceImage {
    if (sourceImage == NULL) {
        return NULL;
    }
    
    NSData *imageData = [[NSData alloc] initWithBytes:sourceImage->image.data() length:sourceImage->image.size()];
    
    CGDataProviderRef imgDataProvider = CGDataProviderCreateWithCFData((__bridge CFDataRef) imageData);
    CGImageRef imageRef = CGImageCreateWithJPEGDataProvider(imgDataProvider, NULL, true, kCGRenderingIntentDefault);
    
    size_t width = sourceImage->width;
    size_t height = sourceImage->height;
    size_t bpc = 8;
    size_t Bpr = width * 4;
    
    uint8_t *pixels = (uint8_t *)malloc(Bpr * height);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, bpc, Bpr, colorSpace, kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    
    for (int i = 0; i < width * height; ++i) {
        uint8_t components[4] = { pixels[i * 4 + 0], pixels[i * 4 + 1], pixels[i * 4 + 2], pixels[i * 4 + 3] }; // RGBA
        pixels[i] = components[channelIndex];
    }
    
    CGColorSpaceRef monoColorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericGrayGamma2_2);
    CGContextRef monoContext = CGBitmapContextCreate(pixels, width, height, bpc, width, monoColorSpace, kCGImageAlphaNone);
    
    CGImageRef channelImage = CGBitmapContextCreateImage(monoContext);
    
    CGColorSpaceRelease(monoColorSpace);
    CGContextRelease(monoContext);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    free(pixels);
    //    CGImageRelease(imageRef);
    
    return channelImage;
}

- (CGImage *)cgImageForTinyImage:(NSInteger)imageID channelMask:(TinyImageChannel)channelMask fromModel:(const tinygltf::Model &)model {
    if (imageID == -1) {
        return nil;
    }
    
    const auto& image = model.images[imageID];
    
    NSString *imageName = nil;
    if (image.name.size() == 0) {
        imageName = [NSString stringWithFormat:@"%ld", (long)imageID];
    } else {
        imageName = [NSString stringWithFormat:@"%s", image.name.c_str()];
    }
    
    NSString *maskedIdentifier = [NSString stringWithFormat:@"%@/%d", imageName, (int)channelMask];
    
    // Check the cache to see if we already have an exact match for the requested image and channel subset
    CGImageRef exactCachedImage = (__bridge CGImageRef)self.cgImagesForImagesAndChannels[maskedIdentifier];
    if (exactCachedImage != nil) {
        return exactCachedImage;
    }
    
    // If we don't have an exact match for the image+channel pair, we may still have the original image cached
    NSString *unmaskedIdentifier = [NSString stringWithFormat:@"%@/%d", imageName, (int)TinyImageChannel::TinyImageChannelAll];
    CGImageRef originalImage = (__bridge CGImageRef)self.cgImagesForImagesAndChannels[unmaskedIdentifier];
    
    if (originalImage == NULL) {
        // We got unlucky, so we need to load and cache the original
        if (image.uri.size() != 0) {
            
            NSURL *url = [[NSURL alloc] initFileURLWithPath:[[NSString alloc] initWithFormat:@"%s", image.uri.c_str()] relativeToURL:self.gltfPath];
            CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)url, nil);
            originalImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil);
            if (imageSource) {
                CFRelease(imageSource);
            }
        } else if ( image.bufferView != -1) {
            
            const auto& bufferView = model.bufferViews[image.bufferView];
            const auto& buffer = model.buffers[bufferView.buffer];
            
            NSData *imageData = [NSData dataWithBytes:buffer.data.data() + bufferView.byteOffset  length:bufferView.byteLength];
            CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, nil);
            originalImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil);
            if (imageSource) {
                CFRelease(imageSource);
            }
        }
        
        self.cgImagesForImagesAndChannels[unmaskedIdentifier] = (__bridge id)originalImage;
        CGImageRelease(originalImage);
    }
    
    // Now that we have the original, we may need to extract the requisite channel and cache the result
    if (channelMask != TinyImageChannel::TinyImageChannelAll) {
        CGImageRef extractedImage = [self newCGImageByExtractingChannel:(int)channelMask fromCGImage:&image];
        self.cgImagesForImagesAndChannels[maskedIdentifier] = (__bridge id)extractedImage;
        CGImageRelease(extractedImage);
        return extractedImage;
    }
    
    return originalImage;
}

- (SCNGeometrySource *)geometrySourceWithSemantic:(SCNGeometrySourceSemantic)semantic accessorID:(NSInteger)accessorID fromModel: (const tinygltf::Model &)model{
    if (accessorID == -1) {
        return nil;
    }
    
    const auto& accessor = model.accessors[accessorID];
    
    const auto& bufferView = model.bufferViews[accessor.bufferView];
    const auto& buffer = model.buffers[bufferView.buffer];
    
    NSInteger bytesPerElement = TinyGLTFSizeOfComponentTypeWithDimension(accessor.componentType, accessor.type);
    BOOL componentsAreFloat = TINYGLTF_COMPONENT_TYPE_FLOAT == accessor.componentType;
    NSInteger componentsPerElement = TinyGLTFComponentCountForDimension(accessor.type);
    NSInteger bytesPerComponent = bytesPerElement / componentsPerElement;
    NSInteger dataOffset = 0;
    NSInteger dataStride = bufferView.byteStride;
    if (dataStride == 0) {
        dataStride = bytesPerElement;
    }
    
    const char *dataBase = ((char *)(buffer.data.data()) + bufferView.byteOffset + accessor.byteOffset);
    
    if ([semantic isEqualToString:SCNGeometrySourceSemanticBoneWeights])
    {
        for (int i = 0; i < accessor.count; ++i) {
            float *weights = (float *)(dataBase + i * dataStride);
            float sum = weights[0] + weights[1] + weights[2] + weights[3];
            if (sum != 1.0f) {
                weights[0] /= sum;
                weights[1] /= sum;
                weights[2] /= sum;
                weights[3] /= sum;
            }
        }
    }
    
    NSData *data = [NSData dataWithBytes:dataBase length:accessor.count * dataStride];
    
    SCNGeometrySource *source = [SCNGeometrySource geometrySourceWithData:data
                                                                 semantic:semantic
                                                              vectorCount:accessor.count
                                                          floatComponents:componentsAreFloat
                                                      componentsPerVector:componentsPerElement
                                                        bytesPerComponent:bytesPerComponent
                                                               dataOffset:dataOffset
                                                               dataStride:dataStride];
    return source;
}

- (NSArray<NSValue *> *)inverseBindMatricesForTinySkin: (NSInteger) skinID fromModel: (const tinygltf::Model &)model {
    if (skinID == -1){
        return @[];
    }
    
    NSNumber *objectSkinID = [NSNumber numberWithInteger:skinID];
    const auto& skin = model.skins[skinID];
    
    NSArray<NSValue *> *inverseBindMatrices = self.inverseBindMatricesForSkins[objectSkinID];
    
    if (inverseBindMatrices != nil) {
        return inverseBindMatrices;
    }
    
    NSMutableArray *matrices = [NSMutableArray array];
    
    const auto& accessor = model.accessors[skin.inverseBindMatrices];
    const auto& bufferView = model.bufferViews[accessor.bufferView];
    
    const unsigned char *buffer = model.buffers[bufferView.buffer].data.data();
    GLTFMatrix4 *ibms = (GLTFMatrix4 *)(buffer + bufferView.byteOffset + accessor.byteOffset);
    
    for (int i = 0; i < accessor.count; ++i) {
        SCNMatrix4 ibm = GLTFSCNMatrix4FromFloat4x4(ibms[i]);
        NSValue *ibmValue = [NSValue valueWithSCNMatrix4:ibm];
        [matrices addObject:ibmValue];
    }
    matrices = [matrices copy];
    self.inverseBindMatricesForSkins[objectSkinID] = matrices;
    
    return matrices;
}

- (NSArray<SCNNode *> *) bonesForTinySkin: (NSInteger) skinID fromModel: (const tinygltf::Model &)model {
    if (skinID == -1) {
        return @[];
    }
    
    const auto& skin = model.skins[skinID];
    
    NSMutableArray<SCNNode *> *bones = [NSMutableArray array];
    for (const auto& jointNode: skin.joints) {
        SCNNode *boneNode = [self makeSCNNodeForTinyNodeByID:jointNode];
        if (boneNode != nil) {
            [bones addObject:boneNode];
        } else {
#if DEBUG
            NSLog(@"WARNING: Did not find node for joint with identifier %d", jointNode);
#endif
        }
    }
    
    if (bones.count == skin.joints.size()) {
        return [bones copy];
    } else {
#if DEBUG
        NSLog(@"WARNING: Bone count for skinner does not match joint node count for skin with identifier %ld", (long)skinID);
#endif
    }
    
    return @[];
}

- (SCNNode *) makeSCNNodeForTinyNodeByID: (NSInteger)nodeID {
    NSNumber *objectNodeID = [NSNumber numberWithInteger:nodeID];
    SCNNode *scnNode = self.scnNodesForTinyNodes[objectNodeID];
    
    if (scnNode == nil) {
        scnNode = [SCNNode node];
        self.scnNodesForTinyNodes[objectNodeID] = scnNode;
    }
    
    return scnNode;
}

- (CGColorRef)newCGColorForFloat4:(simd_float4)v {
    CGFloat components[] = { v.x, v.y, v.z, v.w };
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    CGColorRef color = CGColorCreate(colorSpace, &components[0]);
    CGColorSpaceRelease(colorSpace);
    return color;
}

- (CGColorRef)newCGColorForFloat3:(simd_float3)v {
    CGFloat components[] = { v.x, v.y, v.z, 1 };
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    CGColorRef color = CGColorCreate(colorSpace, &components[0]);
    CGColorSpaceRelease(colorSpace);
    return color;
}

- (NSArray<NSValue *> *)arrayFromQuaternionAccessor:(const tinygltf::Accessor &)accessor fromModel: (const tinygltf::Model &)model {
    
    const auto& buffetView = model.bufferViews[accessor.bufferView];
    const auto& buffer = model.buffers[buffetView.buffer];
    
    NSMutableArray *values = [NSMutableArray array];
    
    const GLTFVector4 *quaternions = (const GLTFVector4 *)((const char *)buffer.data.data() + buffetView.byteOffset + accessor.byteOffset);
    NSInteger count = accessor.count;
    for (NSInteger i = 0; i < count; ++i) {
        SCNVector4 quat =  SCNVector4Zero;
        if (quaternions != nullptr) {
            quat = (SCNVector4){ quaternions[i].x, quaternions[i].y, quaternions[i].z, quaternions[i].w };
        }
        NSValue *value = [NSValue valueWithSCNVector4:quat];
        [values addObject:value];
    }
    return [values copy];
}

- (NSArray<NSValue *> *)vectorArrayFromAccessor:(const tinygltf::Accessor &)accessor fromModel: (const tinygltf::Model &)model {
    const auto& buffetView = model.bufferViews[accessor.bufferView];
    const auto& buffer = model.buffers[buffetView.buffer];
    
    NSMutableArray *values = [NSMutableArray array];
    const GLTFVector3 *vectors = (const GLTFVector3 *)((const char *)buffer.data.data() + buffetView.byteOffset + accessor.byteOffset);
    NSInteger count = accessor.count;
    for (NSInteger i = 0; i < count; ++i) {
        SCNVector3 scnVec = SCNVector3Zero;
        if (vectors != nullptr) {
            GLTFVector3 vec = vectors[i];
            scnVec = (SCNVector3){ vec.x, vec.y, vec.z };
        }
        
        NSValue *value = [NSValue valueWithSCNVector3:scnVec];
        [values addObject:value];
    }
    return [values copy];
}

- (NSArray<NSValue *> *)vectorArrayFromScalarAccessor:(const tinygltf::Accessor &)accessor fromModel: (const tinygltf::Model &)model {
    const auto& buffetView = model.bufferViews[accessor.bufferView];
    const auto& buffer = model.buffers[buffetView.buffer];
    
    NSMutableArray *values = [NSMutableArray array];
    const float *floats = (const float *)((const char *)buffer.data.data() + buffetView.byteOffset + accessor.byteOffset);
    NSInteger count = accessor.count;
    for (NSInteger i = 0; i < count; ++i) {
        SCNVector3 scnVec = SCNVector3Zero;
        if (floats != nullptr) {
            scnVec = (SCNVector3){ floats[i], floats[i], floats[i] };
        }
        NSValue *value = [NSValue valueWithSCNVector3:scnVec];
        [values addObject:value];
    }
    return [values copy];
}

- (NSArray<NSNumber *> *)normalizedArrayFromFloatAccessor:(const tinygltf::Accessor &)accessor fromModel: (const tinygltf::Model &)model minimumValue:(float)minimumValue maximumValue:(float)maximumValue {
    const auto& buffetView = model.bufferViews[accessor.bufferView];
    const auto& buffer = model.buffers[buffetView.buffer];
    
    NSMutableArray *values = [NSMutableArray array];
    const float *floats = (const float *)((const char *)buffer.data.data() + buffetView.byteOffset + accessor.byteOffset);
    NSInteger count = accessor.count;
    for (NSInteger i = 0; i < count; ++i) {
        float f = 0;
        if (floats != nullptr) {
            f = floats[i];
        }
        
        f = fmin(fmax(0, (f - minimumValue) / (maximumValue - minimumValue)), 1);
        NSValue *value = [NSNumber numberWithFloat:f];
        [values addObject:value];
    }
    return [values copy];
}

- (NSTimeInterval)startTime:(const tinygltf::Accessor &)inputAccessor fromModel: (const tinygltf::Model &)model {
    const auto& buffetView = model.bufferViews[inputAccessor.bufferView];
    const auto& buffer = model.buffers[buffetView.buffer];
    
    const float *timeValues = (const float *)((const char *)buffer.data.data() + buffetView.byteOffset + inputAccessor.byteOffset);
    
    float startTime = 0;
    if (timeValues != nullptr) {
        startTime = timeValues[0];
    }
    return startTime;
}

- (NSTimeInterval)endTime:(const tinygltf::Accessor &)outputAccessor fromModel: (const tinygltf::Model &)model keyFrameCount:(int)keyFrameCount {
    const auto& buffetView = model.bufferViews[outputAccessor.bufferView];
    const auto& buffer = model.buffers[buffetView.buffer];
    
    const float *timeValues = (const float *)((const char *)buffer.data.data() + buffetView.byteOffset + outputAccessor.byteOffset);
    float endTime = 0;
    if (timeValues != nullptr) {
        endTime = timeValues[keyFrameCount - 1];
    }
    
    return endTime;
}

- (NSString *)_nextAnonymousAnimationName {
    NSString *name = [NSString stringWithFormat:@"UNNAMED_%d", (int)self.namelessAnimationIndex];
    self.namelessAnimationIndex = self.namelessAnimationIndex + 1;
    return name;
}

@end
