function C = addStruct(A, B)
% Sum between struct array A and array B
% Fields are merged and will be initialized with [] if not assigned.

    fnames = fieldnames(B);
    i_end = length(A);
    
    for j = 1:length(B)
        for i = 1:length(fnames)
            % Assign value on each field. If it doesn't exist, it automatically
            % create the new field for S.
            A(i_end+j).(fnames{i}) = B(j).(fnames{i});
        end
    end
    C = A;
end
