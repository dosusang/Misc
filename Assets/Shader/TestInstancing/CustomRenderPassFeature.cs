using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class CustomRenderPassFeature : ScriptableRendererFeature
{
    class CustomRenderPass : ScriptableRenderPass
    {
        public Mesh mesh;
        public Material mat;
        public ComputeBuffer buffer;
        
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
        }

        void GenGrassBuffer()
        {
            
        }


        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var cmd = CommandBufferPool.Get("ProceduralInstance");
            cmd.Clear();
            
            if (buffer != InstanceInfo.grassBuffer)
            {
                mat.SetBuffer("testStructuredBuffer", InstanceInfo.grassBuffer);
                buffer = InstanceInfo.grassBuffer;
            }
            
            if (buffer != null && buffer.count != 0)
            {
                cmd.DrawMeshInstancedProcedural(mesh, 0, mat, 0, buffer.count);
                context.ExecuteCommandBuffer(cmd);
            }
        }


        public override void OnCameraCleanup(CommandBuffer cmd)
        {
        }
    }

    CustomRenderPass m_ScriptablePass;
    public Mesh mesh;
    public Material mat;
    public override void Create()
    {
        m_ScriptablePass = new CustomRenderPass();
        m_ScriptablePass.renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
    }
    
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        m_ScriptablePass.mesh = mesh;
        m_ScriptablePass.mat = mat;
        if (m_ScriptablePass.mesh != null && mesh != null)
        {
            renderer.EnqueuePass(m_ScriptablePass);
        }
    }
}


