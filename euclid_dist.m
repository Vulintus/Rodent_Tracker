function d = euclid_dist(p1,p2)
d = sqrt(sum((p1-p2).^2,2));      