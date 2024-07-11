#import "Basic";
#import "Windows";

Renderer :: #import,file "../renderer/Renderer.jai";

#import,file "../renderer/descriptors/RTDesc.jai";

_swapChainRT: RTHandle;

Init :: (hwnd: HWND, width: u32, height: u32)
{
    Renderer.Init(hwnd, width, height);

    swapChainRTDesc: SwapChainRTDesc;
    swapChainRTDesc.width = width;
    swapChainRTDesc.height = height;
    swapChainRTDesc.bufferCount = 2;
    swapChainRTDesc.format = .R8G8B8A8_UNORM;
    swapChainRTDesc.hwnd = hwnd;

    _swapChainRT = Renderer.Create(swapChainRTDesc);
}

Update :: (dt: float64)
{

}

Render :: ()
{
    Renderer.Render();

    Renderer.Present();
}