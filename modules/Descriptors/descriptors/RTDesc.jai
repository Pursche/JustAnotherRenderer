#import "Windows";
#import "d3d12";
#import "dxgi";

RTDesc :: struct
{

}

SwapChainRTDesc :: struct
{
    width: u32;
    height: u32;
    bufferCount: u32;
    format: DXGI_FORMAT;

    hwnd: HWND;
}

RTHandle :: #type, distinct s32;
INVALID_RT_HANDLE: RTHandle = -1;