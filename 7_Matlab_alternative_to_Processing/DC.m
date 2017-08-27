% Matlab script to communicate with the Teensy 3.6 when it is in dynamic
% clamp mode.
%
% Calling DC without arguments opens the GUI and initializes all the
% numbers at 0.0.
% 
% The GUI calls the subfunctions by passing arguments.
%
% Last modified 06/11/17.

function [] = DC(varargin)

if (nargin==0)                          % initialize
    
    openfig('DC.fig','reuse');
    
    initializeteensy('COM3')            % replace COM3 with the name of
                                        % the USB port to which the Teensy
                                        % is connected

    zero;  
    
else                                    % feval switchyard
    
    if (nargout)
        [varargout{1:nargout}] = feval(varargin{:}); %#ok<NASGU>
    else
        feval(varargin{:});
    end
    
end


% -------------------------------------------------------------------------

function [] = initializeteensy(portName)
global teensy

teensy = serial(portName,'BaudRate',115200,'ByteOrder','littleEndian');
fopen(teensy);



% -------------------------------------------------------------------------

function [] = upload()
global teensy

g_shunt = get(findobj('Tag','g_shunt'),'Value');
g_HCN = get(findobj('Tag','g_HCN'),'Value');
g_Na = get(findobj('Tag','g_Na'),'Value');
m_OU_exc = get(findobj('Tag','m_OU_exc'),'Value');
D_OU_exc = get(findobj('Tag','D_OU_exc'),'Value');
m_OU_inh = get(findobj('Tag','m_OU_inh'),'Value');
D_OU_inh = get(findobj('Tag','D_OU_inh'),'Value');
g_EPSC = get(findobj('Tag','g_EPSC'),'Value');

out = [g_shunt; g_HCN; g_Na; m_OU_exc; D_OU_exc; m_OU_inh; D_OU_inh; g_EPSC];
out = typecast(single(out),'uint8'); 
fwrite(teensy,out);


% -------------------------------------------------------------------------

function [] = zero()

set(findobj('Tag','g_shunt'),'Value',0);
set(findobj('Tag','g_HCN'),'Value',0);
set(findobj('Tag','g_Na'),'Value',0);
set(findobj('Tag','m_OU_exc'),'Value',0);
set(findobj('Tag','D_OU_exc'),'Value',0);
set(findobj('Tag','m_OU_inh'),'Value',0);
set(findobj('Tag','D_OU_inh'),'Value',0);
set(findobj('Tag','g_EPSC'),'Value',0);

getnumbers
upload


% -------------------------------------------------------------------------
function [] = getnumbers()

g_shunt = get(findobj('Tag','g_shunt'),'Value');
g_HCN = get(findobj('Tag','g_HCN'),'Value');
g_Na = get(findobj('Tag','g_Na'),'Value');
m_OU_exc = get(findobj('Tag','m_OU_exc'),'Value');
D_OU_exc = get(findobj('Tag','D_OU_exc'),'Value');
m_OU_inh = get(findobj('Tag','m_OU_inh'),'Value');
D_OU_inh = get(findobj('Tag','D_OU_inh'),'Value');
g_EPSC = get(findobj('Tag','g_EPSC'),'Value');

set(findobj('Tag','g_shunt_Num'),'String',num2str(g_shunt,'%0.2f'))
set(findobj('Tag','g_HCN_Num'),'String',num2str(g_HCN,'%0.2f'))
set(findobj('Tag','g_Na_Num'),'String',num2str(g_Na,'%0.2f'))
set(findobj('Tag','m_OU_exc_Num'),'String',num2str(m_OU_exc,'%0.2f'))
set(findobj('Tag','D_OU_exc_Num'),'String',num2str(D_OU_exc,'%0.2f'))
set(findobj('Tag','m_OU_inh_Num'),'String',num2str(m_OU_inh,'%0.2f'))
set(findobj('Tag','D_OU_inh_Num'),'String',num2str(D_OU_inh,'%0.2f'))
set(findobj('Tag','g_EPSC_Num'),'String',num2str(g_EPSC,'%0.2f'))


% -------------------------------------------------------------------------

function [] = closedcfigure %#ok<*DEFNU>
global teensy

delete(findobj('Tag','DC_figure'))
fclose(teensy);
delete(teensy)
clear teensy


