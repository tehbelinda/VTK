# Prototype segmentation pipline


set sliceNumber 11

set VTK_FLOAT              1
set VTK_INT                2
set VTK_SHORT              3
set VTK_UNSIGNED_SHORT     4
set VTK_UNSIGNED_CHAR      5

set VTK_IMAGE_X_AXIS             0
set VTK_IMAGE_Y_AXIS             1
set VTK_IMAGE_Z_AXIS             2
set VTK_IMAGE_TIME_AXIS          3
set VTK_IMAGE_COMPONENT_AXIS     4




# Image pipeline

vtkImageShortReader4D reader;
#reader DebugOn
reader SwapBytesOn;
reader SetDimensions 256 256 94 1;
reader SetAspectRatio 1 1 4 0;
reader SetFilePrefix "../../data/fullHead/headsq";
reader SetPixelMask 0x7fff;

# there is no shrink2D yet.
vtkImageShrink3D shrink;
shrink SetInput [reader GetOutput];
shrink SetShrinkFactors 4 4 1;
# Add Max
shrink AveragingOn;
shrink ReleaseDataFlagOff;

# ReplaceOut is not working for some reason. debug later..
vtkImageThreshold thresh1;
thresh1 SetOutputScalarType $VTK_UNSIGNED_CHAR;
thresh1 SetInput [reader GetOutput];
thresh1 ThresholdByUpper 2000.0;
thresh1 SetInValue 255;
thresh1 ReplaceInOn;
thresh1 SetOutValue 0;
thresh1 ReplaceOutOn;

vtkImageThreshold thresh2;
thresh2 SetOutputScalarType $VTK_UNSIGNED_CHAR;
thresh2 SetInput [shrink GetOutput];
thresh2 ThresholdByUpper 1000.0;
thresh2 SetInValue 0;
thresh2 ReplaceInOn;

# connectivity

# We might combine dilate and subtract (bone 1, transition 2, all else 0)
vtkImageDilateErode3D dilate;
dilate SetInput [thresh1 GetOutput];
dilate SetDilateValue 255;
dilate SetErodeValue 0;
dilate SetKernelSize 3 3 3;

vtkImageArithmetic subtract;
subtract SetInput1 [dilate GetOutput];
subtract SetInput2 [thresh1 GetOutput];
subtract ReleaseDataFlagOff;


# will be an adaptive median with subtract as input too.
vtkImageMedian median;
median SetInput [shrink GetOutput];
median SetKernelSize 5 5 5;




# here for debugging
vtkImageXViewer viewer;
#viewer DebugOn;
viewer SetAxes $VTK_IMAGE_X_AXIS $VTK_IMAGE_Y_AXIS $VTK_IMAGE_Z_AXIS;
viewer SetInput [subtract GetOutput];
viewer SetCoordinate2 $sliceNumber;
viewer SetColorWindow 255
viewer SetColorLevel 128
viewer Render;


#make interface
#

frame .slice
button .slice.up -text "Slice Up" -command SliceUp
button .slice.down -text "Slice Down" -command SliceDown

frame .wl
frame .wl.f1;
label .wl.f1.windowLabel -text Window;
scale .wl.f1.window -from 1 -to 3000 -orient horizontal -command SetWindow
frame .wl.f2;
label .wl.f2.levelLabel -text Level;
scale .wl.f2.level -from 1 -to 1500 -orient horizontal -command SetLevel
checkbutton .wl.video -text "Inverse Video" -variable inverseVideo -command SetInverseVideo


.wl.f1.window set 3000
.wl.f2.level set 1500


pack .slice .wl -side left
pack .slice.up .slice.down -side top
pack .wl.f1 .wl.f2 .wl.video -side top
pack .wl.f1.windowLabel .wl.f1.window -side left
pack .wl.f2.levelLabel .wl.f2.level -side left


proc SliceUp {} {
   global sliceNumber viewer
   if {$sliceNumber < 46} {set sliceNumber [expr $sliceNumber + 1]}
   puts $sliceNumber
   viewer SetCoordinate2 $sliceNumber;
   viewer Render;
}

proc SliceDown {} {
   global sliceNumber viewer
   if {$sliceNumber > 0} {set sliceNumber [expr $sliceNumber - 1]}
   puts $sliceNumber
   viewer SetCoordinate2 $sliceNumber;
   viewer Render;
}

proc SetWindow window {
   global viewer
   viewer SetColorWindow $window;
   viewer Render;
}

proc SetLevel level {
   global viewer
   viewer SetColorLevel $level;
   viewer Render;
}

proc SetInverseVideo {} {
   global viewer
   if { $inverseVideo == 0 } {
      viewer SetWindow -255;
   } else {
      viewer SetWindow 255;
   }		
   viewer Render;
}


puts "Done";


#$renWin Render
#wm withdraw .








