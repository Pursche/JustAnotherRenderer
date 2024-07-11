#import "Basic";
#import "Windows";

Window :: #import "Window_Creation";
Input  :: #import "Input";
GlobalRenderModule :: #import,file "rendermodules/GlobalRenderModule.jai";

Context :: struct
{
    isCompileTime : bool = false;
    compileTimeStayOpen : bool = true;
}

// you can use any window module just we need the hwnd and window width/height
_hwnd: HWND;
_width: u32 = 800;
_height: u32 = 500;

Init :: (ctx: Context)
{
    print("Init\n");

    _hwnd = Window.create_window(_width, _height, "Just Another Renderer");
    GlobalRenderModule.Init(_hwnd, _width, _height);
}

Run :: (ctx: Context)
{
    print("Run\n");

    quit := false;
    if (ctx.isCompileTime)
    {
        quit = !ctx.compileTimeStayOpen;
    }

    now := current_time_monotonic();
    while !quit 
    { 
        Input.update_window_events();
        for Input.events_this_frame 
        {
            if it.type == .QUIT then quit = true;
        }

        previous := now;
        now = current_time_monotonic();
        dt := to_float64_seconds(now - previous);

        Update(dt);
        Render();
    }
}

Update :: (dt: float64)
{
    GlobalRenderModule.Update(dt);
}

Render :: ()
{
    GlobalRenderModule.Render();
}

