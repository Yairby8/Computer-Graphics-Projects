using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class MeshData
{
    public List<Vector3> vertices; // The vertices of the mesh 
    public List<int> triangles; // Indices of vertices that make up the mesh faces
    public Vector3[] normals; // The normals of the mesh, one per vertex

    // Class initializer
    public MeshData()
    {
        vertices = new List<Vector3>();
        triangles = new List<int>();
    }

    // Returns a Unity Mesh of this MeshData that can be rendered
    public Mesh ToUnityMesh()
    {
        Mesh mesh = new Mesh
        {
            vertices = vertices.ToArray(),
            triangles = triangles.ToArray(),
            normals = normals
        };

        return mesh;
    }

    // Calculates surface normals for each vertex, according to face orientation
    public void CalculateNormals()
    {
        int vertexCount = vertices.Count;
        int triangleCount = triangles.Count; // int array in format {0, 1, 2, 0, 1, 3, ...} where every grouping of 3 consecutive indices represents the indices of points in a single triangle

        // Initialize normals array (one normal per vertex)
        normals = new Vector3[vertexCount];
        for (int i = 0; i < vertexCount; i++)
        {
            normals[i] = Vector3.zero;
        }

        // Go over all triangles (each face is 3 indices)
        for (int i = 0; i < triangleCount; i += 3)
        {
            //i0...i2 are indices of a single triangle
            int i0 = triangles[i];
            int i1 = triangles[i + 1];
            int i2 = triangles[i + 2];

            Vector3 p0 = vertices[i0];
            Vector3 p1 = vertices[i1];
            Vector3 p2 = vertices[i2];

            // Edge vectors of the triangle
            Vector3 e1 = p0 - p2;
            Vector3 e2 = p1 - p2;

            // Face normal via cross product (not normalized yet)
            Vector3 faceNormal = Vector3.Cross(e1, e2);

            // Normalize face normal
            faceNormal.Normalize();

            // Accumulate this face normal to each of its vertices
            normals[i0] += faceNormal;
            normals[i1] += faceNormal;
            normals[i2] += faceNormal;

        }

        // Normalize all vertex normals
        for (int i = 0; i < vertexCount; i++)
        {
            normals[i].Normalize();
        }
    }

    // Edits mesh such that each face has a unique set of 3 vertices
    public void MakeFlatShaded()
    {
        // If there are no triangles, nothing to do
        if (triangles == null || triangles.Count == 0)
            return;

        // We will create a new vertex list where every triangle
        // uses its own copy of the 3 vertices.
        List<Vector3> newVertices = new List<Vector3>(triangles.Count);
        List<int> newTriangles = new List<int>(triangles.Count);

        // For each triangle index (each entry in triangles)
        for (int i = 0; i < triangles.Count; i++)
        {
            int oldVertexIndex = triangles[i];       // index into original vertices
            Vector3 v = vertices[oldVertexIndex];    // original vertex position

            // Add a duplicate vertex with the same position
            newVertices.Add(v);

            // Its index in the newVertices list is just 'i'
            newTriangles.Add(i);
        }

        // Replace old data with the flat-shaded data
        vertices = newVertices;
        triangles = newTriangles;

        // Normals are now invalid and should be recalculated (handled by MeshViewer.cs)
        normals = null;
    }
}