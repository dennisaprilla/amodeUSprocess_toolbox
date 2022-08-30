function varargout = uswindowsignal_toolbox(varargin)
% USWINDOWSIGNAL_TOOLBOX MATLAB code for uswindowsignal_toolbox.fig
%      USWINDOWSIGNAL_TOOLBOX, by itself, creates a new USWINDOWSIGNAL_TOOLBOX or raises the existing
%      singleton*.
%
%      H = USWINDOWSIGNAL_TOOLBOX returns the handle to a new USWINDOWSIGNAL_TOOLBOX or the handle to
%      the existing singleton*.
%
%      USWINDOWSIGNAL_TOOLBOX('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in USWINDOWSIGNAL_TOOLBOX.M with the given input arguments.
%
%      USWINDOWSIGNAL_TOOLBOX('Property','Value',...) creates a new USWINDOWSIGNAL_TOOLBOX or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before uswindowsignal_toolbox_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to uswindowsignal_toolbox_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help uswindowsignal_toolbox

% Last Modified by GUIDE v2.5 14-Oct-2021 10:38:57

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @uswindowsignal_toolbox_OpeningFcn, ...
                   'gui_OutputFcn',  @uswindowsignal_toolbox_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end


% End initialization code - DO NOT EDIT


% --- Executes just before uswindowsignal_toolbox is made visible.
function uswindowsignal_toolbox_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to uswindowsignal_toolbox (see VARARGIN)

addpath('functions');
addpath('functions/displays');
addpath('functions/gui');

% disable everything so the user not fucking up the order of the process
gui_toggleElement(handles, 'off');

% Choose default command line output for uswindowsignal_toolbox
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes uswindowsignal_toolbox wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = uswindowsignal_toolbox_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function edit_path_Callback(hObject, eventdata, handles)
% hObject    handle to edit_path (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_path as text
%        str2double(get(hObject,'String')) returns contents of edit_path as a double


% --- Executes during object creation, after setting all properties.
function edit_path_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_path (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in button_openfolder.
function button_openfolder_Callback(hObject, eventdata, handles)
% hObject    handle to button_openfolder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get path
dname = uigetdir(pwd);
set(handles.edit_path, 'String', dname);

% read data
[data, timestamps, indexes] = readTIFF_USsignal(dname, 30, 1500);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% preparing constants for data spesification
data_spec.n_ust     = size(data, 1);
data_spec.n_samples = size(data, 2);
data_spec.n_frames  = size(data, 3);

% preparing constants for ultrasound spesification
us_spec.v_sound     = 1540e3; % mm/s
us_spec.sample_rate = 50e6;
us_spec.index2distance_constant  = us_spec.v_sound / (2 * us_spec.sample_rate);
x_axis_values = (1:data_spec.n_samples) .* us_spec.index2distance_constant;

% signal processing
envelope_data = process_USsignal(data, data_spec, us_spec);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% preparing the dropdown menu for probes
popup_probenumber_options = {};
for i=1:data_spec.n_ust
    popup_probenumber_options{i}=i;
end
set(handles.popup_probenumber, 'String', popup_probenumber_options)
% for initialization show probe number 16
probeNumber_toShow = 16;
set(handles.popup_probenumber, 'Value', probeNumber_toShow)


% initialization of probes properties
default_center = str2num(get(handles.edit_windowcenter, 'String'));
default_width = str2num(get(handles.edit_windowwidth, 'String'));

probeProperties = table( 'Size', [1,2], ...
                      'VariableTypes', ["double", "double"], ...
                      'VariableNames', ["WindowPosition", "WindowWidth"]);

for i=1:data_spec.n_ust
    % set the probeProperties
    probeProperties.WindowPosition(i) = default_center;
    probeProperties.WindowWidth(i)    = default_width;
end
set(handles.uitable_properties, 'Data', [probeProperties.WindowPosition, probeProperties.WindowWidth]);

% initialize the timestamp slider
gui_setSlider( handles.slider_timestamp, 1, data_spec.n_frames, 1, 1, 10);

% initialize the window slider
gui_setSlider( handles.slider_windowcenter, 1, 20, ...
               probeProperties.WindowPosition(probeNumber_toShow), ...
               0.25, 1);
gui_setSlider( handles.slider_windowwidth, 1, 10, ...
               probeProperties.WindowWidth(probeNumber_toShow), ...
               0.25, 1);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% show a-mode
timestamp_toshow = 1;
display_amode( handles.axes_amode, ...
               probeNumber_toShow, ...
               timestamp_toshow, ...
               data, ...
               envelope_data, ...
               x_axis_values, ...
               'plot_raw1', ...
               'plot_env1');
% need to do this because everytime i display a-mode it always followed by
% their window in the same axes in this application.
hold(handles.axes_amode, 'on');
          
% show signal window
display_signalwindow_amode( handles.axes_amode, ...
                            probeProperties.WindowPosition(probeNumber_toShow), ...
                            probeProperties.WindowWidth(probeNumber_toShow), ...
                            'plot_amode_windowcenter', ...
                            'plot_amode_windowwidth');

% show m-mode
display_mmode(handles.axes_mmode, ...
              probeNumber_toShow, ...
              envelope_data, ...
              data_spec, ...
              x_axis_values);

% display timestamp for m-mode
display_timestamp_mmode(handles.axes_mmode, timestamp_toshow);

% show signal window
display_signalwindow_mmode( handles.axes_mmode, ...
                            probeProperties.WindowPosition(probeNumber_toShow), ...
                            probeProperties.WindowWidth(probeNumber_toShow), ...
                            'plot_mmode_windowcenter', ...
                            'plot_mmode_windowwidth');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% enable all gui element, now the user can do whatever he/she wants
gui_toggleElement(handles, 'on');
% but not the pause button, i need to prevent the user to not pressing
% pause before they press start button
set(handles.button_pause, 'Enable', 'off');


% store necessary variable to global variable
handles.data_spec = data_spec;
handles.us_spec = us_spec;
handles.x_axis_values = x_axis_values;
handles.data = data;
handles.envelope_data = envelope_data;
% handles.allpeaks = allpeaks;
handles.timestamp_toshow = timestamp_toshow;
handles.probeNumber_toShow = probeNumber_toShow;
handles.probeProperties = probeProperties;

% Update handles structure
guidata(hObject, handles);


% --- Executes on selection change in popup_probenumber.
function popup_probenumber_Callback(hObject, eventdata, handles)
% hObject    handle to popup_probenumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popup_probenumber contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popup_probenumber

% get necessary variable from global
probeProperties    = handles.probeProperties;

% get value from gui
probeNumber_toShow = get(hObject,'Value');

% set the slider window according the the current properties of selected probe
set( handles.slider_windowcenter, 'Value', ...
     probeProperties.WindowPosition(probeNumber_toShow));
set( handles.slider_windowwidth, 'Value', ...
     probeProperties.WindowWidth(probeNumber_toShow));
% set the edittext window according the the current properties of selected probe
set( handles.edit_windowcenter, 'String', ...
     num2str(probeProperties.WindowPosition(probeNumber_toShow)));
set( handles.edit_windowwidth, 'String', ...
     num2str(probeProperties.WindowWidth(probeNumber_toShow)));

% get necessary value from global variable
data             = handles.data;
envelope_data    = handles.envelope_data;
% allpeaks         = handles.allpeaks;
x_axis_values    = handles.x_axis_values;
data_spec        = handles.data_spec;
timestamp_toshow = handles.timestamp_toshow;

% show a-mode
display_amode( handles.axes_amode, ...
               probeNumber_toShow, ...
               timestamp_toshow, ...
               data, ...
               envelope_data, ...
               x_axis_values, ...
               'plot_raw1', ...
               'plot_env1');
% need to do this because everytime i display a-mode it always followed by
% their window in the same axes in this application.
hold(handles.axes_amode, 'on');
           

% draw a-mode window
display_signalwindow_amode( handles.axes_amode, ...
                            probeProperties.WindowPosition(probeNumber_toShow), ...
                            probeProperties.WindowWidth(probeNumber_toShow), ...
                            'plot_amode_windowcenter', ...
                            'plot_amode_windowwidth');

% show m-mode
display_mmode(handles.axes_mmode, probeNumber_toShow, envelope_data, data_spec, x_axis_values)


% draw m-mode window
display_signalwindow_mmode( handles.axes_mmode, ...
                            probeProperties.WindowPosition(probeNumber_toShow), ...
                            probeProperties.WindowWidth(probeNumber_toShow), ...
                            'plot_mmode_windowcenter', ...
                            'plot_mmode_windowwidth');
                        
% draw peaks if only the user already detect the peak
if get(handles.button_detectdepth, 'userdata')
    % plot the peaks in the m-mode axes
    display_peak_mmode(handles.axes_mmode, handles.allpeaks, probeNumber_toShow, 'plot_peaks_mmode')
end
                        
% display the timestamp line in m-mode axes
display_timestamp_mmode(handles.axes_mmode, timestamp_toshow);

% put necessary variable to global variable
handles.probeNumber_toShow = probeNumber_toShow;

% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function popup_probenumber_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popup_probenumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function slider_windowcenter_Callback(hObject, eventdata, handles)
% hObject    handle to slider_windowcenter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

% get necessary variable from global
probeNumber_toShow = handles.probeNumber_toShow;
probeProperties    = handles.probeProperties;

% get necessary value from gui
probeProperties.WindowPosition(probeNumber_toShow) = get(handles.slider_windowcenter, 'Value');
probeProperties.WindowWidth(probeNumber_toShow)    = get(handles.slider_windowwidth, 'Value');

% set the edittext
set(handles.edit_windowcenter, 'String', probeProperties.WindowPosition(probeNumber_toShow));

% draw window
display_signalwindow_amode( handles.axes_amode, ...
                            probeProperties.WindowPosition(probeNumber_toShow), ...
                            probeProperties.WindowWidth(probeNumber_toShow), ...
                            'plot_amode_windowcenter', ...
                            'plot_amode_windowwidth');
display_signalwindow_mmode( handles.axes_mmode, ...
                            probeProperties.WindowPosition(probeNumber_toShow), ...
                            probeProperties.WindowWidth(probeNumber_toShow), ...
                            'plot_mmode_windowcenter', ...
                            'plot_mmode_windowwidth');
                        
% update gui table
gui_updateRowTable( handles.uitable_properties, ...
                    probeNumber_toShow, ...
                    [ probeProperties.WindowPosition(probeNumber_toShow), ...
                      probeProperties.WindowWidth(probeNumber_toShow) ] );

% store the necessary value to global variable
handles.probeProperties = probeProperties;

% Update handles structure
guidata(hObject, handles);




% --- Executes during object creation, after setting all properties.
function slider_windowcenter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_windowcenter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function slider_windowwidth_Callback(hObject, eventdata, handles)
% hObject    handle to slider_windowwidth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

% get necessary variable from global
probeNumber_toShow = handles.probeNumber_toShow;
probeProperties = handles.probeProperties;

% get necessary value from gui
probeProperties.WindowPosition(probeNumber_toShow) = get(handles.slider_windowcenter, 'Value');
probeProperties.WindowWidth(probeNumber_toShow)    = get(handles.slider_windowwidth, 'Value');

% set the edit text
set(handles.edit_windowwidth, 'String', probeProperties.WindowWidth(probeNumber_toShow));

% draw window
display_signalwindow_amode( handles.axes_amode, ...
                            probeProperties.WindowPosition(probeNumber_toShow), ...
                            probeProperties.WindowWidth(probeNumber_toShow), ...
                            'plot_amode_windowcenter', ...
                            'plot_amode_windowwidth');
display_signalwindow_mmode( handles.axes_mmode, ...
                            probeProperties.WindowPosition(probeNumber_toShow), ...
                            probeProperties.WindowWidth(probeNumber_toShow), ...
                            'plot_mmode_windowcenter', ...
                            'plot_mmode_windowwidth');
                        
% update gui table
gui_updateRowTable( handles.uitable_properties, ...
                    probeNumber_toShow, ...
                    [ probeProperties.WindowPosition(probeNumber_toShow), ...
                      probeProperties.WindowWidth(probeNumber_toShow) ] );

% store the necessary value to global variable
handles.probeProperties = probeProperties;

% Update handles structure
guidata(hObject, handles);




% --- Executes during object creation, after setting all properties.
function slider_windowwidth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_windowwidth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function edit_windowcenter_Callback(hObject, eventdata, handles)
% hObject    handle to edit_windowcenter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_windowcenter as text
%        str2double(get(hObject,'String')) returns contents of edit_windowcenter as a double


% --- Executes during object creation, after setting all properties.
function edit_windowcenter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_windowcenter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_windowwidth_Callback(hObject, eventdata, handles)
% hObject    handle to edit_windowwidth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_windowwidth as text
%        str2double(get(hObject,'String')) returns contents of edit_windowwidth as a double


% --- Executes during object creation, after setting all properties.
function edit_windowwidth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_windowwidth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in button_play.
function button_play_Callback(hObject, eventdata, handles)
% hObject    handle to button_play (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get necessary value from global variable
data_spec           = handles.data_spec;
timestamp_toshow    = handles.timestamp_toshow;
probeNumber_toShow  = handles.probeNumber_toShow;

% set play button to diasble, so user can't messed up with the order
set(handles.button_play, 'Enable', 'off');
set(handles.button_export, 'Enable', 'off');
set(handles.button_detectdepth, 'Enable', 'off');
set(handles.button_pause, 'Enable', 'on');
% set the popupmenu for probe number to off, somehow MATLAB can't detect
% there is a change when we are in a loop (the next loop). So better turn
% it off while playing the recording.
set(handles.popup_probenumber, 'Enable', 'off');

% loop from the specified timestamp by user
for timestamp=timestamp_toshow:data_spec.n_frames    

    % draw amode
    display_amode( handles.axes_amode, ...
                   probeNumber_toShow, ...
                   timestamp, ...
                   handles.data, ...
                   handles.envelope_data, ...
                   handles.x_axis_values, ...
                   'plot_raw1', ...
                   'plot_env1');
    % need to do this because everytime i display a-mode it always followed by
    % their window in the same axes in this application.
    hold(handles.axes_amode, 'on');
    
    % draw the timestamp in mmode axes
    display_timestamp_mmode(handles.axes_mmode, timestamp);
    % set the timestamp slider according to the loop
    set(handles.slider_timestamp,'Value', timestamp);
    % set the timestamp edit according to the loop    
    set(handles.edit_timestamp, 'String', num2str(timestamp));
    % store the timestamp according to the loop
    handles.timestamp_toshow = timestamp;
    
    drawnow;

	% if user press pause, stop at the last timestamp
    if get(handles.button_pause, 'userdata')
        
        set(handles.button_pause, 'userdata', 0); 
        set(handles.button_pause, 'Enable', 'off');
        
		break;
    end
        
end

% turn on again after finished
set(handles.button_play, 'Enable', 'on');
set(handles.button_export, 'Enable', 'on');
set(handles.button_detectdepth, 'Enable', 'on');
set(handles.button_pause, 'Enable', 'off');
set(handles.popup_probenumber, 'Enable', 'on');

% Update handles structure
guidata(hObject, handles);



% --- Executes on button press in button_pause.
function button_pause_Callback(hObject, eventdata, handles)
% hObject    handle to button_pause (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.button_pause, 'userdata', 1);

% --- Executes on slider movement.
function slider_timestamp_Callback(hObject, eventdata, handles)
% hObject    handle to slider_timestamp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

% get the value from the slider
timestamp_toshow = round(get(handles.slider_timestamp,'Value'));
set(handles.slider_timestamp,'Value', timestamp_toshow);

% change the timestamp in a-mode axes
display_amode( handles.axes_amode, ...
               handles.probeNumber_toShow, ...
               handles.timestamp_toshow, ...
               handles.data, ...
               handles.envelope_data, ...
               handles.x_axis_values, ...
               'plot_raw1', ...
               'plot_env1');
% need to hold on because everytime i display a-mode it always followed by
% their window in the same axes in this application.
hold(handles.axes_amode, 'on');

% draw the a-mode window
display_signalwindow_amode( handles.axes_amode, ...
                            handles.probeProperties.WindowPosition(handles.probeNumber_toShow), ...
                            handles.probeProperties.WindowWidth(handles.probeNumber_toShow), ...
                            'plot_amode_windowcenter', ...
                            'plot_amode_windowwidth');
 
% change the timestamp line in m-mode axes
display_signalwindow_mmode( handles.axes_mmode, ...
                            handles.probeProperties.WindowPosition(handles.probeNumber_toShow), ...
                            handles.probeProperties.WindowWidth(handles.probeNumber_toShow), ...
                            'plot_mmode_windowcenter', ...
                            'plot_mmode_windowwidth');
 
% change the timestamp line in m-mode axes
delete(findobj('Tag', 'plot_timestamp'));
xline(handles.axes_mmode, timestamp_toshow, '-', 'Timestamp', 'LineWidth', 2, 'Color', 'r',  'Tag', 'plot_timestamp');

% change the edit text to give information to user
set(handles.edit_timestamp, 'String', num2str(timestamp_toshow));

% store necessary variables to global variable
handles.timestamp_toshow = timestamp_toshow;

% Update handles structure
guidata(hObject, handles);



% --- Executes during object creation, after setting all properties.
function slider_timestamp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_timestamp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function edit_timestamp_Callback(hObject, eventdata, handles)
% hObject    handle to edit_timestamp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_timestamp as text
%        str2double(get(hObject,'String')) returns contents of edit_timestamp as a double


% --- Executes during object creation, after setting all properties.
function edit_timestamp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_timestamp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in button_export.
function button_export_Callback(hObject, eventdata, handles)
% hObject    handle to button_export (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

probeProperties = handles.probeProperties;
uisave('probeProperties')



function edit_pathwindowconf_Callback(hObject, eventdata, handles)
% hObject    handle to edit_pathwindowconf (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_pathwindowconf as text
%        str2double(get(hObject,'String')) returns contents of edit_pathwindowconf as a double


% --- Executes during object creation, after setting all properties.
function edit_pathwindowconf_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_pathwindowconf (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in button_openwindowconf.
function button_openwindowconf_Callback(hObject, eventdata, handles)
% hObject    handle to button_openwindowconf (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get necessary variable from global variable
probeNumber_toShow = handles.probeNumber_toShow;

% get path to window properties
[fname, path] = uigetfile('*.mat');
set(handles.edit_pathwindowconf, 'String', strcat(path,fname));

% load window properties
load(strcat(path,fname));

% setting up every gui that is related to the window
% window slider
set(handles.slider_windowcenter, 'Value', probeProperties.WindowPosition(probeNumber_toShow));
set(handles.slider_windowwidth, 'Value', probeProperties.WindowWidth(probeNumber_toShow));
% window edit
set(handles.edit_windowcenter, 'String', num2str(probeProperties.WindowPosition(probeNumber_toShow)));
set(handles.edit_windowwidth, 'String', num2str(probeProperties.WindowWidth(probeNumber_toShow)));
% draw window on amode
display_signalwindow_amode( handles.axes_amode, ...
                            probeProperties.WindowPosition(probeNumber_toShow), ...
                            probeProperties.WindowWidth(probeNumber_toShow), ...
                            'plot_amode_windowcenter', ...
                            'plot_amode_windowwidth');
% draw window on bmode
display_signalwindow_mmode( handles.axes_mmode, ...
                            probeProperties.WindowPosition(probeNumber_toShow), ...
                            probeProperties.WindowWidth(probeNumber_toShow), ...
                            'plot_mmode_windowcenter', ...
                            'plot_mmode_windowwidth');
% set the window properties table
set(handles.uitable_properties, 'Data', [probeProperties.WindowPosition, probeProperties.WindowWidth]);

% store new probeProperties to global variable
handles.probeProperties = probeProperties;

% update handles structure
guidata(hObject, handles);


% --- Executes on button press in button_detectdepth.
function button_detectdepth_Callback(hObject, eventdata, handles)
% hObject    handle to button_detectdepth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get necessary variable from global variable
probeProperties = handles.probeProperties;
probeNumber_toShow = handles.probeNumber_toShow;

data_spec       = handles.data_spec;
us_spec         = handles.us_spec;

% define window range
probeProperties.WindowRange = [1 1].*probeProperties.WindowPosition + [-1 1].*0.5.*probeProperties.WindowWidth;
% convert windows mm to windows indices
probeProperties.WindowRange_i = floor(probeProperties.WindowRange / us_spec.index2distance_constant + 1);

% signal pre-processing
[allpeaks, envelope_clipped] = peaks_USsignal_windowed( handles.data, ...
                                                        data_spec, ...
                                                        us_spec, ...
                                                        probeProperties.WindowRange, ...
                                                        probeProperties.WindowRange_i);

% save the peaks
uisave('allpeaks');
% set userdata in the button as 1, indication that the user already press
% this button to detect the peak
set(handles.button_detectdepth, 'userdata', 1);

% plot the peaks in the m-mode axes
display_peak_mmode(handles.axes_mmode, allpeaks, probeNumber_toShow, 'plot_peaks_mmode')

% store new probeProperties to global variable
handles.probeProperties = probeProperties;
handles.allpeaks = allpeaks;


% Update handles structure
guidata(hObject, handles);
