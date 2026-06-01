using System;
using UnityEngine;

public class QuaternionUtils
{
    // The default rotation order of Unity. May be used for testing
    public static readonly Vector3Int UNITY_ROTATION_ORDER = new Vector3Int(1,2,0);

    // Returns the product of 2 given quaternions
    public static Vector4 Multiply(Vector4 q1, Vector4 q2)
    {
        return new Vector4(
            q1.w*q2.x + q1.x*q2.w + q1.y*q2.z - q1.z*q2.y,
            q1.w*q2.y + q1.y*q2.w + q1.z*q2.x - q1.x*q2.z,
            q1.w*q2.z + q1.z*q2.w + q1.x*q2.y - q1.y*q2.x,
            q1.w*q2.w - q1.x*q2.x - q1.y*q2.y - q1.z*q2.z
        );
    }

    // Returns the conjugate of the given quaternion q
    public static Vector4 Conjugate(Vector4 q)
    {
        return new Vector4(-q.x, -q.y, -q.z, q.w); 
    }

    // Returns the Hamilton product of given quaternions q and v
    public static Vector4 HamiltonProduct(Vector4 q, Vector4 v)
    {
        Vector4 qv = Multiply(q, v);
        Vector4 qConj = Conjugate(q);
        return Multiply(qv, qConj);
    }
    

    // Returns a quaternion representing a rotation of theta degrees around the given axis
    public static Vector4 AxisAngle(Vector3 axis, float theta)
    {
    // Use a unit axis (required for a unit quaternion).
    Vector3 a = axis.normalized;

    // 3) Convert degrees to radians and take half the angle.
    float half = theta * Mathf.Deg2Rad * 0.5f;

    // 4) Precompute sine/cosine of the half-angle.
    float s = Mathf.Sin(half);
    float c = Mathf.Cos(half);

    // 5) Return the unit quaternion q = [v, w] with:
    //    v = a * sin(0/2)  (the vector part)
    //    w = cos(0/2)      (the scalar part)
    return new Vector4(a.x * s, a.y * s, a.z * s, c);
    }

    // Returns a quaternion representing the given Euler angles applied in the given rotation order
    public static Vector4 FromEuler(Vector3 euler, Vector3Int rotationOrder)
    {
        Vector4 qx = AxisAngle(new Vector3(1f, 0f, 0f), euler.x); // +X
        Vector4 qy = AxisAngle(new Vector3(0f, 1f, 0f), euler.y); // +Y
        Vector4 qz = AxisAngle(new Vector3(0f, 0f, 1f), euler.z); // +Z

        // Define matrices to multiply in specified order
        Vector4[] qs = new Vector4[3];
        qs[rotationOrder.x] = qx;
        qs[rotationOrder.y] = qy;
        qs[rotationOrder.z] = qz;

        // Multiply matrices
        Vector4 q = qs[0];
        q = Multiply(q, qs[1]);
        q = Multiply(q, qs[2]);

        // Normalize to safeguard against rounding errors
        float n = Mathf.Sqrt(q.x*q.x + q.y*q.y + q.z*q.z + q.w*q.w);
        if (n > 0f) q /= n;

        return q;
    }

    // Returns a spherically interpolated quaternion between q1 and q2 at time t in [0,1]
    public static Vector4 Slerp(Vector4 q1, Vector4 q2, float t)
    {
        // Normalize inputs
        q1 = q1 / Mathf.Sqrt(q1.x*q1.x + q1.y*q1.y + q1.z*q1.z + q1.w*q1.w);
        q2 = q2 / Mathf.Sqrt(q2.x*q2.x + q2.y*q2.y + q2.z*q2.z + q2.w*q2.w);

        // Dot product to get the cosine of the angle
        float dot = q1.x*q2.x + q1.y*q2.y + q1.z*q2.z + q1.w*q2.w;

        // Use the shortest path and flip dot accordingly
        if (dot < 0f)
        {
            dot = -dot;
            q2 = -q2;
        }


        float theta = Mathf.Acos(Mathf.Clamp(dot, -1f, 1f)); // angle between, clamp avoids jitters created by rounding errors
        // float theta = Mathf.Acos(dot); // angle between
        float sin_theta = Mathf.Sin(theta);

        if (sin_theta == 0)
        {
            return q1;
        }

        float t_theta = t * theta;
        float sin_t_theta = Mathf.Sin(t_theta);

        float s1 = Mathf.Sin(theta - t_theta) / sin_theta;
        float s2 = sin_t_theta / sin_theta;

        Vector4 outQ = s1 * q1 + s2 * q2;
        // Normalize output just in case
        float n = Mathf.Sqrt(outQ.x*outQ.x + outQ.y*outQ.y + outQ.z*outQ.z + outQ.w*outQ.w);
        return outQ / n;
    
    }
}