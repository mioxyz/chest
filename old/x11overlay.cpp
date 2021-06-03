#include <assert.h>
#include <stdio.h>
#include <X11/Xlib.h>
#include <X11/X.h>
#include <X11/Xutil.h>

#include <cairo.h>
#include <cairo-xlib.h>

#include <chrono>
#include <thread>

/*
   note mio: pretty sure this will require window buffer switching thing, or else we can't do 
   transperancy, which is necessary to draw over windows, with the output not only being a 
   rectangle!
*/

void draw(cairo_t *cr) {
    cairo_set_source_rgba(cr, 1.0, 0.0, 0.0, 0.5);
    cairo_rectangle(cr, 0, 0, 200, 200);
    cairo_fill(cr);
}

int main() {
    Display *d = XOpenDisplay(NULL);
    Window root = DefaultRootWindow(d);
    int default_screen = XDefaultScreen(d);

    // these two lines are really all you need
    XSetWindowAttributes attrs;
    attrs.override_redirect = true;

    XVisualInfo vinfo;
    if (!XMatchVisualInfo(d, DefaultScreen(d), 32, TrueColor, &vinfo)) {
        printf("No visual found supporting 32 bit color, terminating\n");
        exit(EXIT_FAILURE);
    }
    // these next three lines add 32 bit depth, remove if you dont need and change the flags below
    attrs.colormap = XCreateColormap(d, root, vinfo.visual, AllocNone);
    attrs.background_pixel = 0;
    attrs.border_pixel = 0;

    // Window XCreateWindow(
    //     Display *display, Window parent,
    //    l int x, int y, unsigned int width, unsigned int height, unsigned int border_width,
    //     int depth, unsigned int class, 
    //     Visual *visual,
    //     unsigned long valuemask, XSetWindowAttributes *attributes
    // );
    Window overlay = XCreateWindow(
        d, root,
        0, 0, 200, 200, 0,
        vinfo.depth, 
        InputOutput, 
        vinfo.visual,
        CWOverrideRedirect | CWColormap | CWBackPixel | CWBorderPixel,
        &attrs
    );

    XMapWindow(d, overlay);

    cairo_surface_t* surf = cairo_xlib_surface_create(d, overlay,
                                  vinfo.visual,
                                  200, 200);

    cairo_t* cr = cairo_create(surf);

    draw(cr);
    XFlush(d);

    std::this_thread::sleep_for(std::chrono::milliseconds(10000));

    cairo_destroy(cr);
    cairo_surface_destroy(surf);

    XUnmapWindow(d, overlay);
    XCloseDisplay(d);
    return 0;
}

/*
I went ahead and added 32 bit depth, but you get the picture. You can remove it if you desire.

Share
Improve this answer
Follow
edited Sep 4 '19 at 6:16
answered Sep 4 '19 at 2:35

Asad-ullah Khan
65366 silver badges1717 bronze badges
For me, this blocks mouse events on Ubuntu 18.04 with GNOME 3. – David Zhao Akeley Jul 7 '20 at 23:16
You mean you can't move mouse at all while it is running? Or that you cannot interact with things drawn on the overlay? Only thing I can think of is my sleep call possibly interfering, maybe try a different sleep call? – Asad-ullah Khan Jul 8 '20 at 8:31
Mouse works fine outside the overlay window; what I experience is that mouse clicks in the region of the window do not get passed on to the window behind the transparent window. On re-reading, I'm not sure this was actually a design goal of this program. – David Zhao Akeley Jul 9 '20 at 23:48
Ah yes you will probably need to pass the events down to window below somehow. I am not sure how to do this. This answer may be of use: stackoverflow.com/questions/16400937/… – Asad-ullah Khan Jul 10 '20 at 22:12
Add a comment

4

sleep(50)! that's too much, it's 50 seconds. I used 5ms delay which works well.

Your problem seems with the runtime environment. You should have a composite display manager running already. (Not all display managers work as expected, better to try on different ones)

I confirm that screen below updated without any problem and I could interact with it.

This was run on:

Ubuntu 15.10
Kernel 4.2.0-18-generic
X.Org X Server 1.17.2
Compiz 0.9.12.2
Here the full code with just delay modification:

#include <assert.h>
#include <stdio.h>
#include <time.h>
#include <X11/Xlib.h>

#include <X11/extensions/Xcomposite.h>
#include <X11/extensions/Xfixes.h>
#include <X11/extensions/shape.h>

#include <cairo.h>
#include <cairo-xlib.h>

Display *d;
Window overlay;
Window root;
int width, height;

void
allow_input_passthrough (Window w)
{
    XserverRegion region = XFixesCreateRegion (d, NULL, 0);

    XFixesSetWindowShapeRegion (d, w, ShapeBounding, 0, 0, 0);
    XFixesSetWindowShapeRegion (d, w, ShapeInput, 0, 0, region);

    XFixesDestroyRegion (d, region);
}

void
prep_overlay (void)
{
    overlay = XCompositeGetOverlayWindow (d, root);
    allow_input_passthrough (overlay);
}

void draw(cairo_t *cr) {
    int quarter_w = width / 4;
    int quarter_h = height / 4;
    cairo_set_source_rgb(cr, 1.0, 0.0, 0.0);
    cairo_rectangle(cr, quarter_w, quarter_h, quarter_w * 2, quarter_h * 2);
    cairo_fill(cr);
}

int main() {
    struct timespec ts = {0, 5000000};

    d = XOpenDisplay(NULL);

    int s = DefaultScreen(d);
    root = RootWindow(d, s);

    XCompositeRedirectSubwindows (d, root, CompositeRedirectAutomatic);
    XSelectInput (d, root, SubstructureNotifyMask);

    width = DisplayWidth(d, s);
    height = DisplayHeight(d, s);

    prep_overlay();

    cairo_surface_t *surf = cairo_xlib_surface_create(d, overlay,
                                  DefaultVisual(d, s),
                                  width, height);
    cairo_t *cr = cairo_create(surf);

    XSelectInput(d, overlay, ExposureMask);

    draw(cr);

    XEvent ev;
    while(1) {
      overlay = XCompositeGetOverlayWindow (d, root);
      draw(cr);
      XCompositeReleaseOverlayWindow (d, root);
      nanosleep(&ts, NULL);
    }

    cairo_destroy(cr);
    cairo_surface_destroy(surf);
    XCloseDisplay(d);
    return 0;
}
X11 overlay on Ubuntu 15.10

*/