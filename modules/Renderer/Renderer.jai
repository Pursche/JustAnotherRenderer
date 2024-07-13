#import "Basic";
#import "Windows";
#import "dxgi";
#import "d3d12";
#import "d3d_compiler";

RenderDevice :: #import,file "internal/RenderDevice.jai";
RenderTargetHandler :: #import,file "internal/RenderTargetHandler.jai";

// Descs
#import "Descriptors";

Init :: (hwnd: HWND, width: u32, height: u32)
{
    RenderDevice.Init(hwnd, width, height);

    RenderTargetHandler.Init();
}

Render :: ()
{
    RenderDevice.Render();
}

Present :: ()
{
    RenderDevice.Present();
}

// Create
Create :: (desc: RTDesc) -> RTHandle
{
    return RenderTargetHandler.Create(desc);
}

Create :: (desc: SwapChainRTDesc) -> RTHandle
{
    return RenderTargetHandler.Create(desc);
}