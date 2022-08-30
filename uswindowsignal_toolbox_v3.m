function varargout = uswindowsignal_toolbox_v3(varargin)
% USWINDOWSIGNAL_TOOLBOX_V3 MATLAB code for uswindowsignal_toolbox_v3.fig
%      USWINDOWSIGNAL_TOOLBOX_V3, by itself, creates a new USWINDOWSIGNAL_TOOLBOX_V3 or raises the existing
%      singleton*.
%
%      H = USWINDOWSIGNAL_TOOLBOX_V3 returns the handle to a new USWINDOWSIGNAL_TOOLBOX_V3 or the handle to
%      the existing singleton*.
%
%      USWINDOWSIGNAL_TOOLBOX_V3('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in USWINDOWSIGNAL_TOOLBOX_V3.M with the given input arguments.
%
%      USWINDOWSIGNAL_TOOLBOX_V3('Property','Value',...) creates a new USWINDOWSIGNAL_TOOLBOX_V3 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before uswindowsignal_toolbox_v3_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to uswindowsignal_toolbox_v3_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help uswindowsignal_toolbox_v3

% Last Modified by GUIDE v2.5 30-Aug-2022 19:00:02

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @uswindowsignal_toolbox_v3_OpeningFcn, ...
                   'gui_OutputFcn',  @uswindowsignal_toolbox_v3_OutputFcn, ...
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


% --- Executes just before uswindowsignal_toolbox_v3 is made visible.
function uswindowsignal_toolbox_v3_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to uswindowsignal_toolbox_v3 (see VARARGIN)

addpath('functions');
addpath('functions/displays');
addpath('functions/gui');
addpath(genpath('functions/external'));

% disable everything so the user not fucking up the order of the process
gui_toggleElement(handles, 'off');

% Choose default command line output for uswindowsignal_toolbox_v3
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes uswindowsignal_toolbox_v3 wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = uswindowsignal_toolbox_v3_OutputFcn(hObject, eventdata, handles) 
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

% show m-mode
display_mmode(handles.axes_mmode, ...
              probeNumber_toShow, ...
              envelope_data, ...
              data_spec, ...
              x_axis_values);

% display timestamp for m-mode
display_timestamp_mmode(handles.axes_mmode, timestamp_toshow);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% enable window properties edit and button, so that the user is forced to
% load the .ini file first
set(handles.edit_pathwindowconf, 'Enable', 'on');
set(handles.button_openwindowconf, 'Enable', 'on');

% store necessary variable to global variable
handles.data_spec           = data_spec;
handles.us_spec             = us_spec;
handles.x_axis_values       = x_axis_values;
handles.data                = data;
handles.envelope_data       = envelope_data;
% handles.allpeaks          = allpeaks;
handles.timestamp_toshow    = timestamp_toshow;
handles.probeNumber_toShow  = probeNumber_toShow;

% Update handles structure
guidata(hObject, handles);



% --- Executes on button press in button_openwindowconf.
function button_openwindowconf_Callback(hObject, eventdata, handles)
% hObject    handle to button_openwindowconf (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get necessary variable from global variable
probeNumber_toShow = handles.probeNumber_toShow;
data_spec          = handles.data_spec;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get path to window properties
[fname, path] = uigetfile('*.ini');
set(handles.edit_pathwindowconf, 'String', strcat(path,fname));

% this code requires ini2struct function which can be found here:
% https://nl.mathworks.com/matlabcentral/fileexchange/17177-ini2struct
probeConfigStruct = ini2struct(strcat(path,fname));

% initialize a table for containing the probe properties
probeProperties = table( 'Size', [1,2], ...
                      'VariableTypes', ["double", "double"], ...
                      'VariableNames', ["WindowLowerBound", "WindowUpperBound"]);

% get the field names
probeConfig_fieldnames = fieldnames(probeConfigStruct);
% loop through all the fields
for i=1:data_spec.n_ust
    % get lower and upper bound data
    lowerbound_str = probeConfigStruct.(probeConfig_fieldnames{i}).LowerBound;
    upperbound_str = probeConfigStruct.(probeConfig_fieldnames{i}).UpperBound;
    
    % but because it is string, and the US machine somehow uses comma 
    % separator for floating point, so we need to replace the comma as 
    % point first, then convert it to double.
    probeProperties.WindowLowerBound(i) = str2double(strrep(lowerbound_str, ',', '.'));
    probeProperties.WindowUpperBound(i) = str2double(strrep(upperbound_str, ',', '.'));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialize the timestamp slider
gui_setSlider( handles.slider_timestamp, 1, data_spec.n_frames, 1, 1, 10);
% initialize the window slider
gui_setSlider( handles.slider_windowlowerbound, 0.5, 20, ...
               probeProperties.WindowLowerBound(probeNumber_toShow), ...
               0.25, 1);
gui_setSlider( handles.slider_windowupperbound, 1, 20, ...
               probeProperties.WindowUpperBound(probeNumber_toShow), ...
               0.25, 1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% setting up every gui that is related to the window
% window slider
set(handles.slider_windowlowerbound, 'Value', probeProperties.WindowLowerBound(probeNumber_toShow));
set(handles.slider_windowupperbound, 'Value', probeProperties.WindowUpperBound(probeNumber_toShow));
% window edit
set(handles.edit_windowlowerbound, 'String', num2str(probeProperties.WindowLowerBound(probeNumber_toShow)));
set(handles.edit_windowupperbound, 'String', num2str(probeProperties.WindowUpperBound(probeNumber_toShow)));
% draw window on amode
display_signalwindow_amode( handles.axes_amode, ...
                            probeProperties.WindowLowerBound(probeNumber_toShow), ...
                            probeProperties.WindowUpperBound(probeNumber_toShow), ...
                            'plot_amode_windowlowerbound', ...
                            'plot_amode_windowupperbound');
% draw window on bmode
display_signalwindow_mmode( handles.axes_mmode, ...
                            probeProperties.WindowLowerBound(probeNumber_toShow), ...
                            probeProperties.WindowUpperBound(probeNumber_toShow), ...
                            'plot_mmode_windowlowerbound', ...
                            'plot_mmode_windowupperbound');
% set the window properties table
set(handles.uitable_properties, 'Data', [probeProperties.WindowLowerBound, probeProperties.WindowUpperBound]);


% enable all gui element, now the user can do whatever he/she wants
gui_toggleElement(handles, 'on');
% but not the pause button, i need to prevent the user to not pressing
% pause before they press start button
set(handles.button_pause, 'Enable', 'off');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% store new probeProperties to global variable
handles.probeProperties = probeProperties;
handles.probeConfigStruct = probeConfigStruct;

% update handles structure
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
set( handles.slider_windowlowerbound, 'Value', ...
     probeProperties.WindowLowerBound(probeNumber_toShow));
set( handles.slider_windowupperbound, 'Value', ...
     probeProperties.WindowUpperBound(probeNumber_toShow));
% set the edittext window according the the current properties of selected probe
set( handles.edit_windowlowerbound, 'String', ...
     num2str(probeProperties.WindowLowerBound(probeNumber_toShow)));
set( handles.edit_windowupperbound, 'String', ...
     num2str(probeProperties.WindowUpperBound(probeNumber_toShow)));

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
                            probeProperties.WindowLowerBound(probeNumber_toShow), ...
                            probeProperties.WindowUpperBound(probeNumber_toShow), ...
                            'plot_amode_windowlowerbound', ...
                            'plot_amode_windowupperbound');

% show m-mode
display_mmode(handles.axes_mmode, probeNumber_toShow, envelope_data, data_spec, x_axis_values)


% draw m-mode window
display_signalwindow_mmode( handles.axes_mmode, ...
                            probeProperties.WindowLowerBound(probeNumber_toShow), ...
                            probeProperties.WindowUpperBound(probeNumber_toShow), ...
                            'plot_mmode_windowlowerbound', ...
                            'plot_mmode_windowupperbound');
                        
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
function slider_windowlowerbound_Callback(hObject, eventdata, handles)
% hObject    handle to slider_windowlowerbound (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

% get necessary variable from global
probeNumber_toShow = handles.probeNumber_toShow;
probeProperties    = handles.probeProperties;

% get necessary value from gui
probeProperties.WindowLowerBound(probeNumber_toShow) = get(handles.slider_windowlowerbound, 'Value');
probeProperties.WindowUpperBound(probeNumber_toShow) = get(handles.slider_windowupperbound, 'Value');

% set the edittext
set(handles.edit_windowlowerbound, 'String', probeProperties.WindowLowerBound(probeNumber_toShow));

% draw window
display_signalwindow_amode( handles.axes_amode, ...
                            probeProperties.WindowLowerBound(probeNumber_toShow), ...
                            probeProperties.WindowUpperBound(probeNumber_toShow), ...
                            'plot_amode_windowlowerbound', ...
                            'plot_amode_windowupperbound');
display_signalwindow_mmode( handles.axes_mmode, ...
                            probeProperties.WindowLowerBound(probeNumber_toShow), ...
                            probeProperties.WindowUpperBound(probeNumber_toShow), ...
                            'plot_mmode_windowlowerbound', ...
                            'plot_mmode_windowupperbound');
                        
% update gui table
gui_updateRowTable( handles.uitable_properties, ...
                    probeNumber_toShow, ...
                    [ probeProperties.WindowLowerBound(probeNumber_toShow), ...
                      probeProperties.WindowUpperBound(probeNumber_toShow) ] );

% store the necessary value to global variable
handles.probeProperties = probeProperties;

% Update handles structure
guidata(hObject, handles);




% --- Executes during object creation, after setting all properties.
function slider_windowlowerbound_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_windowlowerbound (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function slider_windowupperbound_Callback(hObject, eventdata, handles)
% hObject    handle to slider_windowupperbound (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

% get necessary variable from global
probeNumber_toShow = handles.probeNumber_toShow;
probeProperties = handles.probeProperties;

% get necessary value from gui
probeProperties.WindowLowerBound(probeNumber_toShow) = get(handles.slider_windowlowerbound, 'Value');
probeProperties.WindowUpperBound(probeNumber_toShow)    = get(handles.slider_windowupperbound, 'Value');

% set the edit text
set(handles.edit_windowupperbound, 'String', probeProperties.WindowUpperBound(probeNumber_toShow));

% draw window
display_signalwindow_amode( handles.axes_amode, ...
                            probeProperties.WindowLowerBound(probeNumber_toShow), ...
                            probeProperties.WindowUpperBound(probeNumber_toShow), ...
                            'plot_amode_windowlowerbound', ...
                            'plot_amode_windowupperbound');
display_signalwindow_mmode( handles.axes_mmode, ...
                            probeProperties.WindowLowerBound(probeNumber_toShow), ...
                            probeProperties.WindowUpperBound(probeNumber_toShow), ...
                            'plot_mmode_windowlowerbound', ...
                            'plot_mmode_windowupperbound');
                        
% update gui table
gui_updateRowTable( handles.uitable_properties, ...
                    probeNumber_toShow, ...
                    [ probeProperties.WindowLowerBound(probeNumber_toShow), ...
                      probeProperties.WindowUpperBound(probeNumber_toShow) ] );

% store the necessary value to global variable
handles.probeProperties = probeProperties;

% Update handles structure
guidata(hObject, handles);




% --- Executes during object creation, after setting all properties.
function slider_windowupperbound_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_windowupperbound (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function edit_windowlowerbound_Callback(hObject, eventdata, handles)
% hObject    handle to edit_windowlowerbound (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_windowlowerbound as text
%        str2double(get(hObject,'String')) returns contents of edit_windowlowerbound as a double


% --- Executes during object creation, after setting all properties.
function edit_windowlowerbound_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_windowlowerbound (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_windowupperbound_Callback(hObject, eventdata, handles)
% hObject    handle to edit_windowupperbound (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_windowupperbound as text
%        str2double(get(hObject,'String')) returns contents of edit_windowupperbound as a double


% --- Executes during object creation, after setting all properties.
function edit_windowupperbound_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_windowupperbound (see GCBO)
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
                            handles.probeProperties.WindowLowerBound(handles.probeNumber_toShow), ...
                            handles.probeProperties.WindowUpperBound(handles.probeNumber_toShow), ...
                            'plot_amode_windowlowerbound', ...
                            'plot_amode_windowupperbound');
 
% change the timestamp line in m-mode axes
display_signalwindow_mmode( handles.axes_mmode, ...
                            handles.probeProperties.WindowLowerBound(handles.probeNumber_toShow), ...
                            handles.probeProperties.WindowUpperBound(handles.probeNumber_toShow), ...
                            'plot_mmode_windowlowerbound', ...
                            'plot_mmode_windowupperbound');
 
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

% get necessary variable from global variable
probeProperties   = handles.probeProperties;
probeConfigStruct = handles.probeConfigStruct;
data_spec         = handles.data_spec;

% get the field names
probeConfig_fieldnames = fieldnames(probeConfigStruct);
% loop through all the fields
for i=1:data_spec.n_ust
    
    % .ini file from ultrasound machine stores 6 point floating point
    % and (somehow) saved it in string format with comma instead of point,
    % for consistency, we also save the .ini file like that
    lowerbound_str = strrep(sprintf('%.6f', probeProperties.WindowLowerBound(i)), '.', ',');
    upperbound_str = strrep(sprintf('%.6f', probeProperties.WindowUpperBound(i)), '.', ',');
    
    % store it to our struct
    probeConfigStruct.(probeConfig_fieldnames{i}).LowerBound = lowerbound_str;
    probeConfigStruct.(probeConfig_fieldnames{i}).UpperBound = upperbound_str;
end

% this code requires struct2ini function which can be found here:
% https://nl.mathworks.com/matlabcentral/fileexchange/22079-struct2ini
[fname, path] = uiputfile('*.ini', pwd);
struct2ini( strcat(path, fname), probeConfigStruct );



% uisave('probeProperties')



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
% probeProperties.WindowRange = [1 1].*probeProperties.WindowLowerBound + [-1 1].*0.5.*probeProperties.WindowUpperBound;
probeProperties.WindowRange = [probeProperties.WindowLowerBound probeProperties.WindowUpperBound];
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
