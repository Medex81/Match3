extends Node

var n_cols = 10
var fields_model = []
enum e_fields_types{EFT_RED, EFT_GREEN, EFT_BLUE, EFT_YELLOW, EFT_EMPTY, EFT_ROCK, EFT_SAND, EFT_M3, EFT_M4, EFT_M5, EFT_M6}
var a_cols = []
var a_rows = []

var pf_match_clb = null

func init():
	randomize()
	# вспомогательные массивы столбцов и строк для быстрой проверки совпадений
	a_cols.resize(n_cols)
	a_rows.resize(n_cols)
	for i in n_cols:
		a_cols[i] = []
		a_cols[i].resize(n_cols)
		a_rows[i] = []
		a_rows[i].resize(n_cols)
	for ind in n_cols * n_cols:
		# тип должен указывать на элемент следующий за последним, чтобы можно было брать значение по модулю в пределах полей. 
		var type = randi() % (e_fields_types.EFT_EMPTY)
		fields_model.append(type)
		a_cols[ind % n_cols][ind / n_cols] = ind
		a_rows[ind / n_cols][ind % n_cols] = ind
		
func find_all_potential_matches():
	if fields_model.empty() == false:
		if find_potential_matches(n_cols):
			return
		if find_potential_matches(a_rows):
			return
		
# ищем потенциальные совпадения.
func find_potential_matches(a_rapid_array):
	# проходим по стобцам и строкам и ищем клетки с одним типом встречающиеся 2 раза подряд или через клетку.	
	for i in a_rapid_array:
		var ret = find_potential_match_in_line(a_rapid_array[i])
		if ret != null:
			match ret.size():
				1: # проверить на столбик левее и правее(если есть)
					# проверить левый столбик
					if i > 0 && fields_model[a_rapid_array[i - 1][ret[0] + 1]] == fields_model[a_rapid_array[i][ret[0]]]:
						show_potential_hint([fields_model[a_rapid_array[i - 1][ret[0] + 1]], fields_model[a_rapid_array[i][ret[0]]]])
						return true
					# проверить правый столбик
					if i < n_cols - 1 && fields_model[a_rapid_array[i + 1][ret[0] + 1]] == fields_model[a_rapid_array[i][ret[0]]]:
						show_potential_hint([fields_model[a_rapid_array[i + 1][ret[0] + 1]], fields_model[a_rapid_array[i][ret[0]]]])
						return true
				2: # показать подсказку
					show_potential_hint([fields_model[a_rapid_array[i][ret[0]]], fields_model[a_rapid_array[i][ret[1]]]])
					return true
				3: # проверка потенциального матча сзади
					# проверить левый столбик
					if i > 0 && fields_model[a_rapid_array[i - 1][ret[0] - 1]] == fields_model[a_rapid_array[i][ret[0]]]:
						show_potential_hint([fields_model[a_rapid_array[i - 1][ret[0] - 1]], fields_model[a_rapid_array[i][ret[0]]]])
						return true
					# проверить правый столбик
					if i < n_cols - 1 && fields_model[a_rapid_array[i + 1][ret[0] - 1]] == fields_model[a_rapid_array[i][ret[0]]]:
						show_potential_hint([fields_model[a_rapid_array[i + 1][ret[0] - 1]], fields_model[a_rapid_array[i][ret[0]]]])
						return true
	return false
# анимация подсказки на двух клетках о потенциальном матче
func show_potential_hint(a_inds):
	pass
	
# массив индексов потенциально совпавших элементов в общем массиве.
func find_potential_match_in_line(line_array):
	# найти последовательность одинаковых значений из 2 элементов подряд или через один.
	for i in n_cols - 3:
		# ++-+
		if fields_model[line_array[i]] == fields_model[line_array[i + 1]] && fields_model[line_array[i]] == fields_model[line_array[i + 3]]:
			return [i + 2, i + 3]
		# +-++
		if fields_model[line_array[i]] != fields_model[line_array[i + 1]] && fields_model[line_array[i]] == fields_model[line_array[i + 2]] && fields_model[line_array[i]] == fields_model[line_array[i + 3]]:
			return [i, i + 1]
		#  ?
		# +-+
		#  ?
		if fields_model[line_array[i]] != fields_model[line_array[i + 1]] && fields_model[line_array[i]] == fields_model[line_array[i + 2]]:
			return [i]
		#   ?
		# ++-
		#   ?
		if fields_model[line_array[i]] == fields_model[line_array[i + 1]] && i + 2 < n_cols:
			return [i]
		# ?
		# -++
		# ?
		if fields_model[line_array[i]] == fields_model[line_array[i + 1]] && i > 0:
			return [i , 0, 0]
	return null

# ищем совпадения по всему игровому полю.
func find_all_matches():
	if fields_model.empty() == false:
		var a_matches = []
		find_matches(a_cols, a_matches)
		find_matches(a_rows, a_matches)
		var multi_matches = []
		if a_matches.empty() == false:
			recursive_additive_matching(a_matches, multi_matches)
		if multi_matches.empty() == false:
			match_awards(multi_matches)
		
# рекурсивно объединяем пересекающиеся массивы
func recursive_additive_matching(src_matches, res_matches):
	res_matches.clear()
	var b_add = false
	# собираем матчи для проверки пересечений
	for ind_curr in range(src_matches.size()):
		if src_matches[ind_curr].empty() == true:
			continue
		var multi_match = []
		multi_match += src_matches[ind_curr]
		for ind_check in range(ind_curr + 1, src_matches.size()):
			for val_curr in src_matches[ind_curr]:
				if src_matches[ind_check].has(val_curr):
					multi_match += src_matches[ind_check]
					src_matches[ind_check].clear()
					b_add = true
					break
		# выбрасываем последовательности из 2х совпадений
		if multi_match.size() > 2:
			res_matches.append(multi_match)
	# в результирующем массиве есть новые объединения
	if res_matches.empty() == false && b_add:
		src_matches = res_matches.duplicate()
		recursive_additive_matching(src_matches, res_matches)

# ищем совпадения
func find_matches(a_rapid_array, matches):
	for item in a_rapid_array:
		# получили массив с совпадениями(если они есть)
		var ret = find_match_in_line(item)
		for match_cells in ret:
			# массив индексов клеток с совпадением
			var arr = []
			# из быстрого массива копируем индексы совпадения
			for ind in range(match_cells[0], match_cells[0] + match_cells[1]):
				# преобразуем индексы быстрого массива в индексы большого массива(игрового поля/модели)
				arr.append(item[ind])
			if arr.empty() == false:
				arr.sort()
				matches.append(arr)
	
# выдаём награду за совпадение(очки, подсказки).
func match_awards(matched_inds):
	if pf_match_clb:
		pf_match_clb.call_func(matched_inds)
	# количество совпадений
	match matched_inds.size():
		3:
			pass
		4:
			pass
		5:
			pass
		6:
			pass

# массив индексов совпавших элементов в общем массиве.
func find_match_in_line(line_array):
	# найти непрерывную последовательность одинаковых значений из 3 и более элементов.
	#  массив с результатами
	var ret = []
	# текущий тип
	var walk_type = fields_model[line_array[0]]
	# количество совпадений текущего типа
	var cur_count = 1
	# проходим массив клеток по вертикали или горизонтали
	for i in range (1, n_cols):
		# несколько последовательно расположенных клеток с одинаковым типом
		if walk_type == fields_model[line_array[i]]:
			cur_count += 1
		# конец последовательности текущего типа
		if walk_type != fields_model[line_array[i]]:
			# берём последовательности от двух подряд потому, что они могут стоять перпендикулярно
			if cur_count > 1:
				# в возращаемом массиве индекс в строке быстрого массива и размер последовательности
				ret.append([i - cur_count, cur_count])
			walk_type = fields_model[line_array[i]]
			cur_count = 1
	# последовательность находится в конце
	if cur_count > 1:
		ret.append([n_cols - cur_count, cur_count])
		
	return ret

# генерируем новые элементы и двигаем сверху вниз по свободным клеткам.
func shift_from_top():
	# получаем список индексов в которых было совпадение, а значит теперь они пустые.
	# смещаем вниз тип из клетки расположенной выше.
	# если выше статический элемент - пробуем заполнить из бокового столбика, если нет - пропускаем. 
	# если клетка есть, смещаем последовательно до самого верха. в верхнюю клетку добавляем созданный элемент.
	pass
