#import "Basic";
#import "Windows";
#import "dxgi";
#import "d3d12";
RenderDevice :: #import,file "RenderDevice.jai";
#import "Descriptors";

#load "../Settings.jai";

NUM_RTV_DESCRIPTORS : u32 = 64;

_d3d12RtvHeap     : *ID3D12DescriptorHeap;
_d3d12RtvHeapIncSize: u32;

Init :: ()
{
    // Create descriptor heaps.
    {
        // Describe and create a render target view (RTV) descriptor heap.
        rtvHeapDesc: D3D12_DESCRIPTOR_HEAP_DESC;
        rtvHeapDesc.NumDescriptors = NUM_RTV_DESCRIPTORS;
        rtvHeapDesc.Type  = .RTV;
        rtvHeapDesc.Flags = .NONE;
        result := ID3D12Device_CreateDescriptorHeap(RenderDevice._d3d12Device, *rtvHeapDesc, *uid(ID3D12DescriptorHeap_UUID), xx *_d3d12RtvHeap);
        if result != S_OK 
        {
            #if ASSERT_ON_FAIL assert(false, "d3d12_device.CreateDescriptorHeap failed.");
            return;
        }
        _d3d12RtvHeapIncSize = ID3D12Device_GetDescriptorHandleIncrementSize(RenderDevice._d3d12Device, .RTV);
    }
}

RTType :: enum u32
{
    RT;
    SwapChain;
    Texture;
}

RT :: struct
{
    type: RTType = .RT;
    rtvs: [MAX_SWAPCHAIN_BUFFER_COUNT] *ID3D12Resource;

    // Swapchain stuff
    swapChain: *IDXGISwapChain3;
    activeBufferIndex: u32;
    presentFence: *ID3D12Fence;
    presentEvent: *void;
}

Create :: (desc: RTDesc) -> RTHandle
{
    return 0;
}

Create :: (desc: SwapChainRTDesc) -> RTHandle
{
    rt: RT;
    rt.type = .SwapChain;

    swapChainDesc: DXGI_SWAP_CHAIN_DESC1;
    swapChainDesc.BufferCount      = desc.bufferCount;
    swapChainDesc.Width            = desc.width;
    swapChainDesc.Height           = desc.height;
    swapChainDesc.Format           = desc.format;
    swapChainDesc.BufferUsage      = .RENDER_TARGET_OUTPUT;
    swapChainDesc.SwapEffect       = .FLIP_SEQUENTIAL;//.FLIP_DISCARD; // NOTE: BufferCount must be > 1 for using "DXGI_SWAP_EFFECT_FLIP_DISCARD/DXGI_SWAP_EFFECT_FLIP_SEQUENTIAL"
    swapChainDesc.SampleDesc.Count = 1;

    
    result := IDXGIFactory2_CreateSwapChainForHwnd(RenderDevice._d3d12Factory,
        xx RenderDevice._d3d12Queue,    // Swapchain needs the queue so that it can force a flush on it.
        desc.hwnd,
        *swapChainDesc,
        null,
        null,
        xx *rt.swapChain
        );

    if result != S_OK 
    {
        #if ASSERT_ON_FAIL assert(false, "d3d12_factory.CreateSwapChainForHwnd failed.");
        return INVALID_RT_HANDLE;
    }

    // This sample does not support fullscreen transitions.
    IDXGIFactory_MakeWindowAssociation(RenderDevice._d3d12Factory, desc.hwnd, xx DXGI_MWA.NO_ALT_ENTER);

    // Create frame resources.
    {
        rtvHandle: D3D12_CPU_DESCRIPTOR_HANDLE = ID3D12DescriptorHeap_GetCPUDescriptorHandleForHeapStart(_d3d12RtvHeap);
        // Create a RTV for each frame.
        for n:0..desc.bufferCount-1 
        {
            result = IDXGISwapChain_GetBuffer(rt.swapChain, xx n, *uid(ID3D12Resource_UUID), xx *rt.rtvs[n]);
            if result != S_OK 
            {
                #if ASSERT_ON_FAIL assert(false, "_d3d12Swapchain.GetBuffer failed.");
                return INVALID_RT_HANDLE;
            }
            ID3D12Device_CreateRenderTargetView(RenderDevice._d3d12Device, rt.rtvs[n], null, rtvHandle);
            rtvHandle.ptr += (1 * _d3d12RtvHeapIncSize);
        }
    }

    // set the backbuffer index for next present.
    rt.activeBufferIndex = IDXGISwapChain3_GetCurrentBackBufferIndex(rt.swapChain);

    // Present fence
    result = ID3D12Device_CreateFence(RenderDevice._d3d12Device, 0, .NONE, *uid(ID3D12Fence_UUID), xx *rt.resetFence);
    if result != S_OK 
    {
        #if ASSERT_ON_FAIL assert(false, "_d3d12Device.CreateFence failed.");
        return INVALID_RT_HANDLE;
    }

    // Create an event handle.
    rt.presentEvent = CreateEventW(null, 0, 0, null);
    if rt.presentEvent == null 
    {
        #if ASSERT_ON_FAIL assert(false, "CreateEventW failed.");
        return INVALID_RT_HANDLE;
    }

    return cast (RTHandle) 1;
}