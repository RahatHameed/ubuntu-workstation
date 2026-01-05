#!/bin/bash
# Start Plank dock with X11 backend (fixes Wayland compatibility)
sleep 3 && GDK_BACKEND=x11 plank
