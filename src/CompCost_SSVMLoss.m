function [f] = CompCost_SSVMLoss(w, X_posi, X_nega, num_posi,y, num_nega, partFeat_dim, vnum_parts)
num_parts = 0; 
num_scale = length(partFeat_dim);
for k = 1: num_scale  
    num_parts = num_parts + vnum_parts(k); 
end

num_train = num_posi + num_nega;
vThresh = w(end - (num_parts) + 1: end);
w = w(1 : end-sum(num_parts));
%% for positive examples
[n_posi,p] = size(X_posi);
[n_nega,p] = size(X_nega);
n_total = n_posi + n_nega;

start = 0;
start_part = 0;
start_thresh = 0;
g_posi = zeros(n_posi, 1);
g_nega = zeros(n_nega, 1);

num_scale = length(partFeat_dim);
for l = 1 : num_scale
    dim_part = partFeat_dim(l);

    viol_parts_posi_curr = zeros(n_posi, vnum_parts(l));
    for k = 1 : vnum_parts(l)
        b = (X_posi(:, start + (k-1) * dim_part + 1 : start + k * dim_part)) * w(start + (k-1) * dim_part + 1 : start + k * dim_part) + vThresh(k + start_thresh);
        id = find(b <= 0);
        viol_parts_posi_curr(:, k) = (b > 0);
        b_posi = max(b, 0);
        g_posi = g_posi + b_posi;

        X_posi(id, start + (k-1) * dim_part + 1 : start + k * dim_part) = 0;          
    end

    viol_parts_nega_curr = zeros(n_nega, vnum_parts(l));
    for k = 1 : vnum_parts(l)
        b = (X_nega(:, start + (k-1) * dim_part + 1 : start + k * dim_part)) * w(start + (k-1) * dim_part + 1 : start + k * dim_part) + vThresh(k + start_thresh);
        id = find(b <= 0);
        viol_parts_nega_curr(:, k) = (b > 0);
        b_nega = max(b, 0);
        g_nega = g_nega + b_nega;
        X_nega(id, start + (k-1) * dim_part + 1 : start + k * dim_part) = 0;
    end	

    start = start + vnum_parts(l) * dim_part;
    start_thresh = start_thresh + vnum_parts(l);   

    viol_parts_posi{l} = viol_parts_posi_curr;
    viol_parts_nega{l} = viol_parts_nega_curr;
end  
g_posi = g_posi + X_posi(:, end) * w(end);
g_nega = g_nega + X_nega(:, end) * w(end);
g = [g_posi;g_nega];

err = 1-y.*g;
err_posi = err(1:n_posi);
err_nega = err(n_posi + 1 : end);

viol_posi = find(err_posi >= 0);
viol_nega = find(err_nega >= 0);
viol = find(err >= 0);

f_posi = sum(err_posi(viol_posi).^2);
f_nega = sum(err_nega(viol_nega).^2);
f = (f_posi + f_nega * num_nega / n_nega)/ num_train;