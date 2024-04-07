using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class TestMono : MonoBehaviour
{
    void Start()
    {
        Application.targetFrameRate = 240;
    }

    void Update()
    {
        transform.Rotate(new Vector3(1,0,0));
    }
    
    
}


