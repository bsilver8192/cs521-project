library(ggplot2)

# Sum all the tonnages between each pair of locations. Sort the locations first so both directions are
# counted as the same.
aggregated_data <- aggregate(x = data.frame(tons = rowSums(data.frame(data$tons_2012, data$tons_2013,
                                                                      data$tons_2014, data$tons_2015)),
                                            value = rowSums(data.frame(data$value_2012, data$value_2013,
                                                                       data$value_2014, data$value_2015)),
                                            distance = distances),
                             by = data.frame(t(apply(data.frame(data$dms_dest, data$dms_orig), 1, sort)),
                                             mode = data$dms_mode,
                                             commodity = data$sctg2),
                             FUN = mean)
aggregated_data <- aggregated_data[aggregated_data$distance > 0 & aggregated_data$commodity <= 43,]
by_commodity <- aggregate(x = aggregated_data, by = data.frame(aggregated_data$commodity), FUN = mean)

# Some ideas for how to look at the data.
ggplot(data.frame(X = aggregated_data$mode, Y = aggregated_data$distance, tons = log(aggregated_data$tons)),
             aes(x=X, y=Y, color=tons)) + geom_point(size=1)
ggplot(data.frame(commodity = by_commodity$commodity, unit_cost = by_commodity$value / by_commodity$tons),
       aes(x=commodity, y=unit_cost)) + geom_point()

# This is the main overview plot.
ggplot(data.frame(X = aggregated_data$mode, Y = aggregated_data$distance,
                  commodity = aggregated_data$commodity, tons = aggregated_data$tons),
       aes(x=X, y=Y, color=commodity, size=tons)) +
  scale_size(range = c(0.007, 1.5)) +
  geom_jitter()

# This is what says the mode has a significant relation to the distance.
anova(lm(aggregated_data$distance ~ aggregated_data$mode))