using UnityEngine;

public class test : MonoBehaviour
{
    void Start()
    {
        // Test vector: try changing (1, 2, 3) to anything you want
        Vector3 testVec = new Vector3(1, 2, 3);

        // Call your matrix-based function
        Matrix4x4 myMatrix = RotateTowardsVector(testVec);

        // Also call MatrixUtils.RotateTowardsVector for comparison
        Matrix4x4 quaternionMatrix = MatrixUtils.RotateTowardsVector(testVec);

        // Apply both matrices to the original up vector
        Vector3 resultMy = myMatrix.MultiplyVector(Vector3.up);
        Vector3 resultQuat = quaternionMatrix.MultiplyVector(Vector3.up);

        // Print results to the Console
        Debug.Log("Target:         " + testVec.normalized);
        Debug.Log("Matrix Method:  " + resultMy.normalized);
        Debug.Log("Quaternion Method: " + resultQuat.normalized);

        // Print entire matrices if you want to inspect components
        Debug.Log("Matrix-based:\n" + myMatrix);
        Debug.Log("Quaternion-based:\n" + quaternionMatrix);

        float angle = Vector3.Angle(resultMy, testVec.normalized);
        Debug.Log("Angle between result and target: " + angle);
    }

    // Paste your RotateTowardsVector implementation here
    Matrix4x4 RotateTowardsVector(Vector3 v)
    {
        // --- 1. Initialization ---
        // As per the exercise instructions, first normalize the target vector.
        v.Normalize();

        // Get components (a, b, c) as used in TA1 slides (p. 94)
        float a = v.x;
        float b = v.y;
        float c = v.z;

        // --- 2. Calculate R_x_inv (Rotation around X-axis) ---

        // We need the angle theta_x.
        // The slides (p. 97) define theta_x = 90 - phi, where phi = atan2(b, c).
        // The angle phi is the angle in the YZ-plane between the Z-axis and v's projection (0, b, c).
        //
        // Using the trig identity atan2(x, y) = 90_deg - atan2(y, x), we can simplify:
        // theta_x (in degrees) = atan2(c, b) * Mathf.Rad2Deg
        // This is the angle between the Y-axis and the projection (0, b, c).
        float theta_x_rad = Mathf.Atan2(c, b);
        float theta_x_deg = theta_x_rad * Mathf.Rad2Deg;

        // The slides' Rx rotates by -theta_x. Our Rx_inv rotates by +theta_x.
        Matrix4x4 R_x_inv = MatrixUtils.RotateX(theta_x_deg);

        // --- 3. Calculate R_z_inv (Rotation around Z-axis) ---

        // We need the angle theta_z.
        // This angle operates on the intermediate vector v' = (a, b', 0),
        // where b' is the length of the YZ-projection, b' = sqrt(b*b + c*c). (p. 102)
        float b_prime = Mathf.Sqrt(b * b + c * c);

        // The slides (p. 106) define theta_z = 90 - psi, where psi = atan2(b_prime, a).
        // The angle psi is the angle in the XY-plane between the X-axis and v'.
        //
        // Using the same trig identity, we can simplify:
        // theta_z (in degrees) = atan2(a, b_prime) * Mathf.Rad2Deg
        // This is the angle between the Y-axis and the intermediate vector v'.
        float theta_z_rad = Mathf.Atan2(a, b_prime);
        float theta_z_deg = theta_z_rad * Mathf.Rad2Deg;

        // The slides' Rz rotates by +theta_z to get *to* the Y-axis.
        // Our Rz_inv must rotate by -theta_z to get *from* the Y-axis.
        Matrix4x4 R_z_inv = MatrixUtils.RotateZ(-theta_z_deg);

        // --- 4. Combine Transformations ---
        // The final matrix is R = Rx_inv * Rz_inv.
        // The order of multiplication is crucial, as matrix multiplication is not commutative.
        // Transformations are applied right-to-left.
        Matrix4x4 R = R_x_inv * R_z_inv;

        return R;
    }
}