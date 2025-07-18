function idx_kept = filterMinDist(p_loss_vals, MINDIST)
    % Sort values and keep original indices
    [vals_sorted, sort_idx] = sort(p_loss_vals(:));
    
    idx_kept_sorted = [];
    last_val = -inf;
    
    for i = 1:length(vals_sorted)
        if vals_sorted(i) - last_val >= MINDIST
            idx_kept_sorted(end+1) = i;   %#ok<AGROW>
            last_val = vals_sorted(i);
        end
    end
    
    % Map back to original indices
    idx_kept = sort_idx(idx_kept_sorted);
end