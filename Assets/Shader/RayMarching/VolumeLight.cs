using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class VolumeLight : ScriptableRendererFeature
{
    class CustomRenderPass : ScriptableRenderPass
    {
        public RenderTargetIdentifier source;
        private RenderTargetHandle temp1;
        private RenderTargetHandle temp2;
        private RenderTargetHandle tempBase;

        public Material VolumeLightMat;
        public int DownSample;
        public int BlurLoop;
        private int updateChannel = 0;


        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            temp1.id = Shader.PropertyToID("temp1");
            temp2.id = Shader.PropertyToID("temp2");
            tempBase.id = Shader.PropertyToID("tempBase");
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (VolumeLightMat == null) return;

            var tempDesc = renderingData.cameraData.cameraTargetDescriptor;
            tempDesc.width >>= DownSample;
            tempDesc.height >>= DownSample;
            tempDesc.depthBufferBits = 0;
            var cmd = CommandBufferPool.Get("VolumeLight");
            cmd.Clear();

            cmd.GetTemporaryRT(temp1.id, tempDesc, FilterMode.Bilinear);
            cmd.GetTemporaryRT(temp2.id, tempDesc, FilterMode.Bilinear);
            cmd.GetTemporaryRT(tempBase.id, tempDesc, FilterMode.Bilinear);

            cmd.SetRenderTarget(temp1.Identifier());
            // cmd.ClearRenderTarget(false, true, Color.black);

            cmd.SetViewProjectionMatrices(Matrix4x4.identity, Matrix4x4.identity);

            var cameraData = renderingData.cameraData;
            var myRect = cameraData.camera.pixelRect;

            // myRect.max *= 0.5f;
            
            VolumeLightMat.SetFloat("_DownSample",Mathf.Pow(0.5f, DownSample));
            updateChannel = (updateChannel+1) % 2;
            VolumeLightMat.SetInt("_UpdateChannel", updateChannel);
            cmd.Blit(source, tempBase.Identifier(), VolumeLightMat, 0);
            cmd.Blit(tempBase.id, temp1.id, VolumeLightMat, 0);


            for (int i = 0; i < Mathf.Max(1, BlurLoop); i++)
            {
                cmd.Blit(temp1.id, temp2.id, VolumeLightMat, 1);
                cmd.Blit(temp2.id, temp1.id, VolumeLightMat, 2);
            }
            cmd.Blit(temp1.Identifier(), source, VolumeLightMat, 3);
            context.ExecuteCommandBuffer(cmd);
        }

        public override void FrameCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(temp1.id);
            cmd.ReleaseTemporaryRT(temp2.id);
            cmd.ReleaseTemporaryRT(tempBase.id);
        }
    }

    CustomRenderPass m_ScriptablePass;
    public Material VolumeLightMat;
    public int DownSample;
    public int BlurLoop;


    public override void Create()
    {
        m_ScriptablePass = new CustomRenderPass();

        m_ScriptablePass.renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        m_ScriptablePass.VolumeLightMat = VolumeLightMat;
        m_ScriptablePass.source = renderer.cameraColorTarget;
        m_ScriptablePass.DownSample = DownSample;
        m_ScriptablePass.BlurLoop = BlurLoop;

        renderer.EnqueuePass(m_ScriptablePass);
    }
}