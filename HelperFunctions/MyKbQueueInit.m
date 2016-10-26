function id = MyKbQueueInit
%
% Output "id" = [deviceNumber] which used for KbQueueCreate
%
KbName('UnifyKeyNames');
%
[id, name] = GetKeyboardIndices;

keys = [4:44, 51:56, 79:82, 13, 110, 96, 27];
keylist = zeros(1, 256); keylist(keys) = 1;

%
KbQueueCreate(id(1), keylist);
%
KbQueueStart();
KbQueueFlush();

end