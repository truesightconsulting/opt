opt_input_setup: 
	optimization_target: 1 is account, 2 to 4 are npv1 to npv5, 5 is lifetime
	optimization_type: 1 stands for budget type optimization, 2 stands for goal seek optimization, 3 is decreasing optimization, 4 is simulation, 5 is incremental budget optimization, 6 is cpa goal seek, 7 is hurdle rate goal seek, 8 is profit optimization, 9 is incremental goal optimization, 10 is multi-goal seek
	optimization_type_value: the value corresponds to the value of optimization_type; if optimization_type is 8 then leave this value as blank
	optimization_time: 1 is time-variant, 0 is time-invariant
	input_increment: hill-climbing pace. When search the optimal solution, how big the incremental spend for each iteration is.
	input_goal_check: positive numeric value; when optimizer does goal seek optimization, if the incremental value of optimized metric is less than this value, then optimization stop. It's used for the extreme goal which requires very large budget.
	
	There could be more other columns which need to be added in manually!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

