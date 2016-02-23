function print_structure(S)

    print_structure_recursive(S, '.');

end

function print_structure_recursive(S, prefix)
	fields = sort(fieldnames(S));
	for f = 1:length(fields)
        if isstruct(S.(fields{f}))
            print_structure_recursive(S.(fields{f}), sprintf('%s.%s', prefix, fields{f}));
        else
            fprintf('%s.%s = %s\n', prefix, fields{f}, num2str(S.(fields{f})));
        end
	end
end