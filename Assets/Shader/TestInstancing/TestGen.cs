using UnityEngine;
using UnityEditor;

public class CreateTriangleMesh : MonoBehaviour
{
    [MenuItem("Assets/Create/测试三角形")]
    static void CreateMesh()
    {
        Mesh mesh = new Mesh();

        Vector3[] vertices = new Vector3[]
        {
            new Vector3(-0.03f, 0.4f, 0),
            new Vector3(0.03f, 0.4f, 0),
            new Vector3(0, 1, 0),
            new Vector3(0, 0, 0),
        };
        
        Vector3[] normals = new Vector3[]
        {
            new Vector3(-1, 0, 0),
            new Vector3(1, 0, 0),
            new Vector3(0, 0, 1),
            new Vector3(0, 0, 1),
        };

        int[] triangles = new int[]
        {
            0, 1, 2, 0,3,1
        };

        mesh.vertices = vertices;
        mesh.normals = normals;
        mesh.triangles = triangles;

        AssetDatabase.CreateAsset(mesh, "Assets/TriangleMesh.asset");
        AssetDatabase.SaveAssets();
    }
}