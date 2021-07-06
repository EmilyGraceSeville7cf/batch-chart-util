BEGIN {
	value = ARGV[1]
	max = ARGV[2]
	width = ARGV[3]
	printf "%.0f\n", value/max*width
}