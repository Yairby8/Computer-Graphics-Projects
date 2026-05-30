using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CharacterAnimator : MonoBehaviour
{
    public TextAsset BVHFile; // The BVH file that defines the animation and skeleton
    public bool animate; // Indicates whether or not the animation should be running
    public bool interpolate; // Indicates whether or not frames should be interpolated
    [Range(0.01f, 2f)] public float animationSpeed = 1f; // Controls the speed of the animation playback

    public BVHData data; // BVH data of the BVHFile will be loaded here
    public float t = 0; // Value used to interpolate the animation between frames
    public float[] currFrameData; // BVH channel data corresponding to the current keyframe
    public float[] nextFrameData; // BVH vhannel data corresponding to the next keyframe

    // Start is called before the first frame update
    void Start()
    {
        BVHParser parser = new BVHParser();
        data = parser.Parse(BVHFile);
        CreateJoint(data.rootJoint, Vector3.zero);

    }

    // Returns a Matrix4x4 representing a rotation aligning the up direction of an object with the given v
    public Matrix4x4 RotateTowardsVector(Vector3 v)
    {

        // First normalize the target vector.
        v.Normalize();

        // Get components (a, b, c)
        float a = v.x;
        float b = v.y;
        float c = v.z;

        // Rotation around X-axis

        // We need the angle theta_x.
        // The slides (p. 97) define theta_x = 90 - phi, where phi = atan2(b, c).
        // The angle phi is the angle in the YZ-plane between the Z-axis and v's projection (0, b, c).
        //
        // Using the trig identity atan2(x, y) = 90_deg - atan2(y, x), we can simplify:
        // theta_x (in degrees) = atan2(c, b) * Mathf.Rad2Deg
        // This is the angle between the Y-axis and the projection (0, b, c).
        float theta_x_rad = Mathf.Atan2(c, b);
        float theta_x_deg = theta_x_rad * Mathf.Rad2Deg;

        // Rx_inv rotates by +theta_x (Counter-clockwise when following right hand rule)
        Matrix4x4 R_x_inv = MatrixUtils.RotateX(theta_x_deg);

        // Rotation around Z-axis

        // We need the angle theta_z.
        // This angle operates on the vector v' = (a, b', 0),
        // where b' is the length of the YZ-projection, b' = sqrt(b*b + c*c). (p. 102)
        float b_prime = Mathf.Sqrt(b * b + c * c);

        // The slides (p. 106) define theta_z = 90 - psi, where psi = atan2(b_prime, a).
        // The angle psi is the angle in the XY-plane between the X-axis and v'.
        //
        // Using the same trig identity, we can simplify:
        // theta_z (in degrees) = atan2(a, b_prime) * Mathf.Rad2Deg
        // This is the angle between the Y-axis and the vector v'.
        float theta_z_rad = Mathf.Atan2(a, b_prime);
        float theta_z_deg = theta_z_rad * Mathf.Rad2Deg;

        // According to the slides Rz rotates by +theta_z to get to the Y-axis.
        // Our Rz_inv must rotate by -theta_z to get from the Y-axis.
        Matrix4x4 R_z_inv = MatrixUtils.RotateZ(-theta_z_deg);

        // Combine Transformations
        // The final matrix is R = Rx_inv * Rz_inv.
        // The order of multiplication is crucial, as matrix multiplication is not commutative.
        // Transformations are applied right-to-left.
        Matrix4x4 R = R_x_inv * R_z_inv;

        return R;
}


    // Creates a Cylinder GameObject between two given points in 3D space
    public GameObject CreateCylinderBetweenPoints(Vector3 p1, Vector3 p2, float diameter)
    {
        // Unity's default cylinder is aligned along +Y, height = 2, diameter = 1, centered at origin.
        GameObject cylinder = GameObject.CreatePrimitive(PrimitiveType.Cylinder);

        Vector3 dir = p2 - p1;
        float length = dir.magnitude; // The length of the vector is square root of (x*x+y*y+z*z) 
        Vector3 mid = (p1 + p2) * 0.5f;

        Matrix4x4 T = MatrixUtils.Translate(mid);
        Matrix4x4 R = RotateTowardsVector(dir);      // align +Y to (p2-p1)
        //  We want to scale the cylinder to the correct length (originally length=2 and needs to scale to magnitude) and diameter (originally diameter
        //  is 1 for both x and z scales).
        //  x, z immediately scale by the given diameter.
        //  For y: desired length = original length * scale factor <=> desired length = 2 * scale factor <=> scale factor = desired length / 2
        Matrix4x4 S = MatrixUtils.Scale(new Vector3(diameter, length * 0.5f, diameter)); // Sy = L/2

        Matrix4x4 M = T * R * S;
        MatrixUtils.ApplyTransform(cylinder, M);

        // return cylinder;
        return cylinder;
    }

    // Creates a GameObject representing a given BVHJoint and recursively creates GameObjects for it's child joints
    public GameObject CreateJoint(BVHJoint joint, Vector3 parentPosition)
    {
        // create joint
        joint.gameObject = new GameObject(joint.name);

        // create sphere and set parent
        GameObject sphere = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        sphere.transform.parent = joint.gameObject.transform;

        // scale sphere
        float factor = (joint.name == "Head") ? 8f : 2f;
        Matrix4x4 S = MatrixUtils.Scale(Vector3.one * factor);
        MatrixUtils.ApplyTransform(sphere, S);

        // translate joint to correct position
        Vector3 jointWorldPos = parentPosition + joint.offset;
        Matrix4x4 T = MatrixUtils.Translate(jointWorldPos);
        MatrixUtils.ApplyTransform(joint.gameObject, T);
     
        // Recurse
        foreach (var child in joint.children)
        {
            // Child world position (before animation) is parent + child.offset
            Vector3 childWorldPos = jointWorldPos + child.offset;

            // Draw bone with diameter 0.6 and parent it under the current joint object
            GameObject bone = CreateCylinderBetweenPoints(jointWorldPos, childWorldPos, 0.6f);
            bone.transform.parent = joint.gameObject.transform;


            CreateJoint(child, jointWorldPos);
        }


        return joint.gameObject;

    }

    // Build rotation matrix from BVH Euler channels using the BVH rotationOrder (left-to-right).
    private Matrix4x4 RotationFromBVHEuler(BVHJoint joint, float[] frame)
    {
        if (joint.isEndSite) return Matrix4x4.identity;

        // Euler angles in degrees from the keyframe
        float ex = frame[joint.rotationChannels.x];
        float ey = frame[joint.rotationChannels.y];
        float ez = frame[joint.rotationChannels.z];

        Matrix4x4 Rx = MatrixUtils.RotateX(ex);
        Matrix4x4 Ry = MatrixUtils.RotateY(ey);
        Matrix4x4 Rz = MatrixUtils.RotateZ(ez);

        // rotationOrder encodes the left-to-right multiplication order
        Matrix4x4[] ordered = new Matrix4x4[3];
        ordered[joint.rotationOrder.z] = Rz; 
        ordered[joint.rotationOrder.x] = Rx; 
        ordered[joint.rotationOrder.y] = Ry; 

        return ordered[0] * ordered[1] * ordered[2];
    }

    // Translate encoded euler angle rotations to quaterion
    private Vector4 JointRotationQuaternion(BVHJoint joint, float[] frame)
    {
        if (joint.isEndSite) return new Vector4(0, 0, 0, 1); // identity
        // Euler angles in degrees from BVH channels
        float ex = frame[joint.rotationChannels.x];
        float ey = frame[joint.rotationChannels.y];
        float ez = frame[joint.rotationChannels.z];
        // Compose by provided order (left-to-right)
        return QuaternionUtils.FromEuler(new Vector3(ex, ey, ez), joint.rotationOrder);
    }

    // root position from a frame (only root has position channels)
    private Vector3 RootPositionFromFrame(BVHJoint root, float[] frame)
    {
        if (root.positionChannels.x == 0 && root.positionChannels.y == 0 && root.positionChannels.z == 0)
            return Vector3.zero; // Safety check

        return new Vector3(
            frame[root.positionChannels.x],
            frame[root.positionChannels.y],
            frame[root.positionChannels.z]
        );
    }


    // Transforms BVHJoint according to the keyframe channel data, and recursively transforms its children
    // Without quaternions, implementation up to part 4

    // public void TransformJoint(BVHJoint joint, Matrix4x4 parentTransform)
    // {
    //     Matrix4x4 R = RotationFromBVHEuler(joint, currFrameData);


    //     Matrix4x4 T;

    // if (joint == data.rootJoint){
    //     Vector3 rootPosition = RootPositionFromFrame(root, currFrameData);
    // }

    //         T = MatrixUtils.Translate(rootPosition);

    //     }
    //     else{
    //         T = MatrixUtils.Translate(joint.offset);
    //     }

    //     Matrix4x4 currentTransform = parentTransform * T * R;
    //     MatrixUtils.ApplyTransform(joint.gameObject, currentTransform);  
            
    //     foreach (var child in joint.children)
    //     {
    //         TransformJoint(child, currentTransform);      
    //     }
    // }

    // Transforms BVHJoint according to the keyframe channel data, and recursively transforms its children
    // With quaternions for part 5
    public void TransformJoint(BVHJoint joint, Matrix4x4 parentTransform)
    {
        // Rotation (interpolated or not)
        Vector4 qRot;
        if (interpolate && nextFrameData != null)
        {
            Vector4 q1 = JointRotationQuaternion(joint, currFrameData);
            Vector4 q2 = JointRotationQuaternion(joint, nextFrameData);
            qRot = QuaternionUtils.Slerp(q1, q2, t);
        }
        else
        {
            qRot = JointRotationQuaternion(joint, currFrameData);
        }
        Matrix4x4 R = MatrixUtils.RotateFromQuaternion(qRot);

        // Translation
        Matrix4x4 T;
        if (joint == data.rootJoint)
        {
            // The root also has positional channels that move the whole character
            Vector3 p;
            if (interpolate && nextFrameData != null)
            {
                Vector3 p1 = RootPositionFromFrame(joint, currFrameData);
                Vector3 p2 = RootPositionFromFrame(joint, nextFrameData);
                p = Vector3.Lerp(p1, p2, t);
            }
            else
            {
                p = RootPositionFromFrame(joint, currFrameData);
            }
            T = MatrixUtils.Translate(p);
        }
        else
        {
            // Other joints: translate by the static offset (in joint space)
            T = MatrixUtils.Translate(joint.offset);
        }

        // Local then global (all in world space): parent * T * R
        Matrix4x4 finalTransform = parentTransform * T * R;

        // Apply to this joint's GameObject
        MatrixUtils.ApplyTransform(joint.gameObject, finalTransform);

        // Recurse
        foreach (var child in joint.children)
        {
            TransformJoint(child, finalTransform);
        }
    }


    // Returns the frame nunmber of the BVH animation at a given time
    public int GetFrameNumber(float time)
    {
        // Ensure looping after exceeding number of frames
        int frame = Mathf.FloorToInt(time / data.frameLength) % data.numFrames;
        return frame;
    }

    // Returns the proportion of time elapsed between the last frame and the next one, between 0 and 1
    public float GetFrameIntervalTime(float time)
    {
        float f = time / data.frameLength;
        float frac = f - Mathf.Floor(f); // in [0,1)
        return Mathf.Clamp01(frac); // clamped to prevent calculation errors
        }

    // Update is called once per frame
    void Update()
    {
        float time = Time.time * animationSpeed;
        int currFrame;

        if (animate)
        {
            currFrame = GetFrameNumber(time);
            currFrameData = data.keyframes[currFrame];
        }
        else{
            return;
        }


        if (interpolate)
        {
            t = GetFrameIntervalTime(time);
            if (currFrame < data.numFrames - 1)
                nextFrameData = data.keyframes[currFrame + 1];
            else
                nextFrameData = null; // no next on the last frame
        }
        else
        {
            t = 0f;
            nextFrameData = null;
        }

        // Starts running animation from root and recursively apply to all joints
        TransformJoint(data.rootJoint, Matrix4x4.identity);
    }
}
