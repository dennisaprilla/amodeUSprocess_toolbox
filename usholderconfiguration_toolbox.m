function varargout = usholderconfiguration_toolbox(varargin)
% USHOLDERCONFIGURATION_TOOLBOX MATLAB code for usholderconfiguration_toolbox.fig
%      USHOLDERCONFIGURATION_TOOLBOX, by itself, creates a new USHOLDERCONFIGURATION_TOOLBOX or raises the existing
%      singleton*.
%
%      H = USHOLDERCONFIGURATION_TOOLBOX returns the handle to a new USHOLDERCONFIGURATION_TOOLBOX or the handle to
%      the existing singleton*.
%
%      USHOLDERCONFIGURATION_TOOLBOX('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in USHOLDERCONFIGURATION_TOOLBOX.M with the given input arguments.
%
%      USHOLDERCONFIGURATION_TOOLBOX('Property','Value',...) creates a new USHOLDERCONFIGURATION_TOOLBOX or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before usholderconfiguration_toolbox_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to usholderconfiguration_toolbox_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help usholderconfiguration_toolbox

% Last Modified by GUIDE v2.5 19-Oct-2021 18:41:30

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @usholderconfiguration_toolbox_OpeningFcn, ...
                   'gui_OutputFcn',  @usholderconfiguration_toolbox_OutputFcn, ...
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


% --- Executes just before usholderconfiguration_toolbox is made visible.
function usholderconfiguration_toolbox_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to usholderconfiguration_toolbox (see VARARGIN)

% n_ust = 30;
% test = [];
% for i=1:n_ust
%     test = [test; {i,0,'',5,3,0,0,0,0,0,0,0,0,0}];
% end
% set(handles.table_ustconfig, 'Data', test);

% Choose default command line output for usholderconfiguration_toolbox
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes usholderconfiguration_toolbox wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = usholderconfiguration_toolbox_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function edit_nominaltransformation_Callback(hObject, eventdata, handles)
% hObject    handle to edit_nominaltransformation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_nominaltransformation as text
%        str2double(get(hObject,'String')) returns contents of edit_nominaltransformation as a double


% --- Executes during object creation, after setting all properties.
function edit_nominaltransformation_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_nominaltransformation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in button_loadnominaltransformation.
function button_loadnominaltransformation_Callback(hObject, eventdata, handles)
% hObject    handle to button_loadnominaltransformation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in button_loadprobegroup.
function button_loadprobegroup_Callback(hObject, eventdata, handles)
% hObject    handle to button_loadprobegroup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% open browser to get the file
[file_ustgroup, path_ustgroup] = uigetfile('*.txt');

% open the file
fid = fopen(strcat(path_ustgroup, file_ustgroup));
% allocate memory for ust groups
ust_group = [{'Not Used (0)'}];
% index for group indicator
index = 1;
% read line until finished
while ~feof(fid)
    % get the line
    str = {strcat(fgetl(fid), sprintf(' (%d)', index))};
    ust_group = [ust_group, str];
    
    index = index+1;
end

% set the popupmenu_probegroup with the group specified by the text file
set(handles.popupmenu_probegroup, 'String', ust_group);

% enable all necessary elements
set(handles.popupmenu_probegroup, 'Enable', 'on');
set(handles.button_loadwindowsettings, 'Enable', 'on');
set(handles.edit_windowsettings, 'Enable', 'on');
set(handles.button_loadnominaltransformation, 'Enable', 'on');
set(handles.edit_nominaltransformation, 'Enable', 'on');
set(handles.edit_setuptransformationRx, 'Enable', 'on');
set(handles.edit_setuptransformationRy, 'Enable', 'on');
set(handles.edit_setuptransformationRz, 'Enable', 'on');
set(handles.button_savechange, 'Enable', 'on');
set(handles.button_export, 'Enable', 'on');

% store to global variable
handles.ust_group = ust_group;

% Update handles structure
guidata(hObject, handles);



function edit_windowsettings_Callback(hObject, eventdata, handles)
% hObject    handle to edit_windowsettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_windowsettings as text
%        str2double(get(hObject,'String')) returns contents of edit_windowsettings as a double


% --- Executes during object creation, after setting all properties.
function edit_windowsettings_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_windowsettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in button_loadwindowsettings.
function button_loadwindowsettings_Callback(hObject, eventdata, handles)
% hObject    handle to button_loadwindowsettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% open browser to get the file
[file_ustgroup, path_ustgroup] = uigetfile('*.mat');
load(strcat(path_ustgroup, file_ustgroup));

% get the data from the table
uitable = get(handles.table_ustconfig, 'Data');

% replace the data with the window setting from the loaded .mat file
uitable(:,3:4) = table2array(probeProperties);

% set again the table in the gui
set(handles.table_ustconfig, 'Data', uitable);
set(handles.edit_windowsettings, 'String', strcat(path_ustgroup, file_ustgroup));

% Update handles structure
guidata(hObject, handles);



function edit_setuptransformationRx_Callback(hObject, eventdata, handles)
% hObject    handle to edit_setuptransformationRx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_setuptransformationRx as text
%        str2double(get(hObject,'String')) returns contents of edit_setuptransformationRx as a double


% --- Executes during object creation, after setting all properties.
function edit_setuptransformationRx_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_setuptransformationRx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_setuptransformationRy_Callback(hObject, eventdata, handles)
% hObject    handle to edit_setuptransformationRy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_setuptransformationRy as text
%        str2double(get(hObject,'String')) returns contents of edit_setuptransformationRy as a double


% --- Executes during object creation, after setting all properties.
function edit_setuptransformationRy_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_setuptransformationRy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_setuptransformationRz_Callback(hObject, eventdata, handles)
% hObject    handle to edit_setuptransformationRz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_setuptransformationRz as text
%        str2double(get(hObject,'String')) returns contents of edit_setuptransformationRz as a double


% --- Executes during object creation, after setting all properties.
function edit_setuptransformationRz_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_setuptransformationRz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in button_savechange.
function button_savechange_Callback(hObject, eventdata, handles)
% hObject    handle to button_savechange (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

probe_group = get(handles.popupmenu_probegroup, 'Value') -1; % index 1 is for idle probe (0)
setup_Rx = str2double(get(handles.edit_setuptransformationRx, 'String'));
setup_Ry = str2double(get(handles.edit_setuptransformationRy, 'String'));
setup_Rz = str2double(get(handles.edit_setuptransformationRz, 'String'));

% get probe number
probe_number = get(handles.popupmenu_probenumber, 'Value');
% get the table data and change it based on the element we obtained
uitable_data = get(handles.table_ustconfig, 'Data');
uitable_data(probe_number, 2) = probe_group;
uitable_data(probe_number, 11:13) = [setup_Rx, setup_Ry, setup_Rz];

% set the table
set(handles.table_ustconfig, 'Data', uitable_data);



% --- Executes on selection change in popupmenu_probenumber.
function popupmenu_probenumber_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_probenumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_probenumber contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_probenumber

% get the probe number we are working on right now
probe_number = get(handles.popupmenu_probenumber, 'Value');

% get the table data and change it based on the element we obtained
uitable_data = get(handles.table_ustconfig, 'Data');
% get the row which corresponds to our probe_number
current_row = uitable_data(probe_number, :);

% set the popmenu probe group. because in table, there is group 0 (for
% probes which not being used) and there is no index 0 for popmenu, so we
% need to +1
set(handles.popupmenu_probegroup, 'Value', current_row(2)+1);
% set the edit text for setuptransformation
set(handles.edit_setuptransformationRx, 'String', num2str(current_row(11)));
set(handles.edit_setuptransformationRy, 'String', num2str(current_row(12)));
set(handles.edit_setuptransformationRz, 'String', num2str(current_row(13)));

% --- Executes during object creation, after setting all properties.
function popupmenu_probenumber_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_probenumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu_probegroup.
function popupmenu_probegroup_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_probegroup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_probegroup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_probegroup


% --- Executes during object creation, after setting all properties.
function popupmenu_probegroup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_probegroup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in button_export.
function button_export_Callback(hObject, eventdata, handles)
% hObject    handle to button_export (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get table data
ust_config = array2table(get(handles.table_ustconfig, 'Data'));
ust_config.Properties.VariableNames = get(handles.table_ustconfig, 'ColumnName');

% set the name and location of the file
[filename, filepath, index] = uiputfile({'*.csv'; '*.mat'});

% if the user save with .mat file use save command
if(index==2)
    save(strcat(filepath, filename), 'ust_config');
% else use writetable command
else
    writetable(ust_config, strcat(filepath, filename));
end
