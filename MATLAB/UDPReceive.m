classdef UDPReceive< matlab.System
    % UDPReceive = instrument.system.UDPReceive creates a UDP Receive system object. 

    % Copyright 2021-2024 The MathWorks, Inc.

    % Public, non-tunable properties
    properties(Nontunable)
        % Local address
        LocalAddress = ''
        % Local port
        LocalPort = 8888
        % Remote address
        Host = 'localhost'
        % Remote Port
        Port = 9090
        % Data size
        DataSize = [1 1]
        % Source Data type
        DataType = 'uint8'
        % ASCII format string
        ASCIIFormatting = '%f,'
        % Terminator
        Terminator = 'LF'
        % Custom Terminator
        CustomTerminator = 10
        % Byte order
        ByteOrder = 'big-endian'
        % Timeout
        Timeout = 10
        % Block sample time:
        SampleTime = 0.01
    end

    % Public, non-tunable, Logical properties
    properties(Nontunable, Logical)
        % Enable local port sharing
        EnablePortSharing = false
        % Output latest data
        GetLatestData = false
        % Enable blocking mode
        EnableBlockingMode = true
    end

    properties (Access = private)
        UDPReceiveObj
        SaveOutput
    end
    %#codegen

    % Construct pop-up for ByteOrder parameter
    properties (Constant, Hidden)
        ByteOrderSet = matlab.system.StringSet({'big-endian', 'little-endian'})
        DataTypeSet = matlab.system.StringSet({'single', 'double', 'int8', 'uint8', 'int16', 'uint16', ...
            'int32', 'uint32', 'int64', 'uint64', 'ASCII'})
        TerminatorSet = matlab.system.StringSet(cellstr(["CR", "LF", "CR/LF", "LF/CR", "Custom terminator"]))
    end

    methods
        %% Constructor
        function obj = UDPReceive(varargin)
            % Support name-value pair arguments when constructing object
            setProperties(obj, nargin, varargin{:})
        end

        %% Set functions to validate and set the property value.
        function set.Port(obj, value)
            if iscell(value) || isempty(value) || any(value < 1) ...
                    || any(floor(value) ~= value) || ~isscalar(value) || any(value > 65535)
                coder.internal.error('instrument:instrumentblks:udpInvalidRemotePort');
            end
            obj.Port = value;
        end

        function set.LocalPort(obj, value)
            if iscell(value) || isempty(value)
                coder.internal.error('instrument:instrumentblks:udpInvalidLocalPort');
            end
            if value < 0 && value ~= -1
                coder.internal.error('instrument:instrumentblks:udpInvalidLocalPort');
            elseif value == 0 || (floor(value) ~= value) || ~isscalar(value) || value > 65535
                coder.internal.error('instrument:instrumentblks:udpInvalidLocalPort');
            end
            obj.LocalPort = value;
        end

        function set.DataSize(obj, value)
            validateattributes(value, {'numeric'}, ...
                { '>', 0, 'real', 'nonnan', 'integer', 'row'}, ...
                '', 'Data size')
            obj.DataSize = value;
        end

        function set.CustomTerminator(obj, value)
            validateattributes(value, {'numeric'}, ...
                { '>=', 0, '<=', 127, 'real', 'nonnan', 'nonempty' 'integer', 'row'}, ...
                '', 'Terminator')
            obj.CustomTerminator = value;
        end

        function set.ASCIIFormatting(obj, value)
            % If data type is ASCII, check if valid ASCII format specifier
            % is provided
            if coder.target('MATLAB')
                if strcmpi(obj.DataType, 'ASCII') %#ok<MCSUP>
                    if isempty(value) || ~contains(value, '%')
                        coder.internal.error('instrument:instrumentblks:invalidASCIIFormatString');
                    else
                        tempValue = value;
                        validASCIIFormat = {'%d', '%i', '%ld', '%li', '%u', '%o', '%x', '%lu', '%lo', '%lx', '%f', '%e', '%g'};

                        % Iterate over all the valid numeric conversion specifiers to replace user
                        % input with an empty string.
                        for counter = 1:numel(validASCIIFormat)
                            tempValue = strrep(tempValue, validASCIIFormat{counter}, '');
                        end

                        % Check if user input contains any more '%' character. This represents that
                        % user inputs a conversion specifier other than a valid numeric conversion
                        % specifier. For e.g. %s. Also check if input contains invalid specifiers such as '%dd', '%abc' etc
                        if contains(tempValue, '%') || (any(uint8(tempValue) >= uint8('A')) && any(uint8(tempValue)<=uint8('Z'))) ...
                                || (any(uint8(tempValue)>=uint8('a')) && any(uint8(tempValue)<=uint8('z')))
                            coder.internal.error('instrument:instrumentblks:invalidASCIIFormatString');
                        end
                    end
                end
            else
                if ~any(strcmpi(value, {'%d', '%i', '%ld', '%li', '%u', '%o', '%x', '%lu', '%lo', '%lx', '%f', '%e', '%g'}))
                    coder.internal.error('instrument:instrumentblks:invalidASCIIFormatStringForCodegen');
                end
            end
            obj.ASCIIFormatting = value;
        end

        function set.Timeout(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'real', 'nonempty', 'nonnan', 'positive', 'scalar'}, ...
                '', 'Timeout');
            obj.Timeout = value;
        end

        function set.SampleTime(obj, value)
            if iscell(value)
                coder.internal.error('instrument:instrumentblks:invalidReceiveSampleTime');
            end
            if isscalar(value)
                if value < 0 && value ~= -1
                    coder.internal.error('instrument:instrumentblks:invalidReceiveSampleTime');
                elseif value == 0 || isempty(value) || ~isnumeric(value) || any(isnan(value)) || any(isinf(value))
                    coder.internal.error('instrument:instrumentblks:invalidReceiveSampleTime');
                end
            else % Handle cases when user provides initial time offset along with sample time.
                if any((value < 0), 'all') || ~isequal(size(value), [1 2]) || ~isnumeric(value) || any(isnan(value)) || any(isinf(value)) || value(1) == 0
                    coder.internal.error('instrument:instrumentblks:invalidReceiveSampleTime');
                end
            end
            obj.SampleTime = value;
        end
    end

    methods(Static, Access = protected)
        function header = getHeaderImpl
            % Define header panel for System block dialog
            header = matlab.system.display.Header(mfilename("class"), ...
                'Title', 'UDP Receive', ...
                'Text', 'Receive data over UDP network from a specified remote machine.', ...
                'ShowSourceLink', false );
        end

        function group = getPropertyGroupsImpl
            % Define parameter name and grouping rules
            LocalAddressProp = matlab.system.display.internal.Property('LocalAddress', 'Description', 'Local address' );
            LocalPortProp = matlab.system.display.internal.Property('LocalPort', 'Description', 'Local port' );
            PortSharingProp = matlab.system.display.internal.Property('EnablePortSharing', 'Description', 'Enable local port sharing' );
            HostProp = matlab.system.display.internal.Property('Host', 'Description', 'Remote address' );
            PortProp = matlab.system.display.internal.Property('Port', 'Description', 'Remote port' );
            GetLatestDataProp = matlab.system.display.internal.Property('GetLatestData', 'Description', 'Output latest data' );
            DataSizeProp = matlab.system.display.internal.Property('DataSize', 'Description', 'Data size' );
            DataTypeProp = matlab.system.display.internal.Property('DataType', 'Description', 'Source Data type' );
            ASCIIFormattingProp = matlab.system.display.internal.Property('ASCIIFormatting', 'Description', '       ASCII format string' );
            TerminatorProp = matlab.system.display.internal.Property('Terminator', 'Description', '       Terminator');
            CustomTerminatorProp = matlab.system.display.internal.Property('CustomTerminator', 'Description', '','Row', matlab.system.display.internal.Row.current);
            ByteOrderProp = matlab.system.display.internal.Property('ByteOrder', 'Description', '       Byte order' );
            BlockingModeProp = matlab.system.display.internal.Property('EnableBlockingMode', 'Description', 'Enable blocking mode' );
            TimeoutProp = matlab.system.display.internal.Property('Timeout', 'Description', '       Timeout');
            SampleTimeProp = matlab.system.display.internal.Property('SampleTime', 'Description', 'Block sample time');

            % Define the order in which property should be displayed on dialog
            group = matlab.system.display.Section(mfilename("class"), 'PropertyList', {LocalAddressProp, LocalPortProp, PortSharingProp, HostProp, PortProp, ...
                GetLatestDataProp, DataSizeProp, DataTypeProp, ASCIIFormattingProp, TerminatorProp, CustomTerminatorProp, ByteOrderProp, BlockingModeProp, ...
                TimeoutProp, SampleTimeProp});

            % Create 'Verify address and port connectivity' button.
            group.Actions = matlab.system.display.Action(@(~, obj) ...
                validateAddressAndPort(obj), 'Label', 'Verify address and port connectivity', ...
                'Placement', 'GetLatestData', ...
                'Alignment', 'right');
        end

        function flag = showSimulateUsingImpl
            flag = false;
        end
    end

    methods(Access = protected)
        function num = getNumOutputsImpl(obj)
            % Define total number of outputs for system
            num = 1;
            if ~obj.EnableBlockingMode
                num = 2;
            end
        end

        function icon = getIconImpl(obj)
            % Show only block name if block is in the library, else show
            % Local address and Port details as well.
            if bdIsLibrary(bdroot(gcb))
                icon = 'UDP\nReceive';
            else
                if isempty(obj.LocalAddress)
                    addressVal = 'Address: (none)';
                else
                    addressVal= obj.LocalAddress;
                end
                portVal = num2str(obj.LocalPort);
                icon = [addressVal '\n' 'Port: ' portVal];
            end
        end

        function [name, varargout] = getOutputNamesImpl(obj)
            % Return output port names for System block
            name = 'Data';
            if ~obj.EnableBlockingMode
                varargout{1} = 'Status';
            end
        end

        function [out, varargout] = getOutputSizeImpl(obj)
            % Return output size for Data port
            if isscalar(obj.DataSize)
                out = [obj.DataSize 1];
            else
                out = obj.DataSize;
            end

            % Return output size for Status port
            if ~obj.EnableBlockingMode
                varargout{1} = [1 1];
            end
        end

        function [out, varargout] = getOutputDataTypeImpl(obj)
            % Return data type for each output port
            if strcmpi(obj.DataType, 'ASCII')
                out = 'double';
            else
                out = obj.DataType;
            end
            if ~obj.EnableBlockingMode
                varargout{1} = 'logical';
            end
        end

        function [out,varargout] = isOutputComplexImpl(obj)
            % Return true for each output port with complex data
            out = false;
            if ~obj.EnableBlockingMode
                varargout{1} = false;
            end
        end

        function  [out,varargout] = isOutputFixedSizeImpl(obj)
            % Return true for each output port with fixed size
            out = true;
            if ~obj.EnableBlockingMode
                varargout{1} = true;
            end
        end

        function sts = getSampleTimeImpl(obj)
            if isequal(obj.SampleTime, -1)
                sts = obj.createSampleTime("Type", "Inherited");
            elseif isscalar(obj.SampleTime)
                sts = obj.createSampleTime("Type", "Discrete", ...
                    "SampleTime", obj.SampleTime);
            else
                % Handle sample time if user provided initial time offset along with
                % sample time.
                sts = obj.createSampleTime("Type", "Discrete", ...
                    "SampleTime", obj.SampleTime(1), 'OffsetTime', obj.SampleTime(2));
            end
        end

        function flag = isInactivePropertyImpl(obj, prop)
            % Set flag based on if property need to be visible or not on
            % the dialog
            switch prop
                case 'ASCIIFormatting'
                    flag = ~strcmpi(obj.DataType, 'ASCII');
                case 'Terminator'
                    flag = ~strcmpi(obj.DataType, 'ASCII');
                case 'CustomTerminator'
                    flag = ~(strcmpi(obj.DataType, 'ASCII') && strcmpi(obj.Terminator, 'Custom terminator'));
                case 'ByteOrder'
                    flag = ~ismember(obj.DataType, {'single', 'double', ...
                        'int16', 'uint16', 'int32', 'uint32', 'int64', 'uint64'});
                case 'Timeout'
                    flag = ~obj.EnableBlockingMode;
                case 'GetLatestData'
                    flag  =strcmpi(obj.DataType, 'ASCII');
                otherwise
                    flag  = false;
            end
        end

        function num = getNumInputsImpl(~)
            num = 0;
        end

        function setupImpl(obj)
            % Create UDPByte object and connect.
            obj.UDPReceiveObj = matlabshared.network.internal.UDPByte( ...
                'RemoteHost', obj.Host, ...
                'RemotePort', obj.Port, ...
                'LocalHost', obj.LocalAddress, ...
                'EnableSocketSharing', true, ...
                'EnablePortSharing', obj.EnablePortSharing, ...
                'ByteOrder', obj.ByteOrder, ...
                'Timeout', obj.Timeout, ...
                'IsWriteOnly', false);

            % Check if LocalPort setting is set to any value other than -1
            if obj.LocalPort ~= -1
                obj.UDPReceiveObj.LocalPort = obj.LocalPort;
            end

            if isscalar(obj.DataSize)
                outDataSize = [obj.DataSize 1];
            else
                outDataSize = obj.DataSize;
            end
            
            % Construct default value of SaveOutput property with DataSize
            % and DataType.
            if strcmpi(obj.DataType, 'ASCII')
                dType = 'double';
            else
                dType = obj.DataType;
            end

            obj.SaveOutput = zeros(outDataSize, dType);
           
            % Set address type.
            if contains(obj.LocalAddress, ':') || contains(obj.Host, ':')
                obj.UDPReceiveObj.AddressType = 'IPV6';
            end
            
            % If running in MATLAB, we can use try-catch.
            % Otherwise, try to connect without try-catch in codegen mode.
            if coder.target('MATLAB')
                try
                    connect(obj.UDPReceiveObj);
                catch err
                    if (strcmp(err.identifier, "network:udp:connectFailed") && ...
                            contains(err.message, "Only UDP object with initAccess (first instance) can control underlying socking options (Multicast/Broadcast/PortSharing)"))
                        % If the connect fails because of conflicting 'Enable
                        % Socket Sharing' settings on the UDP blocks sharing a
                        % local address and local port, throw an error for the conflict.
                        coder.internal.error('instrument:instrumentblks:conflictPortSharingSettings');
                    end
                    % Otherwise, throw the general 'connectFailed' error.
                    rethrow(err)
                end
            else
                connect(obj.UDPReceiveObj);
            end
        end

        function [output, varargout]  = stepImpl(obj)
            % Set status port value to false by default
            if ~obj.EnableBlockingMode
                varargout{1} = false;
            end

            % Handle DataSize if DataSize is scalar.
            if isscalar(obj.DataSize)
                dataSizeVal = [obj.DataSize 1];
            else
                dataSizeVal = obj.DataSize;
            end

            % Get the number of bytes corresponding to each data type.
            switch obj.DataType
                case {'int8', 'uint8'}
                    typeSize = 1;
                case {'int16', 'uint16'}
                    typeSize = 2;
                case {'int32', 'uint32', 'single'}
                    typeSize = 4;
                case {'int64', 'uint64', 'double'}
                    typeSize = 8;
                otherwise
                    typeSize = 1;
            end

            % Get the ASCII equivalent values of Terminator.
            if strcmpi(obj.DataType, 'ASCII')
                switch obj.Terminator
                    case "CR"
                        termVal = 13;
                    case "LF"
                        termVal = 10;
                    case "CR/LF"
                        termVal = [13 10];
                    case "LF/CR"
                        termVal = [10 13];
                    case "Custom terminator"
                        termVal = obj.CustomTerminator;
                end

                % Call readUntil function by setting the WAIT flag to 'true' or 'false' based on
                % blocking or non-blocking mode.
                if obj.EnableBlockingMode
                    outValPlus = obj.UDPReceiveObj.readUntil(uint8(termVal), true);
                else
                    % In non-blocking mode, check if terminator is present,
                    % then do a read.
                    if obj.UDPReceiveObj.peekUntil(uint8(termVal))
                        outValPlus = obj.UDPReceiveObj.readUntil(uint8(termVal), false);
                    else
                        % Output zeros if no terminator found.
                        output = zeros(dataSizeVal, 'double');
                        return;
                    end
                end

                % If terminator is found, remove the terminator from the
                % read data.
                sizeTermVal = numel (termVal);
                outValPlusSize = numel (outValPlus);
                outVal = outValPlus(1:(outValPlusSize- sizeTermVal));

                formattedVal = formatString(obj, outVal);

                % Error, if formatted data doesn't contain enough data as
                % per the data size provided by user
                if size(formattedVal) < prod(dataSizeVal)
                    coder.internal.error('instrument:instrumentblks:incorrectASCIIRead');
                else
                    % If more data present, extract what is required.
                    % Ignore the remaining data.
                    outputVal = formattedVal(1:prod(dataSizeVal));
                    data = reshape(outputVal, dataSizeVal);
                    output = double(data);

                    % Set status flag to true if new data found.
                    if ~obj.EnableBlockingMode
                        varargout{1} = true;
                    end
                end
            else
                % For numeric data.
                if obj.EnableBlockingMode
                    if obj.GetLatestData
                        % Calculate the amount of data to read in order to be able to read latest data.
                        tempDataToRead = obj.UDPReceiveObj.NumBytesAvailable - typeSize*prod(dataSizeVal);
                        % Read the buffered data and discard it so that we
                        % get the latest data with next read()
                        if tempDataToRead > 0
                            tempData = obj.UDPReceiveObj.read(tempDataToRead); %#ok<NASGU>
                        end
                    end
                    outputVal = obj.UDPReceiveObj.read(prod(dataSizeVal), obj.DataType);
                else
                    % Check if enough data is available in non-blocking
                    % mode.
                    if obj.UDPReceiveObj.NumBytesAvailable <  typeSize*prod(dataSizeVal)
                        % Output last received value if no enough data found.
                        outputVal = obj.SaveOutput;
                    else
                        if obj.GetLatestData
                            % Calculate the amount of data to read in order to be able to read latest data.
                            tempDataToRead = obj.UDPReceiveObj.NumBytesAvailable - typeSize*prod(dataSizeVal);
                            % Read the buffered data and discard it so that we
                            % get the latest data with next read()
                            if tempDataToRead > 0
                                tempData = obj.UDPReceiveObj.read(tempDataToRead); %#ok<NASGU>
                            end
                        end
                        outputVal = obj.UDPReceiveObj.read(prod(dataSizeVal), obj.DataType);
                        obj.SaveOutput = outputVal;
                        % Set the status flag
                        varargout{1} = true;
                    end
                end
                output = reshape(outputVal, dataSizeVal);
            end
        end

        function releaseImpl(obj)
            obj.UDPReceiveObj.disconnect;
        end
    end

    methods
        function formattedVal = formatString(obj, outVal)
            % This is a workaround function to support ASCII workflow in
            % codegen mode. In ASCII workflow, the sscanf function used is not codegenable.
            % Geck g943740 is available to create codegen support for
            % sscanf. Once this support is available the below function can
            % be removed and sscanf can be directly used in both
            % interpreted and codegen workflows.

            % Format the data based on ASCII format specifier provided by user.
            if coder.target('MATLAB')
                formattedVal = sscanf(char(outVal), obj.ASCIIFormatting);
            else
                % If string is not terminated with NULL, append '0' at the
                % end. Otherwise sscanf may read beyond the data memory
                % location.
                if (outVal(end) ~= 0)
                    outVal = [outVal uint8(0)];
                end

                % Converts the read data into a character array.
                inputStr = char(outVal);

                formatString = obj.ASCIIFormatting;
                headerFile = coder.internal.getCHeaderName('stdio');
                coder.cinclude(headerFile);
                idx = uint32(0);
                idxAccumulate = idx;
                success = int32(0);

                % Initialize output based on ASCII format specifier type.
                switch obj.ASCIIFormatting
                    case {'%d','%i','%o','%x'}
                        result = zeros([1 prod(obj.DataSize)], 'int32');
                    case '%u'
                        result = zeros([1 prod(obj.DataSize)], 'uint32');
                    case {'%f','%e','%g'}
                        result = zeros([1 prod(obj.DataSize)], 'single');
                    case {'%ld','%li','%lu','%lo','%lx'}
                        result = zeros([1 prod(obj.DataSize)], 'int64');
                    otherwise
                        coder.internal.error('instrument:instrumentblks:invalidASCIIFormatStringForCodegen');
                end

                % Call the sscanf C function.
                for count=1:numel(result)
                    idxAccumulate = idxAccumulate +idx;
                    libMethodName = coder.internal.getCLibName('sscanf');
                    success = coder.ceval(libMethodName, inputStr(idxAccumulate+1:end), [formatString '%n'], coder.ref(result(count)), coder.ref(idx));
                    if success ~= 1
                        coder.internal.error('instrument:instrumentblks:incorrectSscanfOutput');
                    end
                end

                formattedVal = result;
            end
        end

        function validateAddressAndPort(obj)
            % Function to validate Remote and Local address and Port when
            % 'Verify address and port connectivity' button is pressed.

            % Check if the host specified is empty/invalid.
            [remoteName, remoteAddress] = resolvehost(obj.Host);

            if isempty(remoteName) && isempty(remoteAddress)
                coder.internal.error('instrument:instrumentblks:hostinvalid')
            end

            % Check if the local address specified is empty/invalid.
            [localName, localAddress] = resolvehost(obj.LocalAddress);
            if isempty(localName) && isempty(localAddress)
                coder.internal.error('instrument:instrumentblks:localhostinvalid')
            end

            % Try creating the UDPByte object with the settings given by user
            if obj.LocalPort == -1
                myObj = matlabshared.network.internal.UDPByte("LocalHost", obj.LocalAddress);
            else
                myObj = matlabshared.network.internal.UDPByte("LocalHost", obj.LocalAddress, "LocalPort", obj.LocalPort);
            end

            % If creation of UDPByte object is success, delete the object and
            % display success message
            delete(myObj);
            clear myObj;

            if ~strcmpi(obj.Host, remoteAddress) % Append the IP the address resolves to.
                remoteAddMsg = getString(message('instrument:instrumentblks:remoteHostAndPortCorrectWithIP',...
                    obj.Host, remoteAddress, obj.Port));
            else
                remoteAddMsg = getString(message('instrument:instrumentblks:remoteHostAndPortCorrect',...
                    obj.Host, obj.Port));
            end

            if ~strcmpi(obj.LocalAddress, localAddress) % Append the IP the address resolves to.
                localAddMsg = getString(message('instrument:instrumentblks:localHostAndPortCorrectWithIP', ...
                    obj.LocalAddress, localAddress, obj.LocalPort));
            else
                localAddMsg = getString(message('instrument:instrumentblks:localHostAndPortCorrect', obj.LocalAddress, obj.LocalPort));
            end

            completeUserMsg = [remoteAddMsg newline localAddMsg];
            msgbox(completeUserMsg, 'Success', 'replace');
        end
    end
end

