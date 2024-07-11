#import "Basic";
#import "Windows";
#import "dxgi";
#import "d3d12";

//---------------------------------------------------------------------
// Constants
//
DEBUG          :: true;
ASSERT_ON_FAIL :: true;
BREAK_ON_ERROR :: false;
FRAME_COUNT    :u32: 2;

_hwnd : HWND;
_width : u32 = 800;
_height : u32 = 500;

Init :: (hwnd: HWND, width: u32, height: u32)
{
    _hwnd = hwnd;
    _width = width;
    _height = height;

    if (!_InitBackend()) return;
    if (!_InitDevice()) return;
    //if (!_InitRenderContext()) return;
    //if (!_InitCommandEncoder()) return;
}

Render :: ()
{
    /*
    // wait for the active frame
    {
        // here we do not want the wait value for last submited frame, we want
        // to wait for the active/current/acquired frame (which in use) last submission.
        waitValue: u64;
        if _submitCounter < FRAME_COUNT 
        {
            waitValue = 0;
        } 
        else 
        {
            waitValue = (_submitCounter - FRAME_COUNT) + 1;
        }
        // print("frame:% backbuffer:% submit_counter:% checking:% next-check:% \n", active_frame_index, ctx_active_buffer_index, submit_counter, wait_value, submit_counter+1);
        // wait on the host
        if ID3D12Fence_GetCompletedValue(_d3d12SubmitFence) < waitValue 
        {
            ID3D12Fence_SetEventOnCompletion(_d3d12SubmitFence, waitValue, _d3d12SubmitEvent);
            WaitForSingleObject(_d3d12SubmitEvent, 0xffff_ffff);
        }
    }

    //-------------------

    result: HRESULT;
    cmdList := _d3d12CommandLists[_activeFrameIndex];

    result = ID3D12GraphicsCommandList_Reset(cmdList, _d3d12CommandAllocator, null);//, _d3d12PipelineState);
    #if DEBUG assert(S_OK == result);
    {
        // Indicate that the back buffer will be used as a render target. (begin_renderpass)
        rtBarrier: D3D12_RESOURCE_BARRIER;
        rtBarrier.Type                   = .TRANSITION;
        rtBarrier.Flags                  = .NONE;
        rtBarrier.Transition.pResource   = _d3d12Rtvs[_ctxActiveBufferIndex];
        rtBarrier.Transition.StateBefore = .PRESENT;
        rtBarrier.Transition.StateAfter  = .RENDER_TARGET;
        rtBarrier.Transition.Subresource = D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES;
        ID3D12GraphicsCommandList_ResourceBarrier(cmdList, 1, *rtBarrier);

        rtvHandle: D3D12_CPU_DESCRIPTOR_HANDLE = ID3D12DescriptorHeap_GetCPUDescriptorHandleForHeapStart(_d3d12RtvHeap);
        rtvHandle.ptr = rtvHandle.ptr + (_ctxActiveBufferIndex * _d3d12RtvHeapIncSize);
        clearColor := float.[1.0, 0.2, 0.4, 1.0];
        ID3D12GraphicsCommandList_ClearRenderTargetView(cmdList, rtvHandle, *clearColor, 0, null);

        // Indicate that the back buffer will be used to present. (end_renderpass)
        presentBarrier: D3D12_RESOURCE_BARRIER;
        presentBarrier.Type                   = .TRANSITION;
        presentBarrier.Flags                  = .NONE;
        presentBarrier.Transition.pResource   = _d3d12Rtvs[_ctxActiveBufferIndex];
        presentBarrier.Transition.StateBefore = .RENDER_TARGET;
        presentBarrier.Transition.StateAfter  = .PRESENT;
        presentBarrier.Transition.Subresource = D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES;
        ID3D12GraphicsCommandList_ResourceBarrier(cmdList, 1, *presentBarrier);
    }
    result = ID3D12GraphicsCommandList_Close(cmdList);
    #if DEBUG assert(S_OK == result);

    //-------------------

    // Submit
    {
        _submitCounter += 1; // increment submission counte
        // Execute the command list.
        ID3D12CommandQueue_ExecuteCommandLists(_d3d12Queue, 1, xx *_d3d12CommandLists[_activeFrameIndex]);
        // Signal and increment the fence value.
        ID3D12CommandQueue_Signal(_d3d12Queue, _d3d12SubmitFence, _submitCounter);
        // move to next frame
        _activeFrameIndex = (_activeFrameIndex+1) % FRAME_COUNT;
    }*/
}

Present :: ()
{
    /*// Increment and signal the fence value. (from the gpu to the cpu)
    // to know if the all commands executed.
    _ctxPresentCounter += 1;
    ID3D12CommandQueue_Signal(_d3d12Queue, _d3d12PresentFence, _ctxPresentCounter);
    // wait for the gpu "wait for commands execution"
    if ID3D12Fence_GetCompletedValue(_d3d12PresentFence) < _ctxPresentCounter 
    {
        ID3D12Fence_SetEventOnCompletion(_d3d12PresentFence, _ctxPresentCounter, _d3d12PresentEvent);
        WaitForSingleObject(_d3d12PresentEvent, 0xffff_ffff);
    }
    hr: HRESULT;
    if VSYNC 
    {
        hr = IDXGISwapChain_Present(xx _d3d12Swapchain, 1, 0);
    } 
    else 
    {
        hr = IDXGISwapChain_Present(xx _d3d12Swapchain, 0, 0);
    }
    #if DEBUG assert(hr == S_OK);
    
    _ctxActiveBufferIndex = IDXGISwapChain3_GetCurrentBackBufferIndex(_d3d12Swapchain);*/
}

Deinit :: ()
{
}

// ---------------------------------------------------------------------
// Backend : IDXGIFactory4, IDXGIAdapter1
//
_d3d12Factory: *IDXGIFactory4;
_d3d12Adapter: *IDXGIAdapter1;

_InitBackend :: () -> bool
{
    log("Init backend...\n");
    result: HRESULT;
    dxgiFactoryFlags: u32 = 0;

    #if DEBUG 
    {
        // Enable the debug layer (requires the Graphics Tools "optional feature").
        // For Windows 10, to create a device that supports the debug layer,
        // enable the "Graphics Tools" optional feature. Go to the Settings panel,
        // under System, Apps & features, Manage optional Features, Add a feature,
        // and then look for "Graphics Tools".
        // NOTE: Enabling the debug layer after device creation will invalidate the active device.
        debugInterface: *ID3D12Debug1;
        if SUCCEEDED(D3D12GetDebugInterface(*uid(ID3D12Debug1_UUID), xx *debugInterface)) 
        {
            ID3D12Debug1_EnableDebugLayer(debugInterface);
            // ID3D12Debug1_SetEnableGPUBasedValidation(debug_interface, .TRUE);
            // ID3D12Debug1_SetEnableSynchronizedCommandQueueValidation(debug_interface, .TRUE);
            dxgiFactoryFlags |= DXGI_CREATE_FACTORY_DEBUG;
        }
    }

    // Create Factory
    result = CreateDXGIFactory2(dxgiFactoryFlags, *uid(IDXGIFactory4_UUID), xx *_d3d12Factory);
    if result != S_OK 
    {
        #if ASSERT_ON_FAIL assert(false, "CreateDXGIFactory2 failed.");
        Deinit();
        return false;
    }

    // Get Hardware Adapter
    warpAdapterFound := false;

    // first check warp adapter
    // https://docs.microsoft.com/en-us/windows/win32/direct3darticles/directx-warp

    result = IDXGIFactory4_EnumWarpAdapter(_d3d12Factory, *uid(IDXGIAdapter1_UUID), xx *_d3d12Adapter);
    if result == S_OK
    {
        // Check to see whether the adapter supports Direct3D 12, but don't create the
        // actual device yet.
        result = D3D12CreateDevice(_d3d12Adapter, .D3D_FEATURE_LEVEL_12_0, *uid(ID3D12Device_UUID), null);
        // If ppDevice is NULL and the function succeeds, S_FALSE (0x1) is returned, rather than S_OK.
        if result == 0x1 
        {
            warpAdapterFound = true;
        } 
    } 
    else 
    {
        if _d3d12Adapter IUnknown_Release(_d3d12Adapter);
        _d3d12Adapter = null;
    }

    adapterIndex :u32= 0;
    while true && !warpAdapterFound
    {
        // print("checking: % adapter_index\n", adapter_index);
        if SUCCEEDED(IDXGIFactory1_EnumAdapters1(_d3d12Factory, adapterIndex, *_d3d12Adapter)) 
        {
            // print("found\n");
            desc:DXGI_ADAPTER_DESC1;
            IDXGIAdapter1_GetDesc1(_d3d12Adapter, *desc); 
            // print("desc: %\n", desc);
            // Don't select the Basic Render Driver adapter.
            if (desc.Flags & cast(u32) DXGI_ADAPTER_FLAG.SOFTWARE) continue;
            // Check to see whether the adapter supports Direct3D 12, but don't create the
            // actual device yet.
            result = D3D12CreateDevice(_d3d12Adapter, .D3D_FEATURE_LEVEL_12_0, *uid(ID3D12Device_UUID), null);
            // If ppDevice is NULL and the function succeeds, S_FALSE (0x1) is returned, rather than S_OK.
            if 0x1 == result then break;
        }
        // Else we won't use this iteration's adapter, so release it
        IUnknown_Release(_d3d12Adapter);
        _d3d12Adapter = null;
        adapterIndex += 1;
    }

    if !_d3d12Adapter 
    {
        #if ASSERT_ON_FAIL assert(false, "Obtaining IDXGIAdapter1 failed.");
        Deinit();
        return false;
    } 

    log(" Done!\n");
    return true;
}

_d3d12Device    : *ID3D12Device;
_d3d12Queue     : *ID3D12CommandQueue;
_d3d12InfoQueue: *ID3D12InfoQueue;
_d3d12QueueWiFence: *ID3D12Fence;
_d3d12QueueWiEvent: *void;

_InitDevice :: () -> bool
{
    log("Init device...");
    // Create Device
    result := D3D12CreateDevice(_d3d12Adapter, .D3D_FEATURE_LEVEL_12_0, *uid(ID3D12Device_UUID), xx *_d3d12Device);
    if result != S_OK 
    {
        #if ASSERT_ON_FAIL assert(false, "D3D12CreateDevice failed.");
        Deinit();
        return false;
    }

    #if DEBUG 
    {
        if SUCCEEDED(IUnknown_QueryInterface(_d3d12Device, *uid(ID3D12InfoQueue_UUID), xx *_d3d12InfoQueue)) 
        {
            //  break (while running the .exe in VS)
            #if BREAK_ON_ERROR 
            {
                ID3D12InfoQueue_SetBreakOnSeverity(_d3d12InfoQueue, .CORRUPTION, .TRUE);
                ID3D12InfoQueue_SetBreakOnSeverity(_d3d12InfoQueue, .ERROR, .TRUE);
            }
            // ID3D12InfoQueue_SetBreakOnSeverity(_d3d12InfoQueue, .D3D12_MESSAGE_SEVERITY_WARNING, .TRUE);
            // ID3D12InfoQueue_SetBreakOnSeverity(_d3d12InfoQueue, .D3D12_MESSAGE_SEVERITY_INFO, .TRUE);
            // ID3D12InfoQueue_SetBreakOnSeverity(_d3d12InfoQueue, .D3D12_MESSAGE_SEVERITY_MESSAGE, .TRUE);

            //  setup
            size := ID3D12InfoQueue_GetStorageFilterStackSize(_d3d12InfoQueue);
            while size > 1 
            {
                ID3D12InfoQueue_ClearStorageFilter(_d3d12InfoQueue);
                size = ID3D12InfoQueue_GetStorageFilterStackSize(_d3d12InfoQueue);
            }

            size = ID3D12InfoQueue_GetRetrievalFilterStackSize(_d3d12InfoQueue);
            while size > 1 
            {
                ID3D12InfoQueue_ClearRetrievalFilter(_d3d12InfoQueue);
                size = ID3D12InfoQueue_GetRetrievalFilterStackSize(_d3d12InfoQueue);
            }

            ID3D12InfoQueue_ClearStoredMessages(_d3d12InfoQueue);
            ID3D12InfoQueue_SetMuteDebugOutput(_d3d12InfoQueue, .FALSE);
        } 
        else 
        {
            log_error("_d3d12Device.QueryInterface failed.");
        }
    }

    // Describe and create the command queue.
    queueDesc: D3D12_COMMAND_QUEUE_DESC;
    queueDesc.Flags = .NONE;
    queueDesc.Type  = .DIRECT;
    result = ID3D12Device_CreateCommandQueue(_d3d12Device, *queueDesc, *uid(ID3D12CommandQueue_UUID), xx *_d3d12Queue);
    if result != S_OK 
    {
        #if ASSERT_ON_FAIL assert(false, "_d3d12Device.CreateCommandQueue failed.");
        Deinit();
        return false;
    }

    // Wait idle fence
    result = ID3D12Device_CreateFence(_d3d12Device, 0, .NONE, *uid(ID3D12Fence_UUID), xx *_d3d12QueueWiFence);
    if result != S_OK 
    {
        #if ASSERT_ON_FAIL assert(false, "_d3d12Device.CreateFence failed.");
        Deinit();
        return false;
    }

    // Create an event handle.
    _d3d12QueueWiEvent = CreateEventW(null, 0, 0, null);
    if _d3d12QueueWiEvent == null 
    {
        #if ASSERT_ON_FAIL assert(false, "CreateEventW failed.");
        Deinit();
        return false;
    }

    log(" Done!\n");
    return true;
}

// --------------------------------------------------------
// Render Context: IDXGISwapChain3, ID3D12Resource, ID3D12DescriptorHeap
//
VSYNC :: false;
MAX_SWAPCHAIN_BUFFER_COUNT :: 3;

_d3d12Swapchain    : *IDXGISwapChain3;
_d3d12Rtvs         : [MAX_SWAPCHAIN_BUFFER_COUNT] *ID3D12Resource;
_d3d12RtvHeap     : *ID3D12DescriptorHeap;
_d3d12RtvHeapIncSize: u32;
_d3d12PresentFence: *ID3D12Fence;
_d3d12PresentEvent: *void;

_d3d12ScreenshotRTV: *ID3D12Resource;

_ctxBufferCount       : u32;  // use this to get actual count.
_ctxActiveBufferIndex : u32;
_ctxPresentCounter    : u64;

_InitRenderContext :: () -> bool 
{
    log("Init render context...\n");
    // SEE: https://devblogs.microsoft.com/directx/dxgi-flip-model/
    // SEE: https://docs.microsoft.com/en-us/windows/win32/api/dxgi/ne-dxgi-dxgi_swap_effect
    // Describe and create the swap chain.
    if !VSYNC 
    {
        _ctxBufferCount = 3;
    } 
    else 
    {
        _ctxBufferCount = 2; 
    }

    swapChainDesc: DXGI_SWAP_CHAIN_DESC1;
    swapChainDesc.BufferCount      = _ctxBufferCount;
    swapChainDesc.Width            = _width;
    swapChainDesc.Height           = _height;
    swapChainDesc.Format           = .R8G8B8A8_UNORM;
    swapChainDesc.BufferUsage      = .RENDER_TARGET_OUTPUT;
    swapChainDesc.SwapEffect       = .FLIP_SEQUENTIAL;//.FLIP_DISCARD; // NOTE: BufferCount must be > 1 for using "DXGI_SWAP_EFFECT_FLIP_DISCARD/DXGI_SWAP_EFFECT_FLIP_SEQUENTIAL"
    swapChainDesc.SampleDesc.Count = 1;

    result := IDXGIFactory2_CreateSwapChainForHwnd(_d3d12Factory,
        xx _d3d12Queue,    // Swapchain needs the queue so that it can force a flush on it.
        _hwnd,
        *swapChainDesc,
        null,
        null,
        xx *_d3d12Swapchain
        );

    if result != S_OK 
    {
        #if ASSERT_ON_FAIL assert(false, "d3d12_factory.CreateSwapChainForHwnd failed.");
        Deinit();
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

    log(" Done!\n");
    return true;
}

//--------------------------------------------------------
// Command Encoder: ID3D12CommandAllocator, ID3D12GraphicsCommandList
//
_d3d12CommandAllocator: *ID3D12CommandAllocator;
_d3d12CommandLists    : [FRAME_COUNT] *ID3D12GraphicsCommandList;
_d3d12SubmitFence     : *ID3D12Fence;
_d3d12SubmitEvent     : *void;

_activeFrameIndex: u32; 
_submitCounter    : u64;

_InitCommandEncoder :: () -> bool 
{
    log("Init command encoder...\n");
    // create command allocator
    result := ID3D12Device_CreateCommandAllocator(_d3d12Device, .DIRECT, *uid(ID3D12CommandAllocator_UUID), xx *_d3d12CommandAllocator);
    if result != S_OK 
    {
        #if ASSERT_ON_FAIL assert(false, "d3d12_device.CreateCommandAllocator failed.");
        Deinit();
        return false;
    }

    // Create the command lists.
    for i: 0..FRAME_COUNT-1 
    {
        result = ID3D12Device_CreateCommandList(_d3d12Device, 0, .DIRECT, _d3d12CommandAllocator, null, *uid(ID3D12GraphicsCommandList_UUID), xx *_d3d12CommandLists[i]);
        if result != S_OK 
        {
            #if ASSERT_ON_FAIL assert(false, "d3d12_device.CreateCommandList failed.");
            Deinit();
            return false;
        }
        // Command lists are created in the recording state, but there is nothing
        // to record yet. The main loop expects it to be closed, so close it now.
        ID3D12GraphicsCommandList_Close(_d3d12CommandLists[i]);
    }

    // Submit fence
    result = ID3D12Device_CreateFence(_d3d12Device, 0, .NONE, *uid(ID3D12Fence_UUID), xx *_d3d12SubmitFence);
    if result != S_OK 
    {
        #if ASSERT_ON_FAIL assert(false, "_d3d12Device.CreateFence failed.");
        Deinit();
        return false;
    }

    // Create an event handle.
    _d3d12SubmitEvent = CreateEventW(null, 0, 0, null);
    if _d3d12SubmitEvent == null 
    {
        #if ASSERT_ON_FAIL assert(false, "CreateEventW failed.");
        Deinit();
        return false;
    }

    log(" Done!\n");
    return true;
}