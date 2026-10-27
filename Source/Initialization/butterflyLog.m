function butterflyLog(varargin)

globals;

message = sprintf(varargin{:});
fileId = fopen(logFile, 'a'); fprintf(fileId, '%s\n', message); fclose(fileId);
fprintf('%s\n', message);
end
