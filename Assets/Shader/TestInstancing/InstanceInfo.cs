using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Random = UnityEngine.Random;

public class InstanceInfo : MonoBehaviour
{
    public int GrassCount = 100000;
    public float Range = 20;

    public static ComputeBuffer grassBuffer;
    public static List<Matrix4x4> grassTransforms = new List<Matrix4x4>();

    void GenGrass()
    {
        for (int i = 0; i < GrassCount; i++)
        {
            grassTransforms.Add(Matrix4x4.TRS(new Vector3(Random.value * Range, 0, Random.value * Range),
                Quaternion.Euler(0, Random.value * 30, 0),
                new Vector3(1+Random.value*0.2f, 0.4f+Random.value*0.4f, 1)));
        }

        grassTransforms.Sort((a, b) =>
        {
            var near = Vector3.Distance(transform.position, new Vector3(a.m03, a.m13, a.m23)) -
                       Vector3.Distance(transform.position, new Vector3(b.m03, b.m13, b.m23));
            return near > 0 ? 1 : -1;
        });

        grassBuffer = new ComputeBuffer(GrassCount, 64);
        grassBuffer.SetData(grassTransforms);
    }

    void Start()
    {
        GenGrass();
    }
}

