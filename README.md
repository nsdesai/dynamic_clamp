# dynamic_clamp
A fast, microcontroller-based dynamic clamp system

The system was introduced in this paper: Niraj S. Desai, Richard Gray, and Daniel Johnston. A dynamic clamp on every rig. eNeuro (DOI:10.1523/ENEURO.0250-17.2017).

The website www.dynamicclamp.com includes detailed instructions on how to assemble and use the system. It includes descriptions of recent updates.

This site (github.com) houses most of the associated software (Arduino, Processing, Matlab).

The original project was built on a breadboard and used Arduino/Processing software. Some alternatives you might consider:

(1) Aditya Asopa (https://github.com/AdityaAsopa) has designed a printed circuit board (PCB) version that can be used in place of the breadboard. It includes some nice additional features, including a toggle switch to bypass the dynamic clamp circuitry (useful if one wants to just work in current clamp). The PCB design files can be downloaded from this page (Circuit_and_PCB folder). A description will soon be added to www.dynamicclamp.com. 

(2) Christian Rickert has written alternative software (dyClamp and pyClamp) with extended functionality, including a Python-based control GUI. His software is described at https://dynamicclamp.com/python-alternative/ and is available through his Github account https://github.com/christianrickert.

(3) Kyle Wedgwood has written a Matlab controller that would replace the Processing sketch included here. It allows more flexibility in specifying which conductances to control, and is available through his Github account https://github.com/kyle-wedgwood/DynamicClampController.

Please direct any questions or comments about this Github site or the dynamic clamp project generally to Niraj S. Desai at niraj.desai3@nih.gov.
 


******************************************************************************************************************************************
Copyright 2019. Niraj S. Desai, Richard Gray, and Daniel Johnston.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
