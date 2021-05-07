
# Finds if elements of a vector are close to another element with value `val`, 
# change its value to it if so.
# This function is used in this project to flag time-steps around a given event,
# for example to flag time-steps around an opening of the chamber door.
is_val_around = function(x,val,points_after,points_before){
  ones = which(x == val)
  new_ones = 
    lapply(ones, function(y){
      (y-points_before):(y+points_after)
    })%>%unlist()%>%unique()
  new_ones = new_ones[new_ones >= 1 & new_ones <= length(x)]
  x[new_ones] = val
  x
}