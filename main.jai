#import "Basic";
App :: #import,file "src/App.jai";

#import "d3d12"()(INCLUDE_DEBUG_BINDINGS = true);

main :: () 
{
    ctx: App.Context;

    App.Init(ctx);
    App.Run(ctx);
    print("Bye Jai\n");
}

test :: ()
{
    print("Compiletime!\n");
    ctx: App.Context;
    ctx.isCompileTime = true;

    App.Init(ctx);
    App.Run(ctx);
    print("Bye Jai\n");
}

#run test();