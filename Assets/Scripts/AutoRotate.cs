using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// [ExecuteAlways]
public class AutoRotate : MonoBehaviour
{
    public Vector3 speed;
    public bool isLoop;
    public float loopTime = 1 ;

    void Update()
    {
        if (isLoop)
        {
            transform.Rotate(Mathf.Sin(Time.time / loopTime) * speed * Time.deltaTime);
        }
        else
        {
            transform.Rotate(speed * Time.deltaTime);
        }
    }
}
