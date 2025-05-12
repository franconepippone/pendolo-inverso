class_name Utils


static func write_csv_file(file_path: String, data: Array):
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not open or create the file at %s" % file_path)
		return

	for row in data:
		var line = []
		for value in row:
			# Escape double quotes
			var val = str(value).replace('"', '""')
			# Enclose each value in double quotes
			line.append('"%s"' % val)
		file.store_line(",".join(line))

	file.close()
	print("CSV file written to: ", file_path)
