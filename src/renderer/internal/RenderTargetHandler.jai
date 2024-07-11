#import "Basic";
#import "Windows";
#import "dxgi";
#import "d3d12";
RenderDevice :: #import,file "RenderDevice.jai";
#import,file "../descriptors/RTDesc.jai";

Init :: ()
{

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

    swapChain: IDXGISwapChain1;
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
        return false;
    }

    // This sample does not support fullscreen transitions.
    IDXGIFactory_MakeWindowAssociation(_d3d12Factory, _hwnd, xx DXGI_MWA.NO_ALT_ENTER);

    // Create descriptor heaps.
    {
        // Describe and create a render target view (RTV) descriptor heap.
        rtvHeapDesc: D3D12_DESCRIPTOR_HEAP_DESC;
        rtvHeapDesc.NumDescriptors = _ctxBufferCount;
        rtvHeapDesc.Type  = .RTV;
        rtvHeapDesc.Flags = .NONE;
        result = ID3D12Device_CreateDescriptorHeap(_d3d12Device, *rtvHeapDesc, *uid(ID3D12DescriptorHeap_UUID), xx *_d3d12RtvHeap);
        if result != S_OK 
        {
            #if ASSERT_ON_FAIL assert(false, "d3d12_device.CreateDescriptorHeap failed.");
            Deinit();
            return false;;
        }
        _d3d12RtvHeapIncSize = ID3D12Device_GetDescriptorHandleIncrementSize(_d3d12Device, .RTV);
    }

    // Create frame resources.
    {
        rtvHandle: D3D12_CPU_DESCRIPTOR_HANDLE = ID3D12DescriptorHeap_GetCPUDescriptorHandleForHeapStart(_d3d12RtvHeap);
        // Create a RTV for each frame.
        for n:0.._ctxBufferCount-1 
        {
            result = IDXGISwapChain_GetBuffer(_d3d12Swapchain, xx n, *uid(ID3D12Resource_UUID), xx *_d3d12Rtvs[n]);
            if result != S_OK 
            {
                #if ASSERT_ON_FAIL assert(false, "_d3d12Swapchain.GetBuffer failed.");
                Deinit();
                return false;
            }
            ID3D12Device_CreateRenderTargetView(_d3d12Device, _d3d12Rtvs[n], null, rtvHandle);
            rtvHandle.ptr += (1 * _d3d12RtvHeapIncSize);
        }

        // Create screenshot buffer
        readbackBufferDesc: D3D12_RESOURCE_DESC;
        readbackBufferDesc.Dimension = .D3D12_RESOURCE_DIMENSION_BUFFER;
        readbackBufferDesc.Alignment = 0;
        readbackBufferDesc.Width = _width * _height * 4; // Assuming 4 bytes per pixel (RGBA)
        readbackBufferDesc.Height = 1;
        readbackBufferDesc.DepthOrArraySize = 1;
        readbackBufferDesc.MipLevels = 1;
        readbackBufferDesc.Format = .DXGI_FORMAT_UNKNOWN;
        readbackBufferDesc.SampleDesc.Count = 1;
        readbackBufferDesc.SampleDesc.Quality = 0;
        readbackBufferDesc.Layout = .D3D12_TEXTURE_LAYOUT_ROW_MAJOR;
        readbackBufferDesc.Flags = .D3D12_RESOURCE_FLAG_NONE;

        heapProperties: D3D12_HEAP_PROPERTIES;
        heapProperties.Type = .D3D12_HEAP_TYPE_READBACK;
        heapProperties.CPUPageProperty = .D3D12_CPU_PAGE_PROPERTY_UNKNOWN;
        heapProperties.MemoryPoolPreference = .D3D12_MEMORY_POOL_UNKNOWN;
        heapProperties.CreationNodeMask = 1;
        heapProperties.VisibleNodeMask = 1;

        result = ID3D12Device_CreateCommittedResource(_d3d12Device,
            *heapProperties,
            .D3D12_HEAP_FLAG_NONE,
            *readbackBufferDesc,
            .D3D12_RESOURCE_STATE_COPY_DEST,
            null,
            *uid(ID3D12Resource_UUID),
            xx *_d3d12ScreenshotRTV
        );
        if result != S_OK 
        {
            #if ASSERT_ON_FAIL assert(false, "_d3d12Swapchain.GetBuffer failed.");
            Deinit();
            return false;
        }
    }

    // set the backbuffer index for next present.
    _ctxActiveBufferIndex = IDXGISwapChain3_GetCurrentBackBufferIndex(_d3d12Swapchain);

    // Present fence
    result = ID3D12Device_CreateFence(_d3d12Device, 0, .NONE, *uid(ID3D12Fence_UUID), xx *_d3d12PresentFence);
    if result != S_OK 
    {
        #if ASSERT_ON_FAIL assert(false, "_d3d12Device.CreateFence failed.");
        Deinit();
        return false;
    }

    // Create an event handle.
    _d3d12PresentEvent = CreateEventW(null, 0, 0, null);
    if _d3d12PresentEvent == null 
    {
        #if ASSERT_ON_FAIL assert(false, "CreateEventW failed.");
        Deinit();
        return false;
    }

    return 0;
}